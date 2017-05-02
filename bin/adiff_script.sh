#!/usr/bin/env bash

delimiter='/templates/scripts/'

rp=$(realpath $3)


bp=$(echo $rp | sed -e "s#$delimiter.*##g")
ap=$(echo $rp | sed -e "s#.*$delimiter##g")

if [[ "$bp$delimiter$ap" != "$rp" ]]; then
    echo "comparing script should be in $delimiter subdirectory now=$(realpath $3)"
fi

cd $(dirname $(readlink $0))
cd ..

echo "fetching $ap from " $2 at $1 to "$bp$delimiter$ap"

varansible=$(ansible -i inventories/$1.py -m debug -a "var=hostvars['$2']" $2)


varjson=$(echo $varansible | tr '\n' ' ' | sed -e 's/\s\+//g' | sed -e 's/.*|SUCCESS=>//' )


host_port=$(echo $varjson | python3 -c "import sys, json; i=json.load(sys.stdin); l=lambda x: i[\"hostvars['$2']\"][x]; print(l('ansible_host'), l('ansible_port'))")

scp -P$(echo $host_port | cut -d ' ' -f2) root@$(echo $host_port | cut -d ' ' -f1)":/$ap" /tmp/$(basename $ap)

echo "colordiff -y $rp /tmp/$(basename $ap)"

colordiff --side-by-side --suppress-common-lines -W240 "$rp" "/tmp/$(basename $ap)"
