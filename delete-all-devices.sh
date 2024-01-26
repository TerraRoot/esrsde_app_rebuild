#!/bin/bash
# this file deletes all devices from a PM 5.x, it needs to run inside the container
printf "Starting reading devices from database\n"
printf "\n"
devices=$(curl --silent -X POST "http://localhost:5984/device/_find" -H "Authorization: Basic YWRtaW46I3RaOVcxaUgwVng4dTk=" -H "accept: application/json" -H "Content-Type: application/json" -d  "{\"selector\": { \"_id\" : {\"\$regex\" : \"device-\"}}, \"fields\": [  \"_id\",\"_rev\" ]}" | grep -E "^{\"_id")

printf "Registries found:\n"
printf "${devices[@]}"
printf "\n"
printf "________BEGIN DELETION________\n"

# Delete all devices
for d in ${devices[@]}; do
   id=$(echo $d | cut -d',' -f1 | cut -d':' -f2 | sed 's/"//g')
   printf "id: $id\n"
   rev=$(echo $d | cut -d',' -f2 | cut -d':' -f2 | sed 's/"//g' | sed 's/.$//' | sed 's/}//')
   printf "rev: $rev\n"
   printf "DELETE /device/$id?rev=$rev\n"
   curl -X DELETE "http://localhost:5984/device/$id?rev=$rev" -H "Authorization: Basic YWRtaW46I3RaOVcxaUgwVng4dTk="
done

printf "________END________\n":
