#!/bin/bash
################################################################################
# This script backs out current installed splunk version to its previous.
# Output: /var/tmp/splunk${current_version_no}_backout.out
################################################################################
# user_ | mycorp Data Intelligence
date_=`date '+%Y%m%d'`
YUM_REPO=/etc/yum.repos.d/
current_version=`rpm -q splunk`
current_version_no=`echo ${current_version} |awk -F"-" '{print $2}'`
repo_url='http://nfs-bde-dev.dev.mycorp.com:/mapr/BDEDev/splunk/repos'

usage ()
{
cat<<END

Usage: $0 [ -v version_number ]

Where: -v version to backout 

END
exit 1
}

# Is Splunk running as a service account or root/splunk?
cd /opt/splunk  && {
  pre_uid=`ls -ld etc|awk '{print $3}'`
  pre_gid=`ls -ld etc|awk '{print $4}'`
  }

echo "uid=$pre_uid  gid=$pre_gid"

convert_to_service_account ()
{
  # Convert splunk to service account
  echo 
  echo "Convert /opt/splunk to service account: ${pre_uid}:${pre_gid}"
  echo 

  [ -d /opt/splunk ] && \
  cd /opt && chown -R ${pre_uid}:${pre_gid} splunk

  # Remove local splunk entry.
  sed -i '/^splunk/d' /etc/passwd /etc/group /etc/shadow /etc/gshadow

  chmod 500 /opt/splunk/bin/splunk
  chmod u+s /opt/splunk/bin/splunk
}


#########
# M A I N
#########
if [[ ! $1 ]]
then
  echo "Splunk current version: ${current_version}"
  echo
  echo -n "Enter Splunk version (ie, 6.5.2) to backout? "
  read ver
else
   while [[ $# -gt 0 ]]
   do
     case $1 in
        -v ) ver=$2
             shift
             ;;
      -*|* )
             usage
             ;;
     esac
     shift
   done
fi

{
[[ -z ${ver} ]] && usage


if [[ "${current_version_no}" != "${ver}" ]]
then
   # Stop Splunk
   splunk_status=`show_splunk|awk '/SPLUNK/{print $NF}'`
   echo splunk_status=$splunk_status
   [[ "${splunk_status}" = "UP" ]] && service splunk stop
  
   # Make sure splunk is DOWN
   status=`show_splunk|awk '/SPLUNK/{print $NF}'`
   if [[ "${status}" = "DOWN" ]]
   then
      ps aux|grep [s]plunk >/dev/null
      status=$?
      [[ "$status" != "0" ]] && {
         echo "Splunk is still UP. Backout to Splunk ${ver} Aborted."
         exit 3
      }

      # Rename current /opt/splunk/etc
      echo "Rename current /opt/splunk/etc to etc_DELETE_AFTER_3_DAYS.${current_version}"
      cd /opt/splunk && /bin/mv -f etc etc_DELETE_AFTER_3_DAYS.${current_version}
         
      # Downgrade splunk 
      echo
      # os-update deprecated.
      #os-update -y downgrade splunk
      umount -l /mnt
      mount nfs-bde-dev.dev.mycorp.com:/mapr/BDEDev/splunk /mnt
      [[ "$?" = "0" ]] && {
            echo "Downgrading Splunk to ${ver}"
            echo
            cd /mnt/${ver}/linux && {
              splunk_rpm=`ls -f splunk-${ver}*.rpm 2>/dev/null`
              [[ -z ${splunk_rpm} ]] && {
                 echo "/mnt/${ver}/linux, package does not exist. Abort"
                 exit 4
              }
              rpm -Uvh --oldpackage ${splunk_rpm}
            }
      }


      # Restore Splunk${ver} configuration...
      echo
      echo "Restore Splunk${ver} configuration"
            rpm -q splunk|grep "${ver}" >/dev/null
            if [[ "$?" = "0" ]]
            then
              cd /opt;tar xzvpf splunk_6.6.8.tar.gz 
            else
                echo "Current splunk version is still there: `rpm -q splunk`"
                exit 6
            fi

      # Check splunk's uid. If service account, convert
      cd /opt/splunk/bin  && post_uid=`ls -ld splunkd|awk '{print $3}'`

      convert_to_service_account

      ## Start Splunk....
      if [[ "${pre_uid}" = "ser_act.prod" ]] || \
         [[ "${pre_uid}" = "ser_act.dev" ]]
      then
         echo "Running su - ${pre_uid} -c '/opt/splunk/bin/splunk start --answer-yes --no-prompt --accept-license'"
         su - ${pre_uid} -c '/opt/splunk/bin/splunk start --answer-yes --no-prompt --accept-license'
      else
         echo "Running /opt/splunk/bin/splunk start --answer-yes --no-prompt --accept-license"
         /opt/splunk/bin/splunk start --answer-yes --no-prompt --accept-license
      fi
   fi
   echo
   echo "Current Splunk installed: `rpm -q splunk`"
   echo
else
   echo
   echo "${current_version_no} is already installed: ${current_version}"
   exit 2
fi

## Make sure Splunk is up....
echo
show_splunk -s
} | tee /var/tmp/`basename $0`_splunk${current_version_no}.${date_}.OUT

