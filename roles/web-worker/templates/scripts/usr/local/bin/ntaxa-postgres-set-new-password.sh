#!/bin/bash

if [[ "$1" == "-h" ]] || [[ $# -ne 2 ]]; then
    echo "Usage: "`basename "$0"`" user pass - change password for postgres user
"
    exit
fi

echo "changing password for '$1' to '$2'"
su  postgres -c "echo \"ALTER USER $1 with password '$2' \" | psql"
sleep 1
echo "Testing: list databases;"
echo '\l' | PGPASSWORD="$2" psql --username=$1 --host=localhost

