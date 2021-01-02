#!/usr/bin/with-contenv bash
set -e


if [[ ${#UID} -gt 1 ]] && [[ $(id -u pihole ) -ne ${UID} ]]; then
  #set docker pihole user with UID number
  echo "pihole has now ${UID} as UID"
  usermod -u ${UID} pihole
fi

if [[ ${#GID} -gt 1 ]] && [[ $(id -g pihole ) -ne ${GID} ]]; then
  # set container pihole group with GID number
  echo "pihole group has now ${GID} as group id"
  groupmod -g ${GID} pihole
  # add www-data to pihole group
fi

if [[ $(ip pihole | grep -c ${GID} ) -eq 0 ]]; then
  usermod -a -G pihole www-data
fi