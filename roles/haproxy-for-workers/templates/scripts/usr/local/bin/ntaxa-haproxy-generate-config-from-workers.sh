#!/bin/bash

source /usr/local/bin/o-lib.sh

f=150
t=200
ch="a-zA-Z0-9_-"
#a="\\(\\(*\\.\\)|\\([$ch][-$ch]\\).\\)*[$ch][-$ch]\\{1,50\\}.[$ch]\{1,30\}\$"
onel="\\(\\(\\([$ch]\\{1,30\\}\\)\\|\\(\\*\\)\\)\\.\\)"
a="^$onel*\\([$ch]\\{1,30\\}\\.\\)[$ch]\\{1,10\\}\$"
ddir='aliases'
ddirweb='aliasesweb'
rootdir='/usr/local/bin/haproxy'
newl="
"

rm -r "$rootdir/$ddir/"*
rm -r "$rootdir/$ddirweb/"*

ddir="$rootdir/$ddir"
ddirweb="$rootdir/$ddirweb"

fw ()
{
	vma=$1
        hna=$2
	ipa=$3
	alsa=$4
        echo "alsa=$alsa"
        usebackendfile="$ddir/$vma/$hna.use_backend.cfg"
        conditionlines=''
        conditions=''
	echo "+	Writing file $aliasfilename for $vma"
#	echo "    use_backend $vma if { hdr_end(host) -i $hna }"
#        echo "    use_backend $vma if { hdr_end(host) -i $hna }" > $usebackendfile
	    for alias in $alsa; do
	      echo "alias $alias"
	      if [[ "$alias" =~ [*] ]] ; then
                aliasconditin='hdr_reg(host) -i ^'$(echo $alias | sed -e 's/\./\\./gi' -e 's/\*/.*/gi')'$'
              else
		aliasconditin="hdr(host) -i $alias"
              fi
	      if [[ ${#conditions} -gt 150 ]]; then
                conditionlines="$conditionlines$newl$conditions"
                conditions=''
              fi
              conditions="$conditions or { $aliasconditin }"
            done
	    conditionlines="$conditionlines$newl$conditions"
	echo "$conditionlines" | grep "host" | sed -e "s/^ or /    use_backend $vma if /gi" > $usebackendfile
  return 0
}

html ()
{
  vma=$1
  hna=$2
  ipa=$3
  alsa=$4
  echo "ServerName $hna$alsa" > "$ddirweb/$vma/$hna"
  return 0
}

for ip in {0..99}; do
  echo $ip
done
exit
for vmpath in /images/private/*; do
  vm=`basename $vmpath`
  if [[ $vm -ge "$f" && $vm -le "$t" ]]; then
    vmhostshort=`cat /images/private/$vm/etc/hostname`
    vmhost=$vmhostshort".a.ntaxa.com"
    mkdir -p $ddir/$vm-$vmhostshort
    mkdir -p $ddirweb/$vm-$vmhostshort
    echo "backend $vm-$vmhostshort" > $ddir/$vm-$vmhostshort/backend.cfg
    fw $vm-$vmhostshort $vmhost 10.10.12.$vm "$vmhost *.$vmhost"
    html $vm-$vmhostshort $vmhost 10.10.12.$vm ""
    echo "+scaning hosts in $vmpath"
    for hostpath in /images/private/$vm/var/www/*; do
      host=`basename $hostpath`
      allals=''
      if [[ -d $hostpath ]]; then
	echo "  server $vm-$vmhostshort-$host 10.10.12.$vm:80" >> $ddir/$vm-$vmhostshort/backend.cfg
        echo "+	scaning aliases files for $hostpath"
        for aliasfilepath in /images/private/$vm/var/www/$host/config/aliases*.conf; do
          aliasfile=`basename $aliasfilepath`
          als=''
          while read fline; do
	    line=`echo $fline | grep -i '^Server\(Name\|Alias\) ' | sed 's/^Server\(Name\|Alias\) *//gi'`
	    if [[ "$line" == "" ]]; then
	      echo "-		skiping line $fline"
	    else
	      echo "+		reading line $fline"
	      for domain in $line; do
		check=`echo $domain | sed "s/$a//"`
		if [[ "$check"  == "" ]]; then
		    echo "+			ok $domain"
                    als=$als' '$domain
		else
		    echo "-			skiping wrong domain $domain"
		fi
	      done
	    fi
          done <$aliasfilepath
          if [[ "$als" == "" ]]; then
	    echo "-		no aliases in file $aliasfilepath"
  	  else
	    allals="$allals$newl$als"
	  fi
        done
        fw $vm-$vmhostshort $host 10.10.12.$vm "$allals"
        html $vm-$vmhostshort $host 10.10.12.$vm "$allals" $vmhostshort
      else
        echo "-	skiping $hostpath (not directory)"
      fi
    done
  else
    echo "-skiping $vmpath (not in $f-$t range)"
  fi
done

cat $rootdir/haproxy_begin.cfg > $rootdir/haproxy.cfg

for backend in $ddir/*
  do
    echo "$newl#use backends from file $backend" >> $rootdir/haproxy.cfg
    for use_backend in $backend/*use_backend.cfg
      do
        cat $use_backend >> $rootdir/haproxy.cfg
      done
  done

for backenddir in $ddir/*
  do
    echo "$newl" >> $rootdir/haproxy.cfg
#    cat "$backend/backend.cfg" >> $rootdir/haproxy.cfg
     [[ "$backenddir" =~ ^$ddir/(([0-9]*).*)$ ]]
#     backendip=$(echo $)
#     backendname=$(echo "$backenddir" | sed -e "s#$ddir/##gi")
     backendname="${BASH_REMATCH[1]}"
     ip="${BASH_REMATCH[2]}"
     echo "backend $backendname"  >> $rootdir/haproxy.cfg
    for use_backendfile in $backenddir/*use_backend.cfg
      do
        regexp='s#^.*/\([^/]*\)\.use_backend\.cfg$#\1#g'
        suffix=$(echo $use_backend | sed -e $regexp)
	servername="$backendname-"$(echo "$use_backendfile" | sed -e "s#$backenddir/##gi" -e "s#\.use_backend\.cfg##gi")
	echo "  server $servername 10.10.12.$ip:80"  >> $rootdir/haproxy.cfg
        cat $use_backendfile | sed -e "s/^\s*use_backend\s*\([^ ]*\)/    use-server $servername/g"  >> $rootdir/haproxy.cfg
      done
 done

cat $rootdir/haproxy_end.cfg >> $rootdir/haproxy.cfg

newmd5=$(find $rootdir/haproxy.cfg -xtype f -print0 | xargs -0 sha1sum | cut -b-40 | sort | sha1sum)
oldmd5=$(find /etc/haproxy/haproxy.cfg -xtype f -print0 | xargs -0 sha1sum | cut -b-40 | sort | sha1sum)

echo "new aliases md5: $newmd5"
echo "old aliases md5: $oldmd5"

if [[ "$newmd5" == "$oldmd5" ]]; then
  echo 'md5 are the same'
else
  echo 'md5 differ'
  cp $rootdir/haproxy.cfg /etc/haproxy/
  rsync -r --force --del $rootdir/aliasesweb/ /var/www/aliases/
  sleep 3
  /usr/sbin/service haproxy restart 2>&1
fi
