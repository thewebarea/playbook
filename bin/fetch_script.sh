#!/usr/bin/env bash



cd $(dirname $(readlink $0))
cd ..



echo "fetching $3 from " $2 at $1 to $4

varansible=$(ansible -i inventories/$1.py -m debug -a "var=hostvars['$2']" $2)

#echo $varansible

varjson=$(echo $varansible | tr '\n' ' ' | sed -e 's/\s\+//g' | sed -e 's/.*|SUCCESS=>//' )

#echo $varjson

host_port=$(echo $varjson | python3 -c "import sys, json; i=json.load(sys.stdin); l=lambda x: i[\"hostvars['$2']\"][x]; print(l('ansible_host'), l('ansible_port'))")

ssh root@$(echo $host_port | cut -d ' ' -f1) -p$(echo $host_port | cut -d ' ' -f2)

scp -P$(echo $host_port | cut -d ' ' -f2) root@$(echo $host_port | cut -d ' ' -f1):$3 $4
#echo $variables



echo "fetch scripts recursively from template back to {{role_path}}/templates/scripts/"

echo "TODO: $0 inventory host"