#!/bin/bash
#This script automatically starts and stops the <encase> servlet


case $1 in

'start')

#<servlet path name> -d -p <servlet path>
/usr/local/bin/enlinuxpc64 -d -p /usr/local/bin/

;;

'stop')

pid=`/bin/ps -e | /bin/grep enlinuxpc | /bin/sed -e 's/^ *//' -e 's/ .*//'`

if [ "${pid}" != "" ]

then

/usr/bin/kill ${pid}

fi

;;

*)

echo "usage: /etc/init.d/enlinuxpc {start|stop}"
;;

esac
