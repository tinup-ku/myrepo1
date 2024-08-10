#!/bin/sh
notifyemail='usre@example.com'
healthcheckfile='/tmp/minion_healthcheck'
bootstrapmasters='some_loc14-005589domain1 some_loc14-005590domain1 host1196some_locdomain1 host1197some_locdomain1 cud1-009349.csdev.corp'
counterfile='/tmp/salt_repair_cnt'
badcount=$(cat $counterfile 2>/dev/null)
[ -z "$badcount" ] && badcount=0
unset LD_LIBRARY_PATH
export PATH=/usr/bin:$PATH:/sbin

send_alert() {
  msg=$1
  force=$2

  if [ $badcount -gt 2 -o "$force" == 'force' ]
  then
    if [ -n "$msg" ]
    then
      echo "$msg" | mailx -s "FAIL - unable to repair minion $(hostname)" $notifyemail
    fi
    echo "0" > $counterfile
  else
    #echo "INFO - No notification sent. $badcount is not gt 2"
    badcount=$(expr $badcount + 1)
    echo "$badcount" > $counterfile
  fi
}

repairminion() {
  if [ $badcount -lt 1 ]
  then
    echo
    echo "INFO - Skipping auto-repair incase we have a one-time glitch like a network outage."
    echo "       Performing salt-minion restart only."
    echo
    send_alert ""
    autorepair=0
  else
    autorepair=1
  fi

  if [ $autorepair -eq 1 ]
  then
    echo "Attempting auto-repair:"
    
    ## check if someone broke salt's python
    if [ -z "$(readlink /usr/bin/salt-minion | grep '/opt/saltstack/salt')" ]
    then
      cur_py=$(head -1 /usr/bin/salt-minion | awk -F'!' '{print $2}' | awk '{print $1}')
      TEST=$($cur_py -c 'import salt.minion' 2>&1)
      if [ $? -ne 0 ]
      then
        echo "WARN - $cur_py is unable to exec salt, looking for good py env"

        use_py='none'

        for pybin in /usr/bin/python3 /usr/libexec/platform-python /usr/bin/python3.6
        do
          TEST=$($pybin -c 'import salt.minion' 2>&1)
          if [ $? -eq 0 ]
          then
            echo "INFO - using $pybin"
            use_py=$pybin
            break
          fi
        done

        if [ "$use_py" = 'none' ]
        then
          send_alert "No working salt py env found."
          echo "FAIL - no working salt py env found."
          exit 1
        fi

        echo "Updating salt scripts:"

        for bin in /usr/bin/salt-call /usr/bin/salt-minion /usr/bin/salt-proxy
        do
          echo -n "  - updating $bin to use $use_py: "
          TEST=$(sed -i "s|^#\!/..*$|#\!${use_py}|" $bin 2>&1)

          if [ $? -eq 0 ]
          then
            echo "OK"
          else
            send_alert "unable to update $bin to use $use_py"
            echo "FAIL - unable to update."
            echo "$TEST"
            exit 1
          fi
        done
      else
        echo "INFO - $cur_py is able to run salt"
      fi
    fi

    for item in $bootstrapmasters
    do
      TEST=$(wget --no-proxy -q --no-check-certificate -nv -t 2 -T 30 "https://${item}/" -O - 2>/dev/null)
      if [ $? -eq 0 ]
      then
        bootstrapmaster=$item
        break
      fi
    done

    if [ -z "$bootstrapmaster" ]
    then
      send_alert "No bootstrap masters are reachable."
      echo "FAIL - no bootstrapmasters are reachable."
      echo "       Please contact cma_salt_admin_prod@example.com for help."
      exit 1
    fi

    myname=$(hostname | awk -F\. '{print $1}' | tr [:upper:] [:lower:])
    ## sometimes awk is busted
    [ -z "$myname" ] && myname=$(hostname)
    echo -n "  - checking for config backup for ${myname}: "
    TEST=$(wget --no-proxy -q --no-check-certificate -nv -t 2 -T 30 "https://${bootstrapmaster}/master_map/${myname}" -O /etc/salt/minion.new)

    if [ $? -eq 0 ]
    then
      echo "OK"
    else
      echo "NOT FOUND"
      echo -n "  - detecting datacenter and core values: "
      SALT_BOOTSTRAP=$(wget --no-proxy -q --no-check-certificate -nv -t 2 -T 30 "https://${bootstrapmaster}/cgi-bin/trace_to_minion" -O -)

      if [ $? -ne 0 ]
      then
        echo "FAIL - unable to detect datacenter and core values."
        echo "       Please contact cma_salt_admin_prod@example.com for help."
        send_alert "Unable to detect datacenter and core values."
        exit 1
      fi

      if [ "$SALT_BOOTSTRAP" = 'ERROR' ]
      then
        echo "FAIL - salt environment was unable to detect datacenter and core values."
        echo "       Please contact cma_salt_admin_prod@example.com"
        send_alert "Detect datacenter and core values returned ERROR."
        exit 1
      fi

      dc=$(echo "$SALT_BOOTSTRAP" | awk -F/ '{print $1}')
      core=$(echo "$SALT_BOOTSTRAP" | awk -F/ '{print $2}')

      if [ -z "$dc" -o -z "$core" ]
      then
        echo "FAIL - properly formatted SALT_BOOTSTRAP variable required."
        echo "       Please check env SALT_BOOTSTRAP value."
        sendalert "Did not get properly formatted SALT_BOOTSTRAP variable."
        exit 1
      fi

      echo "$dc/$core"

      echo -n "  - downloading minion config: "
      TEST=$(wget --no-proxy --no-check-certificate -nv -T 30 "https://${bootstrapmaster}/repair.2e84/${dc}/${core}/minion" -O /etc/salt/minion.new 2>&1)

      if [ $? -ne 0 ]
      then
        echo "FAIL - unable to download minion config file."
        send_alert "Unable to download minion config file."
        echo "$TEST"
        exit 1
      else
        echo "OK"
      fi

    fi

    echo -n "  - installing minion config: "
    TEST=$(mv /etc/salt/minion.new /etc/salt/minion 2>/dev/null)
    if [ $? -ne 0 ]
    then
      echo "FAIL - unable to install minion config file."
      send_alert "Unable to install minion config file."
      echo "$TEST"
      exit 1
    fi

    echo "OK"

    [ -f '/etc/salt/pki/minion/minion_master.pub' ] && rm /etc/salt/pki/minion/minion_master.pub
    [ -f '/etc/salt/pki/minion/syndic_master.pub' ] && rm /etc/salt/pki/minion/syndic_master.pub
  fi

  retcode=1

  if [ -n "$statuscmd" ]
  then
    echo -n "Restarting salt-minion: "
    result=$(timeout 30 $enablecmd 2>&1)
    result=$(timeout 30 pkill -9 -f salt-minion)
    result=$(timeout 30 pkill -9 -f __salt.tmp)
    result=$(timeout 30 pkill -9 -f /opt/saltstack/salt/run/run)
    sleep 10
    result=$(timeout 30 $restartcmd 2>&1)
    result=$(timeout 30 $statuscmd 2>&1)
    if [ $? -ne 0 ]
    then
      echo "FAIL - unable to restart salt-minion service."
      echo "$result"
      echo
    else
      echo "$result"
      echo -n "Sending test.ping: "

      TEST=$(timeout 30 salt-call --output=newline_values_only test.ping 2>&1)
      if [ "$TEST" = 'True' ]
      then
        echo "OK"
        retcode=0
      else
        echo -n "FAIL - "

        if [ -z "$TEST" ]
        then
          echo "cannot reach masters before timeout."
        fi

        if [ -n "$(echo "$TEST" | grep -i "DNS lookup or connection check of 'salt' failed")" ]
        then
          echo "minion config appears missing or corrupt. Run this script again to attempt fix."
        fi

        if [ -n "$(echo "$TEST" | grep -i "The Salt Master has rejected this minion's public key")" ]
        then
          echo "minion's key has changed or has been corrupted. Contact cma_salt_admin_prod@example.com for help."
        fi

        if [ -n "$(echo "$TEST" | grep -i "The Salt Master server's public key did not authenticate")" ]
        then
          echo "minion_master.pub fails authentication. Run this script again to attempt fix."
        fi
      
        if [ -n "$TEST" ]
        then
          echo "$TEST" | head -n 5
          echo
        fi
      fi
    fi
  else
    echo "FAIL - no restart cmd defined. Cannot restart service."
    retcode=1
  fi

  if [ $retcode -eq 0 ]
  then
    echo "SUCCESS - minion repaired and functional"

    if [ $autorepair -eq 1 ]
    then
      echo "0" > $counterfile
      result=$(timeout 30 salt-call test.echo 'salt_repair_script: minion successfully repaired' 2>&1)
    fi
  else
    echo 'FAIL - unable to repair minion.'
    send_alert "Unable to repair minion after multiple restarts and config file download. Please manually evaluate and repair."
  fi
}

##MAIN
######
unset LD_LIBRARY_PATH

TEST=$(uname -r)
if [ -n "$(echo $TEST | grep '\.el[789]')" ]
then
  echo "INFO - EL7/8/9 system detected"
  statuscmd='systemctl is-active salt-minion'
  restartcmd='systemctl restart salt-minion'
  enablecmd='systemctl enable salt-minion'

else
  echo "WARN - unsupported linux ($TEST). Only doing checks"
  statuscmd=''
  restartcmd=''
  enablecmd=''
fi

echo "INFO - repair count is $badcount"

echo -n "Checking if awk binary works: "
TEST=$(echo OK | awk '{print $1}')
if [ "$TEST" != 'OK' ]
then
  echo "FAIL- could not run awk command."
  echo "Correct and try again."
  exit 1
else
  echo "OK"
fi

## time to do basic SALT and OS
## sanity checks
###############################
echo -n "Checking if salt installation has basic function: "
TEST=$(salt-minion --version 2>&1)
if [ $? -ne 0 ]
then
  echo "FAIL - salt package appears to be broken."
  echo "$TEST"
  echo "Correct and try again."
  exit 1
else
  echo "OK"
fi

echo -n "Checking if salt reports a disk is full: "
TEST=$(salt-call --local test.ping 2>&1 | grep -i 'no space left on device')
if [ -n "$TEST" ]
then
  echo "FAIL - one or more filesystems are full or possibly have corruption."
  echo "$TEST"
  echo "Correct and try again."
  exit 1
else
  echo "OK"
fi

echo -n "Checking CPU usage (this takes about 15 sec): "
TEST=$(mpstat -u 15 1 2>&1)
if [ $? -ne 0 ]
then
  echo "FAIL - could not run mpstat command."
  echo "$TEST"
else
  cpuidleperc=$(echo "$TEST" | grep '^Average:' | awk '{print $NF}' | awk -F\. '{print $1}')
  if [ $cpuidleperc -lt 16 ]
  then
    echo "FAIL - CPU under heavy load. Only ${cpuidleperc}% idle."
    echo "This may impair salt-minion function."
    echo "While this is a failure will attempt to repair anyway."
    echo "If minion remains offline correct and try again."
    echo "$TEST"
    echo 
  else
    echo "OK"
  fi
fi

echo -n "Checking memory usage: "
TEST=$(free 2>&1)
if [ $? -ne 0 ]
then
  echo "FAIL - could not run free command."
  echo "$TEST"
else
  freemem=$(echo "$TEST" | grep '^Mem:' | awk '{print $7/$2 * 100.0}' | awk -F\. '{print $1}')
  if [ $freemem -lt 11 ]
  then
    echo "FAIL - system is low on memory. Only ${freemem}% avail."
    echo "This may impair salt-minion function."
    echo "While this is a failure will attempt to repair anyway."
    echo "If minion remains offline correct and try again."
    echo "$TEST"
    echo
  else
    echo "OK"
  fi
fi

echo -n "Checking if salt-minion config file appears valid: "
TEST=$(salt-call --local --out=newline_values_only config.get master 2>&1)
if [ "$TEST" = 'salt' ]
then
  echo "FAIL - forcing auto-repair and attempt to download valid config."
  echo "Master: $TEST" | xargs
  echo
  [ $badcount -lt 2 ] && badcount=1
else
  echo "OK"
fi

repairminion
