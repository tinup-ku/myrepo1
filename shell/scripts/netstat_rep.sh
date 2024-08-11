#!/bin/bash
LOGFILE=/var/log/netstat.log
IFS=
interval=2
while true
do
echo $(netstat -an | grep tcp |grep -E "9887"  | awk '{ print strftime("%m-%d-%Y %H:%M:%S")" " "hostname="ENVIRON["HOSTNAME"] " " "protocol="$1 " " "RecvQ="$2 " " "SendQ="$3 " " "LocalAddress="$4 " " "Foreign_Address="$5 " " "state="$6 }') | tee -a $LOGFILE
sleep $interval
done
#note: "9887" indicate the port numbers you are interested in replication port
