#!/bin/bash

cd $(dirname $(readlink $0))
cd ..
# ssh to ansible host
inventory=$(dirname $(readlink $0))
echo "ansible-playbook -i inventories/$1.py -s $3 --extra-vars=\"hosts=$2\""

ansible-playbook -vvv -i inventories/$1.py -s $3 --extra-vars="hosts=$2"

