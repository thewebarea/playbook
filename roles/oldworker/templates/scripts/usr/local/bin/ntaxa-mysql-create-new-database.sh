#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 2 ]]; then
    echo "Usage: "`basename "$0"`" database user - create database and grant database.* provilegies to user@localhost
"
    exit
fi

echo "mysql root password: "
read pass

echo "create database $1; flush privileges;" | tee  /dev/tty | mysql -u root --password=$pass
echo "grant all privileges on $1.* to $2@localhost; flush privileges;" | tee  /dev/tty | mysql -u root --password=$pass 

