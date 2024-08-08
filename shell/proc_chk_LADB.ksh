#!/bin/ksh
#set -x

OS=`uname`

LADBFile="/tmp/LADB"
LADBName=""
LADBType=""
Today=`date +%Y%m%d`

case ${OS} in
  Linux ) AWK="/bin/awk"
          Thirtydays=`date -d "now + 30 days" "+%Y%m%d"`
          ;;
    AIX ) AWK="/bin/awk"
          if [[ -f /usr/linux/bin/date ]] then
            Thirtydays=`/usr/linux/bin/date -d "now + 30 days" "+%Y%m%d"`
          else
            Thirtydays="BLANK"
          fi
          ;;
      * ) AWK="Unknown OS"
          ;;
esac

#############################
# Usage and parameter block #
#############################

usage() {

cat<<++

###########################################################################
#                                                                         #
#         FILE: proc_chk_LADB.ksh                                         #
#                                                                         #
#        USAGE: proc_chk_LADB.ksh -n <Name> [-t <Type>] [-h]              #
#                                                                         #
#  DESCRIPTION: Check LADB authorizations for named account or group.     #
#                                                                         #
#      OPTIONS: -n <Name>                                                 #
#                  The name of the account or group to be checked         #
#                                                                         #
#               -t <a|g>                                                  #
#                  LADB type (Acct or Group)                              #
#                  The default is Acct                                    #
#                                                                         #
#               -h                                                        #
#                  This help display and exit                             #
#                                                                         #
###########################################################################

++
}

echo

if [[ `whoami` != "root" ]] then
  echo "WARN  - You are not currently running this command as root. As a result you may not get accurate answers to the 'Allowed on this server?' question."
  echo
fi

OptCount=0

while getopts n:t:h option
do
   case $option in
    n ) echo $OPTARG | tr '[:upper:]' '[:lower:]' | read LADBName
        (( OptCount=OptCount+1 ))
        ;;
    t ) echo $OPTARG | tr '[:upper:]' '[:lower:]' | read LADBType
        ;;
    h ) usage
        exit
        ;;
    * ) echo "ERROR - Invalid option chosen"
        usage
        exit
        ;;
  esac
done

if [[ ${OptCount} != 1 ]] then
  echo "ERROR - Name to check is required (-n)"
  usage
  exit
fi

if [[ "${LADBType}" == "" ]] then
  LADBType="a"
fi

case ${LADBType} in
  a) FileCheck="/etc/passwd"
     IDType="UID"
     Type="Acct"
     ;;
  g) FileCheck="/etc/group"
     IDType="GID"
     Type="Group"
     ;;
  *) echo "ERROR - '${LADBType}' is not a correct value for -t"
     echo "        Please use:"
     echo "        a for Account"
     echo "        g for Group"
     usage
     exit
     ;;
esac

grep "^${LADBName}::" ${LADBFile} | grep  -c "::${Type}::${OS}" | read CountLADB

if [[ ${CountLADB} -eq 0 ]] then

  echo "ERROR - ${LADBName} (${Type}) is not authorized in LADB"
  echo

  #################################
  # Does it exist on this server? #
  #################################

  grep -c "^${LADBName}:" ${FileCheck} | read CountInst
  if [[ ${CountInst} -eq 0 ]] then
    echo "NOTE  - ${LADBName} (${Type}) does not exist in ${FileCheck}"
  else
    echo "ERROR - ${LADBName} (${Type}) exists in ${FileCheck}"
  fi

else
  grep "^${LADBName}::" ${LADBFile} | grep  "::${Type}::${OS}" | while read ThisLADBLine
  do

    ########################################
    # Extract fields needed for validation #
    ########################################


    echo ${ThisLADBLine} | awk -F'::' '{print $2 }' | read LADB_ID
    echo ${ThisLADBLine} | awk -F'::' '{print $5 }' | read LADB_Criteria
    echo ${ThisLADBLine} | awk -F'::' '{print $6 }' | read LADB_Owner

    ###############################################################
    # JDG 20180205 - Commented out Expiry checks and notification #
    ###############################################################

    #####################
    # Check expiry date #
    #####################
    #echo ${ThisLADBLine} | awk -F'::' '{print $7 }' | read LADB_Expiry

    #if [[ ${LADB_Expiry} -lt ${Today} ]] then
    #  ExpiredDate="Has passed"
    #  ExpiredLabel="ERROR"
    #elif [[ ${Thirtydays} == "BLANK" ]] then
    #  ExpiredDate="but the projected expiry date calculations cannot be carried out"
    #  ExpiredLabel="WARN "
    #elif [[ ${Thirtydays} -ge ${LADB_Expiry}  ]] then
    #  ExpiredDate="Is due to expire within next 30 days"
    #  ExpiredLabel="WARN "
    #else
    #  ExpiredDate="Is valid for at least 30 more days"
    #  ExpiredLabel="NOTE "
    #fi

    ###############################
    # Check Criteria is fulfilled #
    ###############################

    IsItAllowed=`eval ${LADB_Criteria} 2>/dev/null`

    if [[ ${IsItAllowed} -eq 1 ]] then
      AllowedHere="Yes"
      AllowedLabel="NOTE "
    else
      AllowedHere="No"
      AllowedLabel="ERROR"
    fi

    ##############################
    # Display validation results #
    ##############################

    echo "NOTE  - ${LADBName} (${Type}) is authorized in LADB"
    echo "        ID      = ${LADB_ID}"
    echo "        OS      = ${OS}"
    echo "        Owner   = ${LADB_Owner}"
    echo
    #echo "${ExpiredLabel} - Expiry date - ${LADB_Expiry} - ${ExpiredDate}"
    #echo
    echo "${AllowedLabel} - Allowed on this server? ${AllowedHere} (Criteria=\"${LADB_Criteria}\")"
    echo

    #################################
    # Does it exist on this server? #
    #################################

    grep -c "^${LADBName}:" ${FileCheck} | read CountInst
    if [[ ${CountInst} -eq 0 ]] then
      echo "NOTE  - ${LADBName} (${Type}) does not exist in ${FileCheck}"
    else
      grep "^${LADBName}:" ${FileCheck} | awk -F':' '{print $3}' | read ThisID

      if [[ ${ThisID} == ${LADB_ID} ]] then
        echo "NOTE  - ${LADBName} (${Type}) exists in ${FileCheck} and the ${IDType} (${ThisID}) matches this rule"
      else
        echo "ERROR - ${LADBName} (${Type}) exists in ${FileCheck} and the ${IDType} (${ThisID}) does not match this rule"
      fi
    fi
    done

fi
