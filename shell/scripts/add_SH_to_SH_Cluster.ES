#!/bin/ksh
##############################################################################
# This script adds new search head into search head cluster,
# https://splunk.mycorp.com
# Once new search head is initialized, ${SPLUNK_LOCAL}/server.conf's stanza,
# [shclustering], the followings will be added 
# - If search head is adhoc,
#   conf_replication_include.passwd = false
#   captain_is_adhoc_searchhead = true
#   adhoc_searchhead = true
# - If search head is regular or none
#   conf_replication_include.passwd = false
#   captain_is_adhoc_searchhead = true
##############################################################################
# Written by user1 | TOS Splunk Platform
node=`uname -n`
SPLUNK_LOCAL=/opt/splunk/etc/system/local
date_=$(date '+%a%H%M_%m%d%Y')
env_=`uname -n|grep -o '...$'`
{
eval `gpg --batch --xyz xyz -quiet --no-verbose -d /.splunk` >/dev/null 2>&1
} 2>/dev/null


# Service Account only.
case ${env_} in
   pdv | bdv ) uid=ser_act.dev
               ;;
   some_loc | loc2 ) uid=ser_act.prod
               ;;
esac

if [[ "`whoami`" != "${uid}" ]]
then
   echo "Running `basename $0` as ${uid} only. Abort."
   exit
fi

{
# Initialize the instance
grep '^\[shclustering' ${SPLUNK_LOCAL}/server.conf >/dev/null
if [[ "$?" != "0" ]]
then
   echo "Initializing $node instance"
   /opt/splunk/bin/splunk login -auth admin:${prod}
   /opt/splunk/bin/splunk init shcluster-config -mgmt_uri https://${node}.some_loc.mycorp.com:8089 -replication_port 9886 -replication_factor 3 -conf_deploy_fetch_url https://splunkdeployer-es.mycorp.com:8089 -secret prodcluster -shcluster_label prod-es_shcluster
fi

echo option=$1

case $1 in
     adhoc )
            cat<<END

Add the followings to ${SPLUNK_LOCAL}/server.conf [shclustering] stanza:

conf_replication_include.passwd = false
captain_is_adhoc_searchhead = true
adhoc_searchhead = true

END
            sed -i 's/\[shclustering\]/&\nconf_replication_include.passwd = false\ncaptain_is_adhoc_searchhead = true\nadhoc_searchhead = true/' ${SPLUNK_LOCAL}/server.conf
            ;;
      none )
            cat<<END

Add the followings to ${SPLUNK_LOCAL}/server.conf [shclustering] stanza:

conf_replication_include.passwd = false
captain_is_adhoc_searchhead = true

END
            sed -i 's/\[shclustering\]/&\nconf_replication_include.passwd = false\ncaptain_is_adhoc_searchhead = true/' ${SPLUNK_LOCAL}/server.conf
            ;;
        * )
            echo "option either adhoc OR none. Abort."
            exit
esac

echo "Now restarting splunk check kvstore via: /opt/splunk/bin/splunk show kvstore-status as ser_act.prod" 

echo "Next step, as ser_act.prod on an existing Search Head"
echo "/opt/splunk/bin/splunk add shcluster-member -new_member_uri https://${node}.some_loc.mycorp.com:8089"
} | tee /ser_act.prod/`basename $0`.${date_}.OUT
echo
echo "OUTPUT: /ser_act.prod/`basename $0`.${date_}.OUT"
