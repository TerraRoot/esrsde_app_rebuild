#!/bin/bash
echo script will backup and rebuild esrsde_app container.
echo create database backup
docker exec -i esrsde-app su -l postgres -c "pg_dumpall > /esrsve_config/opt/esrsve/pgsql/dbdump"
	if [[ $? -eq 0 ]];then
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
			# Checking if underlying JEOS has changed, Resetting the LB, Also calls ra-prerequisite.sh internally, Has Systemctl dependency, ra-prerequisite.sh preform the database recovery
				docker exec -ti esrsde-app cat/opt/esrsve/gateway/suseveupgrade.sh -configuresystem
			done
	fi
docker  exec -i esrsde-app systemctl start esrshttpdftp
docker exec -i esrsde-app systemctl start esrshttpdlistener
