#!/bin/bash
###############################################################################
# Refer to
# https://community.splunk.com/t5/Deployment-Architecture/Using-REST-API-load-balancing-in-a-Search-Head-Cluster-why-are/m-p/262272
###############################################################################
bold_yellow="\e[1m\e[33m"
reset_color="\e[0m"

get_sessionKey ()
{
  sessionKey=$(
  {
    curl -k -u ${user}:${key} https://${node_fqdn}:8089/services/auth/login -d username=${user} -d password=$key
  } 2>/dev/null | grep sessionKey|awk -F'<sessionKey>|</sessionKey>' '{print $2}')
}

get_sid ()
{
  sid=$(
  {
   curl -k -u ${user}:${key} https://${node_fqdn}:8089/services/search/jobs -d search="search index=secops*|stats count by splunk_server|head" -d earliest_time="-15m@m" -d latest_time="-0m@m"
  } 2>/dev/null | grep 'sid'|awk -F'<sid>|</sid>' '{print $2}')
}

get_dispatchState ()
{
  dispatchState=$(
  {
    curl -k -u ${user}:${key} https://${node_fqdn}:8089/services/search/jobs/$1
  } 2>/dev/null | grep 'dispatchState'|awk -F'">|</' '{print $2}')
}

get_results ()
{
  echo -e "sid=${bold_yellow}${1}${reset_color}"
  results=$(
  {
    curl -k -u ${user}:${key} https://${node_fqdn}:8089/services/search/jobs/${1}/results --get -d output_mode=csv
  } 2>/dev/null )
}

show_SH_list ()
{
cat<<END

Here's list of PROD ES Search Heads:

CURRENT:
--------
s3110some_loc guid = 23BC1D72-6D2E-4D43-B700-6FF1A9CCB6BD
s3111some_loc guid = 6D4C1176-474C-4FB8-B234-5868A6A936F3
s3110loc2 guid = 961D3069-1FB8-49E1-B805-15DBFEFDE310
s0978loc2 guid = 77DA529F-E4AF-4013-AEFC-55F9D1AA9A0E
s0180loc3 guid = BE152D96-6D66-4D77-A4E0-6BD3E88700EB

NEW:
--------
s3111loc2 guid = 3C9AA7BA-8A07-4251-97DE-A02B45978717
s0160loc3 guid = A10B5E72-422E-4593-8C0D-F4586E14680C
s0161loc3 guid = 91D11DC0-ACD5-4B6C-B3E4-CBB4F361D8CD
s0162loc3 guid = A6DB6460-3E11-4E32-8A22-9528CA4978EF
s0181loc3 guid = EC659433-92F7-40CC-97B2-3703E5C181A0

END
read -p "Enter search head name or F5 (splunk-es.mycorp.com)? " node
}

##########
# M A I N
##########
echo -en "Enter your ${bold_yellow}first.last${reset_color}: "
read user
read -sp "Password: " key

show_SH_list

while [ 1 ]
do
  echo $node|grep -q 'splunk-es'
  if [[ "$?" = "0" ]]
  then
     node_fqdn=$node
  else
     node_fqdn=$(host ${node}|awk '{print $1}')
     nc -vz ${node} 8089 >/dev/null 2>&1
     [[ "$?" != "0" ]] && {
        echo "${node}: splunkd's DOWN"
        show_SH_list
     }
  fi
  echo "Authenticating ${user} via ${node}: "
  get_sessionKey
  [[ -z ${sessionKey} ]] && echo "User: ${user} | Authentication failed. Abort" && exit
  
  echo "sessionKey=${sessionKey}"
  echo
  echo "Running search and getting sid ...."

  get_sid
  echo -en "sid=${bold_yellow}${sid}${reset_color}"
  echo
  echo -e "Retrieve ad-hoc search status with sid: ${bold_yellow}${sid}${reset_color}"
  get_dispatchState ${sid}
  echo dispatchState=${dispatchState}
  total_secs=""
  while [[ "${dispatchState}" != "DONE" ]] 
  do
    #echo "let's wait for 1 second ..."
    get_dispatchState ${sid}
    sleep 1s
    total_secs=`expr $total_secs + 1`
    echo "${total_secs}s dispatchState=${dispatchState}"
  done
  echo "Total secs: $total_secs"
  echo
  echo "Getting results ..."
  echo
  get_results ${sid}
  echo "results=`echo ${results}|head -1`"
  echo

  read -p "Try again(Y|N)? " ans
  case $ans in
       Y|y )
            show_SH_list 
            ;;
         * )
            echo "Good Bye"
            exit
            ;;
    esac
done
