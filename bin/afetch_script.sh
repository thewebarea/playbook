#!/usr/bin/env bash

delimiter='/templates/scripts/'

bp=$(realpath $3 | sed -e "s#$delimiter.*##g")
ap=$(realpath $3 | sed -e "s#.*$delimiter##g")

if [[ "$bp$delimiter$ap" != $(realpath $3) ]]; then
    echo "fetched script should be in $delimiter subdirectory now=$(realpath $3)"
fi


cd $(dirname $(readlink $0))
cd ..

echo "fetching $ap from " $2 at $1 to "$bp$delimiter$ap"

varansible=$(ansible -i inventories/$1.py -m debug -a "var=hostvars['$2']" $2)

#echo $varansible

varjson=$(echo $varansible | tr '\n' ' ' | sed -e 's/\s\+//g' | sed -e 's/.*|SUCCESS=>//' )

#echo $varjson

host_port=$(echo $varjson | python3 -c "import sys, json; i=json.load(sys.stdin); l=lambda x: i[\"hostvars['$2']\"][x]; print(l('ansible_host'), l('ansible_port'))")


scp -P$(echo $host_port | cut -d ' ' -f2) root@$(echo $host_port | cut -d ' ' -f1)":/$ap" "$bp$delimiter$ap"

