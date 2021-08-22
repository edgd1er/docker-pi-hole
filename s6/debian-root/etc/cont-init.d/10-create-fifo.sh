#!/usr/bin/execlineb -P

#lighthttpd cannot use /dev/stdout https://redmine.lighttpd.net/issues/2731
if { s6-rmrf /var/log/lighttpd/access.log }
if { s6-mkfifo /var/log/lighttpd/access.log }
if { s6-rmrf /var/log/lighttpd/error.log }
if { s6-mkfifo /var/log/lighttpd/error.log }
