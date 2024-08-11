#!/bin/ksh

#LOG=/var/tmp/show_topmem.out
LOG=show_topmem.out


# top command needs to check rhel version - flags are all different, but code goes below

VERSION=`cat /etc/redhat-release | awk '{print $8}' | tr -d '()'`

{
echo
echo "***********************************************************************"
echo
echo "TOP SORTED BY MEM  "
echo
echo
top  -n1 -b | head -5
echo

if [[ $VERSION = "Maipo" ]]
        then
        for x in {1..3} ; do top -o %MEM -n1 -b | head -12 | tail -6    ;sleep 3;echo ; done
elif [[ $VERSION = "Santiago" ]]
        then
        for x in {1..3} ; do top -a -n1 -b  | head -12 | tail -6    ;sleep 3; echo ; done
elif [[ $VERSION = "Tikanga" ]]
        then
        for x in {1..3} ; do top -m -n1 -b | head -12 | tail -6    ;sleep 3; echo ; done
elif [[ $VERSION == "" ]]
        then
        break
fi
} | tee -a $LOG
