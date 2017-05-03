#!/bin/bash

vw='/var/www'

symlinks=''

for dir in $(ls $vw); do
  if [[ -d $vw/$dir && -L $vw/$dir && $dir =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$ ]]; then
    symlinks="$symlinks $dir"
  fi
done

for dir in $(ls $vw); do
  if [[ -d $vw/$dir && ! -L $vw/$dir && $dir =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$ ]]; then
    project=$dir
    
    for link in $symlinks; do
      linkbase=$(basename $(readlink $vw/$link))
      if [[ $dir == $linkbase ]]; then
        project="$project $link"
      fi
    done
    echo $project
  fi
done

