#!/bin/sh 
#
# Example init.d script with LSB support.
#
# Please read this init.d carefully and modify the sections to
# adjust it to the program you want to run.
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
# Required-Start:    $mythtv-backend
# Required-Stop:     
# Should-Start:      $named
# Should-Stop:       
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Update the MOTD with the MythTV status
# Description:       Update the MOTD with the MythTV status
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

DAEMON=/usr/sbin/mythtv-update-motd # Introduce the server's location here
NAME=mythtv-status         # Introduce the short server's name here
DESC="MythTV Status"         # Introduce a short description here
LOGDIR=/var/log/mythtv-status  # Log directory to use

test -x $DAEMON || exit 0
test -x $DAEMON_WRAPPER || exit 0

. /lib/lsb/init-functions

# Default options, these can be overriden by the information
# at /etc/default/$NAME
LOGFILE=$LOGDIR/$NAME.log  # Server logfile

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
  start|reload|refresh|restart)
    log_daemon_msg "Updating $DESC " "$NAME"
    [ ! -f /var/run/motd.orig ] && cp /var/run/motd /var/run/motd.orig

    cp /var/run/motd.orig /var/run/motd.new

    if mythtv-status -h $HOST >> /var/run/motd.new
    then
      mv /var/run/motd.new /var/run/motd
    fi
    #$DAEMON
    log_end_msg 0
    ;;
  stop)
    log_daemon_msg "Stoping $DESC " "$NAME"
    [ -f /var/run/motd.orig ] && cp /var/run/motd.orig /var/run/motd
    log_end_msg 0
    ;;
  *)
    N=/etc/init.d/$NAME
    echo "Usage: $N {start|stop|reload|refresh}" >&2
    exit 1
    ;;
esac

exit 0
