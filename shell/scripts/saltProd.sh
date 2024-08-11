#!/bin/bash
################################################################################
# https://jira.mycorp.com/browse/TOS-14647 
# This script interacts with https://cmaportal.us.global.mycorp.com, apply 
# via salt state.apply the salt state file, deploy_shapps.sls 
# app_iaas_serviceassuranceservices_prod.AD00006311_splunk_core.salt.states.deploy_shapps:
# https://cmaportal.us.global.mycorp.com/ajax/get_file/YXBwX2lhYXNfc2VydmljZWFzc3VyYW5jZXNlcnZpY2VzX3Byb2QvQUQwMDAwNjMxMV9zcGx1bmtfY29yZS9zYWx0L3N0YXRlcy9kZXBsb3lfc2hhcHBzLnNscw== 
#
# update_apps
# update_global
# update_perms
# update_owner
# push_lookups
# push_bundle
#
# to perform the following tasks in order 
# 1. update_apps, push new/updated Splunk Search Head apps from
#    - https://bitbucket.mycorp.com/scm/ad00203364/tos_splunk_apps.git
#    to
#    - Splunk Search Head Deployer ser10860some_loc:/opt/splunk/etc/shcluster/apps
# 
# 2. update_global, push new/updated Splunk Search Head core from
#    - https://bitbucket.mycorp.com/scm/ad00203364/tos_splunk_core.git
#    to 
#    - ser10860some_loc:/opt/splunk/etc/shcluster/apps/00-CORE-SH
#
# 3. update_perms, recursively change /opt/splunk/etc/shcluster/apps 
#    files/directories permission to 766 (rwxrw-rw-)
#
# 4. update_owner, recursively change UID:GID /opt/splunk/etc/shcluster/apps 
#    ownership to ser_act.prod:unx_9998_access
#
# 5. push_lookups, run, as root, ser10860some_loc:/root/push_lookups to push 
#    new/updated ser10860some_loc:/opt/splunk/etc/shcluster/apps/*/lookups 
#    to
#    All Search Head members defined in Splunk Control Server/License Master,
#    ser10966some_loc:${CLUSTER}'s LUMP:All_splunk_multisite_SH
#
# 6. push_bundle, run as Splunk AD service account (ser_act.prod),
#    /usr/local/bin/push_bundle
#    to push new/updated apps to all Search Head cluster members
#
# The script runs 4 times daily via cron
# 0 12,15,18,21 * * * /usr/local/bin/saltProd.sh 2>&1
#
# OUTPUTS:
# . /srv/salt/LOG/$(date '+%a%H%M_%m%d%Y').log
# . Salt job id status for each salt ID, '"result":${status}'
#   where
#   ${status} is "true" or otherwise 
#   will be reported, via, email 
#   Subject: "`uname -n`: `basename $0` Salt job result"
#   to ${users_list}
#
# Steps to run manually (on demand)
# . From the command line
#    On ser10968some_loc, as root
#    saltProd.sh
# or
# . From CMA Portal
# 1. Login to https://cmaportal.us.global.mycorp.com/ as ad.first.last 
# 2. Under Drop down, All Applications, choose AD00006311
# 3. In Minion Id, search for ser10860some_loc, chceck mark on LHS penguin.
# 4. In Actions Dropdown, click on Apply State
# 5. Under "Choose Group Repository:", click on
#    App_iaas_SERVICEASSURANCESERVICES_prod_AD00006311
# 6. Under "Choose file:", click on
#    app_iaas_serviceassuranceservices_prod/AD00006311_splunk_core/salt/states/deploy_shapps.sls
#    Note, click on "View Source" to see state file .sls content
#    https://cmaportal.us.global.mycorp.com/ajax/get_file/YXBwX2lhYXNfc2VydmljZWFzc3VyYW5jZXNlcnZpY2VzX3Byb2QvQUQwMDAwNjMxMV9zcGx1bmtfY29yZS9zYWx0L3N0YXRlcy9kZXBsb3lfc2hhcHBzLnNscw==
# 7. To test run, put a check mark on "Run as test/dry-run, no actual changes are made."
#    then click on "Apply State"
# 8. Otherwise, click on "Apply State". Job id will be shown below as an example.
#    Job executed with Job Id: 20211021204146060914
# Reference:
# https://confluence.mycorp.com/display/SDIP/SALT+MANAGED+PLATFORM#SALTMANAGEDPLATFORM-CMAAPIDocumentation
################################################################################
# Written by user1 w/ inputs from Steve Warburton.
#
module_functions="
update_apps
update_global
update_perms
update_owner
push_lookups
push_bundle"
date_=$(date '+%a%H%M_%m%d%Y')
LOG=/srv/salt/LOG/`basename $0`.${date_}.log
users_list="user1@mycorp.com,user2@mycorp.com"

{

check_salt_jid_status ()
{
  bold_yellow="\e[1m\e[33m"
  reset_color="\e[0m"
  echo
  echo "Checking jid=$1 status..."
  echo

  # Checking various salt jid status
  # Output:
  # {"state": "running", "timer": 50, "minions": {"ser10860some_loc": "running"}}
  # {"state": "complete", "timer": 62, "minions": {"ser10860some_loc": "complete"}}
  # {"state": "complete", "timer": 3612, "minions": {"ser10860some_loc": "no data"}}
  while :
  do
    status=`{
              curl --location --request GET "https://cmaapi.us.global.mycorp.com/salt/job_status/$1" \
                   --header 'X-Auth-Key: 1bmhwKrNhsaCrevkGD96uyajGJ5OoJ6PXfdZDj7dK6Kswy9rN1Y5ix5s0Vdv9dG6ERms60fk3G8jBMpQVJfw2CNW2NnOX4IYbiNHF6HWxmaAqcJudymydb7Yb0fBBfGR' \
                   --header 'X-Auth-Token: gXZHf9SYXoQYNllXs62VgmNf97nMtD6JB6rQfkOcIFaw0wtsCwoSTb82iwOMaVwL1XCghrs06Dw69ZzMwXFp9NsskheucLgeITu0kX0qAwxKw6x23csdZUFkcUPoF5Cn'
    } 2>/dev/null`

    echo
    echo status=$status
    echo $status|grep "running" >/dev/null 2>&1
    if [[ "$?" = "0" ]]
    then
       echo -n "jid $1 is still running. Let's wait for 60 seconds "
       for sec in {1..60}
       do
        #echo -en "${bold_yellow}.${reset_color}"
        echo -n "."
        sleep 1
       done
       echo
    else
       echo
       # {"state": "complete", "timer": 11396, "minions": {"ser10860some_loc": "complete"}}
       echo "Checking jid $1 to make sure ser10860some_loc is in \"complete\" state"
       echo "$status"|awk 'BEGIN{RS="{"}{print}'|sed '/^$/d'|awk 'END{print}' \
       | grep '"ser10860some_loc": "complete"}}' 2>/dev/null
       jid_status=$?

       if [[ "${jid_status}" != "0" ]]
       then
         echo
         echo "$status"
         echo "Waiting for jid $1 to complete for another 5 minutes."
         sleep 5m
       else 
         echo "jid $1 Completed"
         echo "$status"
         break
       fi
    fi
  done
}

run_test_job ()
{
  # Start test run to get salt jid
  # Example output: {"return": [{"jid": "20211020172204541253", "minions": []}]}
  jid_test=`{
         curl --location --request POST 'https://cmaapi.us.global.mycorp.com/salt/apply_state' \
              --header 'X-Auth-Key: 1bmhwKrNhsaCrevkGD96uyajGJ5OoJ6PXfdZDj7dK6Kswy9rN1Y5ix5s0Vdv9dG6ERms60fk3G8jBMpQVJfw2CNW2NnOX4IYbiNHF6HWxmaAqcJudymydb7Yb0fBBfGR' \
              --header 'X-Auth-Token: gXZHf9SYXoQYNllXs62VgmNf97nMtD6JB6rQfkOcIFaw0wtsCwoSTb82iwOMaVwL1XCghrs06Dw69ZzMwXFp9NsskheucLgeITu0kX0qAwxKw6x23csdZUFkcUPoF5Cn' \
              --header 'Content-Type: application/json' \
              --data '[{
                         "target": "ser10860some_loc",
                         "tgt_type": "list",
                         "file": "app_iaas_serviceassuranceservices_prod.AD00006311_splunk_core.salt.states.deploy_shapps",
                         "test": "true"
                       }]'
  } 2>/dev/null| awk '{print $3}'| sed -e 's/"//g' -e 's/,//g'`
}

run_actual_job ()
{
  echo
  echo "Pushing new/updated apps from Bitbucket to Search Head Cluster Deployer, ser10860some_loc."
  # Insert run salt run job below
  jid=`{
         curl --location --request POST 'https://cmaapi.us.global.mycorp.com/salt/apply_state' \
              --header 'X-Auth-Key: 1bmhwKrNhsaCrevkGD96uyajGJ5OoJ6PXfdZDj7dK6Kswy9rN1Y5ix5s0Vdv9dG6ERms60fk3G8jBMpQVJfw2CNW2NnOX4IYbiNHF6HWxmaAqcJudymydb7Yb0fBBfGR' \
              --header 'X-Auth-Token: gXZHf9SYXoQYNllXs62VgmNf97nMtD6JB6rQfkOcIFaw0wtsCwoSTb82iwOMaVwL1XCghrs06Dw69ZzMwXFp9NsskheucLgeITu0kX0qAwxKw6x23csdZUFkcUPoF5Cn' \
              --header 'Content-Type: application/json' \
              --data '[{
                         "target": "ser10860some_loc",
                         "tgt_type": "list",
                         "file": "app_iaas_serviceassuranceservices_prod.AD00006311_splunk_core.salt.states.deploy_shapps"
                       }]'
  } 2>/dev/null| awk '{print $3}'| sed -e 's/"//g' -e 's/,//g'`
  # 2>/dev/null| awk '{print $3}'| sed -e 's/"//g;'s/,//g'`
}


##########
# M A I N
##########
ping -c 1 ser10860some_loc  >/dev/null 2>&1
[[ "$?" != "0" ]] && {
  echo "Search Head Cluster Deployer ser10860some_loc is down"
  exit
}

date
run_test_job
check_salt_jid_status ${jid_test}
date

run_actual_job
check_salt_jid_status ${jid}
date

# Output actual run to log and make it easier to read instead of 1-liner.
echo "Sending actual job output, $jid, to /srv/salt/LOG/`basename $0`.${date_}.log"
{
  curl --location --request GET "https://cmaapi.us.global.mycorp.com/salt/jobs/${jid}" \
       --header 'X-Auth-Key: 1bmhwKrNhsaCrevkGD96uyajGJ5OoJ6PXfdZDj7dK6Kswy9rN1Y5ix5s0Vdv9dG6ERms60fk3G8jBMpQVJfw2CNW2NnOX4IYbiNHF6HWxmaAqcJudymydb7Yb0fBBfGR' \
       --header 'X-Auth-Token: gXZHf9SYXoQYNllXs62VgmNf97nMtD6JB6rQfkOcIFaw0wtsCwoSTb82iwOMaVwL1XCghrs06Dw69ZzMwXFp9NsskheucLgeITu0kX0qAwxKw6x23csdZUFkcUPoF5Cn'
} | sed 's/\\\//\//g' | awk 'BEGIN{RS="|"}{print}'

echo
date
} | tee ${LOG}
echo
echo "Output: ${LOG}"

# Checking result from $LOG
{
for salt_func in ${module_functions}
do
  # Parse out "result":true
  echo
  echo "Verifying Salt module.function result, ${salt_func}."
  if [[ "${salt_func}" = "update_apps" ]]
  then
     # Verify if ${salt_func} is in the $LOG
     grep "^\-${salt_func}" ${LOG} >/dev/null
     if [[ "$?" = "0" ]]
     then
        result_=`{
                   sed -n '/^\-update_apps/,/^\-update_global/p' ${LOG} \
                   |grep -oP '"result":true'
                 }`
        sed -n '/^\-update_apps/,/^\-update_global/p' ${LOG} \
                |grep -oP '"result":true' >/dev/null
        if [[ "$?" != "0" ]]
        then
            result_=`{
                      sed -n '/^\-update_apps/,/^\-update_global/p' ${LOG} | \
                      grep '"result":' | \
                      awk -v FS='result":|,)' '{print $2}'|awk -F',' '{print $1}'
                      }`
            echo "result_=$result_"
        else
            echo "result_=$result_"
        fi
     else
        echo "${salt_func} entry is NOT showing in ${LOG}"
     fi
  else
     grep "^\-${salt_func}" ${LOG} >/dev/null
     if [[ "$?" = "0" ]]
     then
        result_=`grep -A3 "^\-${salt_func}" ${LOG}|grep -oP '"result":true'`
        grep -A3 "^\-${salt_func}" ${LOG}|grep -oP '"result":true' >/dev/null
        if [[ "$?" != "0" ]]
        then
           result_=`grep -A3 "^\-${salt_func}" ${LOG}|grep result|awk -F'result":' '{print $NF}'|awk -F, '{print $1}'` 
           echo "result_=$result_"
        else
            echo "result_=$result_"
        fi 
     else
        echo "${salt_func} entry is NOT showing in ${LOG}"
     fi
  fi
done
} | mailx -s "`uname -n`: `basename $0` Salt job result" ${users_list}
