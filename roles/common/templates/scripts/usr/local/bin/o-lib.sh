#!/usr/bin/env bash

function 2lines { cat | xargs | sed -e 's/ /\n/g'; }

function 2spaces { cat | xargs; }

function _e { echo "$*"; logger -p local0.error "$*"; exit 1; }

function _w { echo "$*"; logger -p local0.warning "$*"; }

function _n { echo "$*"; logger -p local0.notice "$*"; }

function _d { echo "$*"; logger -p local0.debug "$*"; }

function is_dir {
  if [ ! -e "$1" ]; then
    _w "$1" dont exists
    echo "0"
  elif [ ! -d "$1" ]; then
    _w "$1" is not directory
    echo "0"
  else
    echo "1"
  fi
}

function rm_in_dir_if_exists {
  if [ ! ""$(echo "$*" | xargs) ]; then
     _w nothing passed to rm_in_dir_if_exists
     return 1
  fi
  for f in $*; do
      local ft=$(echo $f | sed -e 's#/$##')
      _n removing $ft
      if [ $(is_dir $f) ]; then
          rm -rf $f/*
      fi
  done
}


function lower { cat | tr '[:upper:]' '[:lower:]'; }

function join_by { cat | 2spaces | sed -e "s/ /$1/g"; }

function sync_dirs {

  local srcdir=$(echo $1 | sed -e 's#/$##')
  local dstdir=$(echo $2 | sed -e 's#/$##')

  _n "syncing $srcdir and $dstdir"

  if [ ! $(is_dir $srcdir) ]; then
    return 2
  fi
  if [ ! $(is_dir $dstdir) ]; then
    return 2
  fi
  local srcmd5=$(find $srcdir -xtype f -print0 | xargs -0 sha1sum | cut -b-40 | sort | sha1sum)
  local dstmd5=$(find $dstdir -xtype f -print0 | xargs -0 sha1sum | cut -b-40 | sort | sha1sum)

  if [[ "$srcmd5" == "$dstmd5" ]]; then
    _n "md5 are the same: $srcmd5"
    return 1
  else
    _n "md5 differ for md5($srcdir)=$srcmd5!=md5($dstdir)=$dstmd5, syncing"
    rsync -r --force --del $srcdir/ $dstdir/
    return 0
  fi
}