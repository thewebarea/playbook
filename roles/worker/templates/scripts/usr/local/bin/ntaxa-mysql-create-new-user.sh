#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 2 ]]; then
    echo "Usage: "`basename "$0"`" username password - create username with password (no privilegies)
"
    exit
fi

echo "mysql root password: "
read pass

echo "CREATE USER '$1'@'localhost' IDENTIFIED BY '$2'; FLUSH PRIVILEGES;" | mysql -u root --password=$pass
service mysql restart
