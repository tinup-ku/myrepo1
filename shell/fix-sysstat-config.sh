#!/bin/bash
#
# $Id: $

# Adjust paths depending on arch
if [ -d /usr/lib64 ]; then
  LIB=lib64
else
  LIB=lib
fi

# For the sysconfig file we look for cs-misc-config comment
# to prove the file came from us.
if [ `grep -c cs-misc-config /etc/sysconfig/sysstat` -eq 0 ]; then
  sed "s/LIB/${LIB}/g" /etc/cs-misc-config/sysconfig-sysstat > /etc/sysconfig/sysstat
fi

# For cron.d we overwrite the existing file regardless. RHEL6 uses different
# args than earlier so we have to have 2 files.
if [ `grep -c 'release 6' /etc/redhat-release` -eq 0 ]; then
  sed "s/LIB/${LIB}/g" /etc/cs-misc-config/cron.d-sysstat > /etc/cron.d/sysstat
else
  sed "s/LIB/${LIB}/g" /etc/cs-misc-config/cron.d-sysstat-6 > /etc/cron.d/sysstat
fi

# For sa1 and sa2 we want to use the stock files if they came from RHEL6.  The
# RHEL5 and older files are under 30 lines long.
if [ `wc -l /usr/${LIB}/sa/sa1 | awk '{print $1}'` -lt 30 ]; then
  cp /usr/${LIB}/sa/sa1 /usr/${LIB}/sa/sa1-pre-cs-misc-config
  cp /etc/cs-misc-config/sa1 /usr/${LIB}/sa/
fi
if [ `wc -l /usr/${LIB}/sa/sa2 | awk '{print $1}'` -lt 30 ]; then
  cp /usr/${LIB}/sa/sa2 /usr/${LIB}/sa/sa2-pre-cs-misc-config
  cp /etc/cs-misc-config/sa2 /usr/${LIB}/sa/
fi
