#!/bin/bash

if [[ "$1" == "-h" ]]; then
    echo "Usage: "`basename "$0"`"
Show all hosts and aliases
"
    exit
fi

vw='/var/www'

for dir in $(ls $vw); do
  cf="$vw/$dir/config/aliases.conf"
  >&2 echo "checking directory $dir"
  if [[ -d $vw/$dir && -f $cf && $dir =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$ ]]; then
    >&2 echo "checking config file $cf"
    if [[ -d "$vw/$dir/config/ssl" ]];
      if [[ -f "$vw/$dir/config/ssl/fullchain_and_privkey.pem" ]]; then
        ssl="$vw/$dir/config/ssl/fullchain_and_privkey.pem" 
      else
        ssl=auto 
      fi
    then
      ssl=no
    fi
    project="project: $dir ssl: $ssl domains: "$(cat $cf | grep '^\s*ServerName\s\+' | head -n1 | sed -e 's/^\s*ServerName\s\+\([^#]*\)\(#.*\)\?$/\1/g')
    aliases=$(cat $cf | grep '^\s*ServerAlias\s\+' | sed -e 's/^\s*ServerAlias\s\+\([^#]\+\)\(#.*\)\?$/\1/g')
    for alias in $aliases; do
      project="$project $alias"
    done
    echo $project
  fi
done

