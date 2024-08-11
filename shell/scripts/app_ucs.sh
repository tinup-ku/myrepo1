#!/bin/bash

###############################################################
## Application Control for use with UNIX Currency Automation ##
###############################################################

##  Servers being patched are rebooted multiple times.
##  Disable any init.d or systemD boot scripts for your apps under stop case.
##  If applicable, re-enable init.d or systemD services under lastboot case.
##  Start app under start case. If applicable, check that re-enabling in lastboot worked.

##
case $1 in
'start')
	## BEGIN START COMMANDS ##
	if [ -f /usr/local/bin/re-enable_splunk ]; then 
  	  re-enable_splunk
	fi > /dev/null 2>&1
	echo "SUCCESS"

	## END START COMMANDS ##
        ;;
'stop')
	## BEGIN STOP COMMANDS ##
	echo "SUCCESS"

	## END STOP COMMANDS ##
        ;;
'lastboot')
	## BEGIN LASTBOOT COMMANDS ##
	echo "SUCCESS"

	## END LASTBOOT COMMANDS ##
	;;
*)
        echo "----------------------------------------"
        echo "Usage: $0 { start | stop | lastboot }"
        echo "----------------------------------------"
        ;;
esac
exit 0

