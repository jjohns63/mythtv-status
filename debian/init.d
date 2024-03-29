#!/bin/sh 
#
# Copyright (c) 2007 Javier Fernandez-Sanguino <jfs@debian.org>
#
# This is free software; you may redistribute it and/or modify
# it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2,
# or (at your option) any later version.
#
# This is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License with
# the Debian operating system, in /usr/share/common-licenses/GPL;  if
# not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA 02111-1307 USA
#
### BEGIN INIT INFO
# Provides:          mythtv-status
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $named mythtv-backend
# Should-Stop:       $named mythtv-backend
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Update the MOTD with the MythTV status
# Description:       Update the MOTD with the MythTV status
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

DAEMON=/usr/bin/mythtv-status # Introduce the server's location here
NAME=mythtv-status            # Introduce the short server's name here
DESC="MythTV Status"          # Introduce a short description here

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

# Include defaults if available
if [ -f /etc/default/$NAME ] ; then
	. /etc/default/$NAME
fi

# Use this if you want the user to explicitly set 'RUN' in 
# /etc/default/
if [ "x$RUN" != "xyes" ] ; then
    log_failure_msg "$NAME disabled, please adjust the configuration to your needs "
    log_failure_msg "and then set RUN to 'yes' in /etc/default/$NAME to enable it."
    exit
fi

set -e

case "$1" in
  start|reload|refresh|restart|force-reload)
    log_daemon_msg "Updating $DESC" "$NAME"

    # Just incase someone has removed their motd file.
    [ -f /var/run/motd ] || touch /var/run/motd
    [ -f /var/run/motd.orig ] || cp /var/run/motd /var/run/motd.orig

    cp /var/run/motd.orig /var/run/motd.new

    ret=0
    $DAEMON $ARGS -h $HOST >> /var/run/motd.new 2> /dev/null || ret=$?
    if [ $ret -eq 0 -o $ret -eq 1 ]; then
      mv /var/run/motd.new /var/run/motd
      log_end_msg 0
    else
      log_failure_msg 
    fi
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" "$NAME"
    [ -f /var/run/motd.orig ] && cp /var/run/motd.orig /var/run/motd
    rm /var/run/motd.orig
    log_end_msg 0
    ;;
  status)
    if [ ! -f /var/run/motd.orig ]; then 
      log_failure_msg "$NAME is not running"
      exit 1
    fi
    if [ ! -f /var/run/motd ]; then 
      log_failure_msg "$NAME is not running (no motd file!)"
      exit 1
    fi
    if [ $(date -d "15 minutes ago" +"%s") -gt $(stat -c "%Y" /var/run/motd) ]
    then
      log_failure_msg "$NAME is not running (motd file is stale)"
      exit 1
    fi

    # If all tests have passed, then we must be running.
    log_success_msg "$NAME is running"
    exit 0
    ;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|reload|refresh|status}" >&2
    exit 1
    ;;
esac

exit 0
