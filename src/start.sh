#!/bin/bash -e

if [ "${PH_VERBOSE:-0}" -gt 0 ]; then
  set -x
fi

trap stop TERM INT QUIT HUP ERR

start() {
  # The below functions are all contained in bash_functions.sh
  # shellcheck source=/dev/null
  . /usr/bin/bash_functions.sh

  echo "  [i] Starting docker specific checks & setup for docker pihole/pihole"

  # TODO:
  #if [ ! -f /.piholeFirstBoot ] ; then
  #    echo "   [i] Not first container startup so not running docker's setup, re-create container to run setup again"
  #else
  #    regular_setup_functions
  #fi

  # Initial checks
  # ===========================

  # If PIHOLE_UID is set, modify the pihole user's id to match
  if [ -n "${PIHOLE_UID}" ]; then
    currentId=$(id -u pihole)
    if [[ ${currentId} -ne ${PIHOLE_UID} ]]; then
      echo "  [i] Changing ID for user: pihole (${currentId} => ${PIHOLE_UID})"
      usermod -o -u ${PIHOLE_UID} pihole
    else
      echo "  [i] ID for user pihole is already ${PIHOLE_UID}, no need to change"
    fi
  fi

  # If PIHOLE_GID is set, modify the pihole group's id to match
  if [ -n "${PIHOLE_GID}" ]; then
    currentId=$(id -g pihole)
    if [[ ${currentId} -ne ${PIHOLE_GID} ]]; then
      echo "  [i] Changing ID for group: pihole (${currentId} => ${PIHOLE_GID})"
      groupmod -o -g ${PIHOLE_GID} pihole
    else
      echo "  [i] ID for group pihole is already ${PIHOLE_GID}, no need to change"
    fi
  fi

  ensure_basic_configuration
  setup_web_password

  # [ -f /.piholeFirstBoot ] && rm /.piholeFirstBoot

  # Install additional packages inside the container if requested
  if [ -n "${ADDITIONAL_PACKAGES}" ]; then
    echo "  [i] Fetching APK repository metadata."
    if ! apk update; then
      echo "  [i] Failed to fetch APK repository metadata."
    else
      echo "  [i] Installing additional packages: ${ADDITIONAL_PACKAGES}."
      # shellcheck disable=SC2086
      if ! apk add --no-cache ${ADDITIONAL_PACKAGES}; then
        echo "  [i] Failed to install additional packages."
      fi
    fi
    echo ""
  fi

  # Remove possible leftovers from previous pihole-FTL processes
  rm -f /dev/shm/FTL-* 2>/dev/null
  rm -f /run/pihole/FTL.sock

  # Start crond for scheduled scripts (logrotate, pihole flush, gravity update etc)
  # Randomize gravity update time
  sed -i "s/59 1 /$((1 + RANDOM % 58)) $((3 + RANDOM % 1))/" /crontab.txt
  # Randomize update checker time
  sed -i "s/59 17/$((1 + RANDOM % 58)) $((12 + RANDOM % 8))/" /crontab.txt
  # remove log file after MAXDAYS
  sed -i -E "s/MAXDAYS=.*/MAXDAYS=${MAXDAYS:-60}/" /crontab.txt
  #load crontab
  /usr/bin/crontab /crontab.txt
  #start daemon
  /usr/sbin/crond -d0 -l1 2>&1

  echo "  [i] crontab jobs"
  crontab -l
  echo ""

  #migrate Database if needed:
  gravityDBfile=$(getFTLConfigValue files.gravity)
  if [ ! -f "${gravityDBfile}" ]; then
    echo "  [i] ${gravityDBfile} does not exist (Likely due to a fresh volume). This is a required file for Pi-hole to operate."
    pihole -g
  else
    # TODO: Revisit this path if we move to a multistage build
    source /etc/.pihole/advanced/Scripts/database_migration/gravity-db.sh
    upgrade_gravityDB "${gravityDBfile}" "/etc/pihole"
  fi

  pihole updatechecker

  echo "  [i] Docker start setup complete"
  echo ""

  echo "  [i] pihole-FTL ($FTL_CMD) will be started as ${DNSMASQ_USER}"
  echo ""

  # Start pihole-FTL

  fix_capabilities
  sh /opt/pihole/pihole-FTL-prestart.sh
  capsh --user=$DNSMASQ_USER --keep=1 -- -c "/usr/bin/pihole-FTL $FTL_CMD >/dev/null" &

  #create backup dir if needed
  [[ ! -d /etc/pihole/config_backups ]] && mkdir -p /etc/pihole/config_backups || true

  #create self signed certificate
  FTLCONF_webserver_tls_cert=${FTLCONF_webserver_tls_cert:-"/etc/pihole/tls.pem"}
  export FTLCONF_webserver_tls_cert
  # https defined but no cert found, generating one.
  if [[ ! -f ${FTLCONF_webserver_tls_cert} ]] && [[ ${FTLCONF_webserver_port} =~ .*s.* ]]; then
    echo "  [i] ${FTLCONF_webserver_tls_cert} not found, generating a certfile with pihole-FTL"
    pihole-FTL --gen-x509 ${FTLCONF_webserver_tls_cert}
  else
    echo -e "  [i] certificate file found.\n"
  fi

  # Start pihole-FTL using the service-wrapper at /usr/local/bin/service
  service pihole-FTL start

  if [ "${TAIL_FTL_LOG:-1}" -eq "1" ]; then
    tail -f /var/log/pihole/FTL.log &
  else
    echo "  [i] FTL log output is disabled. Remove the Environment variable TAIL_FTL_LOG, or set it to 1 to enable FTL log output."
  fi

  # https://stackoverflow.com/a/49511035
  wait $!
  # Notes on above:
  # - DNSMASQ_USER default of pihole is in Dockerfile & can be overwritten by runtime container env
  # - /var/log/pihole/pihole*.log has FTL's output that no-daemon would normally print in FG too
  #   prevent duplicating it in docker logs by sending to dev null
}

stop() {
  # Ensure pihole-FTL shuts down cleanly on SIGTERM/SIGINT
  ftl_pid=$(pgrep pihole-FTL)

  # Stop pihole-FTL using the service-wrapper at /usr/local/bin/service
  service pihole-FTL stop

  # Wait for pihole-FTL to exit
  while test -d /proc/"${ftl_pid}"; do
    sleep 0.5
  done

  # If we are running pytest, keep the container alive for a little longer
  # to allow the tests to complete
  if [[ -n ${PYTEST} ]]; then
    sleep 10
  fi
  exit
}

start
