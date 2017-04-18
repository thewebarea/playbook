#!/bin/bash

#cd $1

if [[ "$1" == "-h" ]] || [[ $# -gt 1 ]]; then
    echo "Usage: "`basename "$0"`" <user<:group>> - change all files ownership/permissions recursivelly (og-rwx, u+rwX) in currend directory
"
    exit
fi


if [[ "" == "$1" ]]; then
    ug=$(find . -maxdepth 0 -printf '%u:%g\n')
else
    ug="$1"
fi

curdir=`pwd | grep '^/var/www/'`
if [[ "" == "$curdir" ]]; then
    echo "error. are you sure this is web dir?"
    exit
fi

echo "
changing ownership and permissions in current directory $curdir to $ug"

chown -R $ug . # ownership
chmod a-rwx -R . # nowbody can nor read read,write,execute,access_directories
chmod u+rwX -R . # user can read/access_directories

#find . -type d | grep 'wp-content/uploads$' | xargs -I {} chmod -R a+rwX '{}' #anybody can write to uploads dir. this is obsolete if file ownership and apache server runer are same user

