#!/bin/bash

echo "Usage $0 <inventory> <host> <playbook> => ansible-playbook -i inventories/<inventory>.py -s <playbook> --extra-vars=\"hosts=<host>\""

cd $(dirname $(readlink $0))
cd ..
# ssh to ansible host
inventory=$(dirname $(readlink $0))
echo "ansible-playbook -vvv --ask-pass --ask-become-pass -i inventories/$1.py -s ./playbooks/key.yml --extra-vars=\"hosts=$2 user=$3\""

ansible-playbook -vvv --ask-pass --ask-become-pass -i inventories/$1.py -s ./playbooks/key.yml --extra-vars="hosts=$2 user=$3"
