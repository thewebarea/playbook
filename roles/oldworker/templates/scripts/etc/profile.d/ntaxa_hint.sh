#!/bin/sh

hostname=`hostname`
domain=$(cat /etc/resolv.conf | grep 'domain ' | sed -e's/^[[:space:]]*domain[[:space:]]\+//')
echo ''
echo ''
myip=$(ifconfig | grep 'inet addr:10.10.' | sed "s/.*addr:10.10.[[:digit:]]\{1,3\}.//; s/  Bcast.*//")

echo "--   ssh	: ssh $hostname.$domain.ntaxa.com -p 22$myip"
echo "--   ftp	: ftp $hostname.$domain.ntaxa.com 21$myip"
echo "--   mysql	: http://$hostname.$domain.ntaxa.com/mysql/"
echo "--   postgres	: http://$hostname.$domain.ntaxa.com/postgres/"

echo "--   usefull tools:"

for t in /usr/local/bin/ntaxa-*; do
  echo "--   "`basename $t`":		"`$t -h`
done
