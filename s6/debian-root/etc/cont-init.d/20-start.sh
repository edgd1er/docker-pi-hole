#!/usr/bin/with-contenv bash
set -e

bashCmd='bash -e'
if [ "${PH_VERBOSE:-0}" -gt 0 ]; then
  set -x
  bashCmd='bash -e -x'
fi

#When using volumes for /var/cache, create missing folder
[ ! -d /var/cache/lighttpd/uploads -o ! -d /var/cache/lighttpd/compress ] && mkdir -p /var/cache/lighttpd/{uploads,compress}
chown -R www-data:www-data /var/cache/

# used to start dnsmasq here for gravity to use...now that conflicts port 53

$bashCmd /start.sh
# Gotta go fast, no time for gravity
if [ -n "$PYTEST" ]; then
    sed -i 's/^gravity_spinup$/#gravity_spinup # DISABLED FOR PYTEST/g' "$(which gravity.sh)"
fi
if [ -z "$SKIPGRAVITYONBOOT" ]; then
    echo '@reboot root PATH="$PATH:/usr/sbin:/usr/local/bin/" pihole updateGravity >/var/log/pihole_updateGravity.log || cat /var/log/pihole_updateGravity.log' > /etc/cron.d/gravity-on-boot
else
    echo "  Skipping Gravity Database Update."
    [ ! -e /etc/cron.d/gravity-on-boot ] || rm /etc/cron.d/gravity-on-boot &>/dev/null
fi

# Kill dnsmasq because s6 won't like it if it's running when s6 services start
kill -9 $(pgrep pihole-FTL) || true # TODO: REVISIT THIS SO AS TO NOT kill -9

pihole -v
