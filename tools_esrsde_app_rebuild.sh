#!/bin/bash

#this has worked, case 179197082 if you need to check anything

echo script will backup and rebuild esrsde_app container, we should hope.
echo create database backup
docker exec -i esrsde-app su -l postgres -c "pg_dumpall > /esrsve_config/opt/esrsve/pgsql/dbdump"
	if [[ $? -eq 0 ]];then
		#echo changing version to 5.16.00.00, really neccasery? only for 5.16 download failues, later SCG doiesn not have esrsclient.conf in this location.
		#sed -i "s/ContainerEdition=${KB_TARGET_VERSION}/ContainerEdition=5.16.00.00/g" /var/lib/docker/volumes/esrsconfig/_data/etc/esrsclient.conf
			# why are we cat'ing this?
			#cat /var/lib/docker/volumes/esrsconfig/_data/etc/esrsclient.conf
				#the important bit?
				docker stop esrsde-app
				docker rm esrsde-app
				systemctl start srs.docker.service
				echo $?
				for retryCount in {0..10}
					do
						echo "RetryAttempt: $retryCount"
							sleep 90s
							httpdrStatus=$(docker exec -i esrsde-app systemctl status esrshttpdR  | grep -i RUNNING | wc -l)
								if [[ $httpdrStatus -eq 1 ]]; then                                        
									break;
									fi
									# Checking if underlying JEOS has changed, Resetting the LB, Also calls ra-prerequisite.sh internally, Has Systemctl dependency.
									# hopfully this script calls the database recovery?
									docker exec -i esrsde-app /opt/esrsve/gateway/suseveupgrade.sh -configuresystem
								done
	fi
docker  exec -i esrsde-app systemctl start esrshttpdftp
docker exec -i esrsde-app systemctl start esrshttpdlistener