#!/bin/bash

# FUNCTIONS

add_keys_WGET() {

# Token will be from the svc.ukmdiscoveryprod account in bitbucket
WGET_STATUS=$(wget -q --server-response --header="Authorization: Bearer $BITBUCKET_TOKEN"  $BITBUCKET_DIRECTORY/$BITBUCKET_FILE -P $KEY_DIRECTORY 2>&1 | awk 'NR==1{print $2}')

}

add_keys_API() {

# Loop through all the tagged keys.

while read -r line
do

# KEY ID gets the id of the authorized key
# AUTH_ID_LENGTH gets the amount of servers in the "from" of the SSH Key
# KEY DATA Main part of the SSH Key
# KEY_COMMENT Comment of the key, usually the owner

export KEY_ID=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-keys/ -G --data-urlencode "_id__in=$line" | python -c 'import sys, json; print(json.load(sys.stdin)["values"][0]["key_pair_id"])')

export AUTH_ID_LENGTH=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-keys/ -G --data-urlencode "_id__in=$line" | python -c 'import sys, json; print(json.load(sys.stdin)["values"][0]["authorized_key_option_ids"])' | tr ',' '\n' | tr -d '[]' | sed '/^$/d' | wc -l)

export KEY_DATA=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/key-data/$KEY_ID/ | python -c 'import sys, json; print(json.load(sys.stdin)["values"]["data"])')

export KEY_COMMENT=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-keys/ -G --data-urlencode "_id__in=$line" | python -c 'import sys, json; print(json.load(sys.stdin)["values"][0]["key_comment"])')

# Loops through the KEY_OPTION to get all the servers in the "from"
counter=0
AUTH_KEY_ARRAY=()
    while [[ $counter != $AUTH_ID_LENGTH ]]
    do

        export AUTH_ID=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-keys/ -G --data-urlencode "_id__in=$line" | python -c 'import sys, json; print(json.load(sys.stdin)["values"][0]["authorized_key_option_ids"]['$counter'])')

        export AUTH_KEY=$(curl --insecure -s -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-key-options/$AUTH_ID/ | python -c 'import sys, json; print(json.load(sys.stdin)["values"]["value"])')

        AUTH_KEY_ARRAY+=("$AUTH_KEY"",")
        counter=$(( $counter + 1 ))

    done

# If there is no KEY COMMENT it blanks out the variable
        if [[ $KEY_COMMENT == "None" ]];then
            KEY_COMMENT=""
        fi

        # Reads the array and places the output into the KEY_OPTION variable.  Based on the array output, the AUTHORIZED_KEY is set
        READ_ARRAY=$(printf "%s" "${AUTH_KEY_ARRAY[@]}" | sed 's/.\{1\}$//')
            if [ ! -z "$READ_ARRAY" ];then
                KEY_OPTION=$(echo "from="\"$READ_ARRAY"\"")
                AUTHORIZED_KEY="$KEY_OPTION $KEY_DATA $KEY_COMMENT"
            else
                AUTHORIZED_KEY="$KEY_DATA $KEY_COMMENT"
            fi

    # Check to see if the key is already added to the KEY LOCATION
    if ! grep -q "$KEY_DATA" $KEY_LOCATION > /dev/null 2>&1
    then
        echo $AUTHORIZED_KEY >> $KEY_LOCATION
    fi

# cud1-008594domain1 will be used as the main source of the authorized keys
done < <(curl --insecure -sD - -X GET -m 10 -H "Authorization: Bearer $UKM_TOKEN" -H "Accept: application/json; indent=4" $URL/api/v3/authorized-keys/ -G --data-urlencode "tag=$TAG" --data-urlencode "host=cud1-008594domain1" | grep '"_id"' | cut -d':' -f2 | sed 's/"//g' | sed 's/,//g')

}


# VARIABLES

# Tokens must be provied.  1st token is for bitbucket access.  2nd token is from UKM Admin UI
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Provide tokens"
    exit 1
fi

BITBUCKET_TOKEN=$1
UKM_TOKEN=$2

# URL of the keymanager frontends
#URL="https://ukmadmin.devdomain1"
URL="https://ukmadmindomain1"

# KEY_DIRECTORY high level directory
KEY_DIRECTORY=/ssh-keys

# Bitbucket location
BITBUCKET_DIRECTORY="https://bitbucketdomain1/projects/SCSSE/repos/ssh_ukm/raw/scripts/server_builds/ssh-keys"


# TAG key that is being searched
# KEY_LOCATION is where the keys are copied to
####################################################

# /ssh-keys/root
TAG=^standard
KEY_LOCATION=$KEY_DIRECTORY/root
BITBUCKET_FILE=root

# If SSH Key file DOES NOT exist then run the add_keys_API, else run add_keys_WGET.  If add_keys_WGET is run, check status of wget command.  If it fails, run add_keys_API
if [[ -f "$KEY_LOCATION" ]];then
    add_keys_API
else
    add_keys_WGET
    if [[ $WGET_STATUS -ne 200 ]]
    then
        rm -rf $KEY_LOCATION
        add_keys_API
    fi
fi

####################################################

# /ssh-keys/svc.auditlogservice

TAG=svc.auditlogservice_standard
KEY_LOCATION=$KEY_DIRECTORY/svc.auditlogservice
BITBUCKET_FILE=svc.auditlogservice

if [[ -f "$KEY_LOCATION" ]];then
    add_keys_API
else
    add_keys_WGET
    if [[ $WGET_STATUS -ne 200 ]]
    then
        rm -rf $KEY_LOCATION
        add_keys_API
    fi
fi
####################################################

# /ssh-keys/svc.ceauto

TAG=svc.ceauto_standard
KEY_LOCATION=$KEY_DIRECTORY/svc.ceauto
BITBUCKET_FILE=svc.ceauto

if [[ -f "$KEY_LOCATION" ]];then
    add_keys_API
else
    add_keys_WGET
    if [[ $WGET_STATUS -ne 200 ]]
    then
        rm -rf $KEY_LOCATION
        add_keys_API
    fi
fi
