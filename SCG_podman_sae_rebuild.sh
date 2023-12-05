#!/bin/bash
SAE_DATA_VOLUME="/opt/dell/secureconnectgateway/data"
SAE_LOG_VOLUME="/opt/dell/secureconnectgateway/logs"
SAE_CONFIG_VOLUME="/opt/dell/secureconnectgateway/config"
SCG_BRIDGE="sae-srs-bridge"
SAE_CONTAINER_NAME=saede-app
HostName=$(cat /etc/hostname)
SAE_REPO_NAME=sae_de
security_opt="--security-opt label=disable"
security_opt_sae="--security-opt seccomp=${profile_file}"
profile_file="${volume_path}/../dockerprofile.json"
pid_limit="--pids-limit=-1"
sae_memory_cont="6.98492g"
Deployment_Type="podman"
SAE_REPO_TAG=$(podman images | grep sae_de | awk '{print $2}')
HOSTIP=$(podman exec -i esrsde-app cat /opt/esrsve/version/esrshost.conf | grep 'IpAddress' | cut -d'=' -f2)
ENVIRONMENT=$(podman exec -i esrsde-app cat /opt/esrsve/version/esrshost.conf | grep 'Environment' | cut -d'=' -f2)
MacAddress=$(podman exec -i esrsde-app cat /opt/esrsve/version/esrshost.conf | grep 'MacAddress' | cut -d'=' -f2)
Version=$(podman exec -i esrsde-app cat /opt/esrsve/version/esrshost.conf | grep 'Version' | grep -v 'OSPatch' | cut -d'=' -f2)
volume_path=$(podman volume inspect saede_config -f '{{ .Mountpoint }}')
volume_path=${volume_path%/*}

eval $(cat /etc/os-release | grep -i PRETTY_NAME)
if [ -n "`echo ${PRETTY_NAME} | grep -i 'Alpine Linux'`" ]; then
    TimeZone=$(ls -ltr /etc/localtime|awk '{print $NF}'|cut -d "/" -f4)
else
    TimeZone=$(ls -ltr /etc/localtime|awk '{print $NF}'|cut -d "/" -f5,6)
fi

# blow away old container

podman stop saede_app
podman rm saede_app

# don't know of a way right now to restore database for sae, probably uses the data volume	
# this bit is extracted from the podman install bin

podman run $security_opt $security_opt_sae --memory=$sae_memory_cont --memory-swap="-1" --restart=always -v saede_data:$SAE_DATA_VOLUME \
-v saede_logs:$SAE_LOG_VOLUME -v saede_config:$SAE_CONFIG_VOLUME \
--add-host linux.site:$HOSTIP --add-host podmanhost:$HOSTIP \
-v srssae:/shared -v /etc/hostname:/etc/hostname -v /etc/hosts:/etc/hosts:ro \
-e ESRS_ADMIN='admin' -e IP_ADDRESS=$HOSTIP -e TIME_ZONE=$TimeZone -e HYPERVISOR_TYPE="Container Platform - $Deployment_Type" -e VERSION=$Version
-e OS='SUSE Linux Enterprise Server 15 SP5' -e ENVIRONMENT=$ENVIRONMENT -e HOSTNAME=$HostName -e MAC_ADDRESS=$MacAddress -e DEPLOYMENT_TYPE=$Deployment_Type \
--device=/dev/mem:/dev/mem --network $SCG_BRIDGE   \
-d -p 5700:5700 -p 5701:5701 -p 5702:5702 -p 5703:5703 -p 5704:5704 -p 5705:5705 -p 162:1162/udp -p 162:1162/tcp --cap-add=SYS_PTRACE --cap-add=SYS_RAWIO --cap-add=CAP_AUDIT_WRITE --cap-add=CAP_NET_BIND_SERVICE $pid_limit --name $SAE_CONTAINER_NAME $SAE_REPO_NAME:$SAE_REPO_TAG

#todo
#umm make this a script instead of a pile of notes and guesses.
#probably test on a lab. and not a customers setup
