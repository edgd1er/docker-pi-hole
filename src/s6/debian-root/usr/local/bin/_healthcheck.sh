#!/bin/bash

if [ "${PH_VERBOSE:-0}" -gt 0 ] ; then
    set -x ;
fi

checkRestartService(){
  if [[ "up" != $(service $1 status | grep -ioP "up" ) ]]; then
    echo restarting $s
    service $1 start
  fi
}

for s in pihole-FTL lighttpd
do
  checkRestartService ${s}
done