#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 2 ]]; then
    echo "Usage: "`basename "$0"`" user pass - change password for mysql user
"
    exit
fi

echo "stoping mysql"
service mysql stop
sleep 1
echo "starting mysql without greants"
mysqld_safe --skip-grant-tables &
sleep 1
while [ ! -S /var/run/mysqld/mysqld.sock ]; do
    sleep 1
    echo "no socket /var/run/mysqld/mysqld.sock waiting..."
done

echo "changing password for '$1' to '$2'"
echo "update user set password=PASSWORD('$2') where User='$1'; flush privileges;" | mysql mysql
sleep 1
echo "stoping mysql in safe mode"
service mysql stop
sleep 1
echo "starting mysql"
service mysql start
sleep 1
echo "Testing: SHOW DATABASES;"
echo "SHOW DATABASES;" | mysql -u $1 --password=$2
