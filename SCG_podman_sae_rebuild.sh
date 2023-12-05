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

#earlier code extract
#[Yesterday 21:28] Wang, Daniel
#podman run --security-opt label=disable --restart=always --ulimit core=-1:-1 --ulimit memlock=16384000:16384000 -v saede_data:/opt/dell/secureconnectgateway/data \
# -v saede_logs:/opt/dell/secureconnectgateway/logs -v saede_config:/opt/dell/secureconnectgateway/config --add-host linux.site:<HOST_IP> --add-host podmanhost:<HOST_IP> \
# -v /var/run/podman/podman.sock:/var/run/podman.sock:ro -v srssae:/shared -v /etc/hostname:/etc/hostname -v /etc/hosts:/etc/hosts:ro -v /usr/bin/podman:/podmanCli/podman -e ESRS_ADMIN=admin\
# -e IP_ADDRESS=<HOST_IP> -e TIME_ZONE=<TIMEZONE> -e 'HYPERVISOR_TYPE=Container Platform - podman' -e 'OS=SUSE Linux Enterprise Server 12 SP5' -e ENVIRONMENT=PROD -e HOSTNAME=<HOSTNAME> -e MAC_ADDRESS=<HOST_MAC>\
# -e DEPLOYMENT_TYPE=podman --device=/dev/mem:/dev/mem --network sae-srs-bridge -d -p 5700:5700 -p 5701:5701 -p 5702:5702 -p 5703:5703 -p 5704:5704 -p 162:162/udp -p 162:162/tcp -p 161:161/udp -p 161:161/tcp \
# --cap-add=SYS_PTRACE --cap-add=SYS_RAWIO --cap-add=CAP_AUDIT_WRITE --cap-add=CAP_NET_BIND_SERVICE --name saede-app sae_de:<TAG>
 
 
 
#stuff i ripped out that isn't needed for sae rebuild 

#SRS_COMMON_SP_HOST="common-sp.esrs.emc.com"
#PRODUCT_NAME="SCG"
#IPV4_SUBNET="172.18.0.0"
#IPV6_SUBNET="fd00:d311:e3c:5c6::0"
#platform_Config_File="/etc/podman/daemon.json"
#bkp_platform_Config_File="/etc/podman/daemon_bkp.json"
#SAE_REPO_NAME=sae_de
#container_platform_sock="podman.sock"
#    group_id=""
#    network_opt=""
#    podman_STORAGE_PATH=$(podman info | grep graphRoot: | awk -F: '{print $2}')
#    platform_Config_File="/etc/containers/registries.conf"
#    container_Config_File="/etc/containers/registries.conf"
#    bkp_platform_Config_File="/etc/containers/registries.bkp.conf"
#    CLIENT_CLI=""
#   HOST_CONFIG_FILE="-v /etc/containers/registries.conf:/etc/containers/registries.conf"
#   platform_Config_Direcotry="/etc/containers"
#   chmod 777 $host_platform_sock
#volume_path=${volume_path%/*}
#hostMount=$(echo $volume_path | awk -F'/saede_config' '{print $1}')
