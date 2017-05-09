#!/bin/bash

source /usr/local/bin/o-lib.sh

f=150
t=200
ch="a-zA-Z0-9_-"
onel="\\(\\(\\([$ch]\\{1,30\\}\\)\\|\\(\\*\\)\\)\\.\\)"
a="^$onel*\\([$ch]\\{1,30\\}\\.\\)[$ch]\\{1,10\\}\$"
newl="
"
__deb ()
{ 
  echo "$*" 1>&2
} 
  
ippref='10.10.13.'
hostpref='n.ntaxa.com'
external_ip=88.99.238.13 
ippref='10.10.13.'
rootdir="/usr/local/bin/haproxy/$external_ip"
newl="
"   
  
ddir="$rootdir"
#ddirweb="$rootdir/aliasesweb"
allcertsdir="$rootdir/certs"

rm -r "$ddir/"*
#rm -r "$ddirweb/"*
#rm -r "$allcertsdir/"*

backend_name () {
  echo $hostpref-$1
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

ip_for_domain () {
  host -ta $1 | grep 'has address' | head -n1 | sed -e 's/.* has address //g'
}

if_fqdn_and_our_ip () {
  __deb '->'" if_fqdn_and_our_ip $*"
  local ret=''
  local ifip=$1
  local d=''
  shift
  for d in $*; do
    local d_ip=$(ip_for_domain $d)
    if is_fqdn $d; then 
      if [[ "$d_ip" == "$ifip" ]]; then
        ret="$ret $d"
      else
        __deb "domain $d has wrong ip ($d_ip != $ifip) ignored"
      fi
    else
        __deb "domain $d is not fqdn. ignored"
    fi
  done
  __deb '<-'" if_fqdn_and_our_ip $ret"
  echo $ret
}

generate_certificate () {
  __deb '->'" generate_certificate $*"
  local ssltype=$1
  local certdir=$2
  local ifip=$3
  local proj_name=$4
  local domains="${@:5}"
  local d=''
  if [[ "$ssltype" == 'no' ]]; then
    echo ''
  fi
  if [[ "$ssltype" == 'auto' ]]; then
    ssl_domains=$(if_fqdn_and_our_ip $ifip $domains)
    echo "ssl_domains $ssl_domains"
    if [[ $ssl_domains != '' ]]; then
      chainkey=$(certonly.sh ntaxa@ntaxa.com $ssl_domains)
      fullchain=$(echo "$chainkey" | grep 'Certificate Path: ' | sed -e 's/^.*:\s\+//g')
      privkey=$(echo "$chainkey" | grep 'Private Key Path: ' | sed -e 's/^.*:\s\+//g')
      if [[ -f $fullchain && -f $privkey ]]; then
        cat $fullchain $privkey > "$certdir/$project_name.pem"
      fi
    fi
  fi
  if [[ "$ssltype" == 'yes' ]]; then
    fullchain_privkey="$(ssh -oBatchMode=yes $ip /usr/local/bin/ntaxa-apache-list-hosts.sh $proj_name)"
    cat $fullchain_privkey > "$certdir/$project_name.pem"
  fi
  __deb '<-'" generate_certificate"
}

generate_redirections () {
  local ssltype=$1
  local external_ip=$2
  local p_n=$3
  local domains="${@:4}"
  local d
  local tohttp="$ddir/$ip/to_http_redirection.cfg"
  local tohttps="$ddir/$ip/to_https_redirection.cfg"
  local conditionlines=''
  local conditions=''
  local aliasconditin=''
  for d in $domains; do
    if [[ "$d" =~ [*] ]] ; then
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
  conditionlines=$(strip_new_lines "$conditionlines$newl$conditions")
  if [[ "$conditionlines" != "" && $conditions != "" ]]; then
    if [[ "$ssltype" == 'auto' || "$ssltype" == 'yes' ]]; then
      echo "
# project $p_n" >> $tohttps
      echo "$conditionlines" | sed -e "s/^ or /    redirect scheme https code 301 if !{ssl_fc} /gi" >> $tohttps
    else
      echo "
# project $p_n" >> $tohttp
      echo "$conditionlines" | sed -e "s/^ or /    redirect scheme http code 301 if {ssl_fc} /gi" >> $tohttp
    fi
  fi
} 

generate_use_backend ()
{
  ip=$1
  p_n=$2
  alsa=$3
  usebackendfile="$ddir/$ip/use_backend.cfg"
  conditionlines=''
  conditions=''
  for alias in $alsa; do
    if [[ "$alias" =~ [*] ]] ; then
      aliasconditin='hdr_reg(host) -i ^'$(echo $alias | sed -e 's/\./\\./gi' -e 's/\*/.*/gi')'$'
    else
      aliasconditin="hdr(host) -i $alias"
    fi
	if [[ ${#conditions} -gt 50 ]]; then
      conditionlines="$conditionlines$newl$conditions"
      conditions=''
    fi
      conditions="$conditions or { $aliasconditin }"
  done
  conditionlines=$(strip_new_lines "$conditionlines$newl$conditions")
  if [[ "$conditionlines" != "" ]]; then
    echo "
# project $p_n" | tee -a $usebackendfile
    echo "$conditionlines" | sed -e "s/^ or /    use_backend $(backend_name $ip) if /gi" |  tee -a $usebackendfile
  fi
}


append_from_internal_ip () {
   local ip=$1
   local filename=$2
   if [[ -f $ddir/$ip/$filename  ]]; then
     echo "
#from file $ddir/$ip/$filename" >> $ddir/$filename
    cat $ddir/$ip/$filename >> $ddir/$filename
   fi
}

for ipnum in {3..5}; do
  ip=$ippref$ipnum
  __deb checking ip $ip
  host_is_up $ip
  if [[ $? == '1' ]]; then
    mkdir -p $ddir/$ip
    certdir=$ddir/$ip/certs
    mkdir -p $certdir
    mkdir -p $ddirweb/$ip
    projects="$(ssh -oBatchMode=yes $ip /usr/local/bin/ntaxa-apache-list-hosts.sh)"
    generate_use_backend $ip host "$ip.$hostpref"
    if [[ "$projects" != "" ]]; then
      echo "$projects" | while read -r delvar1 project_name delvar2 ssltype delvar3 domains; do
        generate_use_backend $ip $project_name "$domains"
        generate_certificate $ssltype $ddir/$ip/certs $external_ip $project_name "$domains"
        generate_redirections $ssltype $external_ip $project_name "$domains"
      done
    else
      __deb there is no ssh connection to host or no projects there
    fi
    echo "backend $(backend_name $ip)" > $ddir/$ip/backend.cfg
    echo "  server $hostpref-$ip $ip:80" >> $ddir/$ip/backend.cfg
  else
    __deb host is down
  fi
done

for ip in $(ls $ddir/); do
  __deb ip is $ip
  append_from_internal_ip $ip backend.cfg
  append_from_internal_ip $ip use_backend.cfg
  append_from_internal_ip $ip to_http_redirection.cfg
  append_from_internal_ip $ip to_https_redirection.cfg
done

cat ./haproxy/haproxy.cfg.template | sed "/----backends----/ {
  r $ddir/backends.cfg
  d
}" | sed "/----use_backends----/ {
  r $ddir/use_backends.cfg
  d
}" | sed "/----to_http_redirections----/ {
  r $ddir/$ip/to_http_redirections.cfg
  d
}" | sed "/----to_https_redirections----/ {
  r $ddir/$ip/to_https_redirections.cfg
  d
}" > /etc/haproxy/haproxy.cfg

service haproxy restart

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
