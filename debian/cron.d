#
# Regular cron jobs for the mythtv-status package
#
*/10 *	* * *	root	[ -x /etc/init.d/mythtv-status ] && /etc/init.d/mythtv-status reload > /dev/null
