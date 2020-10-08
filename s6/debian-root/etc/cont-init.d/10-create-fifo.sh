#!/usr/bin/execlineb -P

#lighthttpd cannot use /dev/stdout https://redmine.lighttpd.net/issues/2731
if { s6-rmrf /var/run/s6/lighttpd-access-log-fifo }
if { s6-mkfifo /var/run/s6/lighttpd-access-log-fifo }
if { s6-rmrf /var/run/s6/lighttpd-error-log-fifo }
if { s6-mkfifo /var/run/s6/lighttpd-error-log-fifo }
