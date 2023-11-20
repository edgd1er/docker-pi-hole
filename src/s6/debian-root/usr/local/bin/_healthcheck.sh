#!/usr/bin/env bash

if [ "${PH_VERBOSE:-0}" -gt 0 ] ; then
    set -x ;
fi

checkRestartService(){
  if [[ "up" != $(/command/s6-svstat /run/service/$1 | grep -ioP "up" ) ]]; then
    echo $(date "+%Y/%m/%d %H:%M:%S") restarting $s
    /command/s6-svc -wu -u -T${S6_SVC_TIMEOUT:-20000} /run/service/$1
  fi
}

for s in pihole-FTL lighttpd
do
  checkRestartService ${s}
done