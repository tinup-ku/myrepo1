#!/bin/bash
###############################################################################
#
#  This script will unregister this machine from mycorp's Satellite system
#
#  Robert Leonhard, April 2019
#
###############################################################################
PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ ! $1 = "-f" ]; then
	echo -n "This will unregister this host from Satellite.  Press any key to continue..."
	read junk
fi

systemctl stop goferd > /dev/null 2>&1
service goferd stop > /dev/null 2>&1
rm -fr /var/cache/yum/*
yum clean all
subscription-manager remove --all
subscription-manager unregister
subscription-manager clean
rpm -qa | grep katello | xargs rpm -e 
rpm -e facter

