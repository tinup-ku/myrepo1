#!/bin/bash
##########################################################################
#
# This script is for creating a skeleton Forwarder App.
# using template in /root/scripts/EXAMPLEForwarderApp.
#
# Input is the Forwarder App Name.
#
# The output will be placed in /tmp/${forwarderName}.
#
##########################################################################

# get filename
echo -n "Enter the new Forwarder App Name you want to create (for example, SNE): "
read forwarderName

echo " "
echo "You entered : ${forwarderName}"
echo " "

# remove old copy in case there is one
cd /tmp && rm -rf ${forwarderName}
cd /tmp && rm -rf ${forwarderName}Pointer

# make a copy of the template folder to /tmp
mkdir /tmp/${forwarderName}
mkdir /tmp/${forwarderName}Pointer

cp -r /root/scripts/EXAMPLEForwarderApp/app/EXAMPLE/*  /tmp/${forwarderName}/.
cp -r /root/scripts/EXAMPLEForwarderApp/serverclassApps/EXAMPLEPointer/* /tmp/${forwarderName}Pointer/.

# Replace EXAMPLE with the inputted index name
cd /tmp/${forwarderName}        && find . -type f -name *.conf -exec sed -i"" -e "s/EXAMPLE/${forwarderName}/g" {} +
cd /tmp/${forwarderName}Pointer && find . -type f -name *.conf -exec sed -i"" -e "s/EXAMPLE/${forwarderName}/g" {} +

echo " "
echo "=================================================================================================="
echo " Forwarder App ${forwarderName} created in /tmp/${forwarderName} and /tmp/${forwarderName}Pointer."
echo "=================================================================================================="
echo " "
echo " Next Steps : "
echo " "
echo "1.  Please edit  /tmp/${forwarderName}/local/app.conf to have the correct APMID, Owner, and Contact Info. "
echo " "
echo "2.  Then copy to the appropriate bitbucket location for deployment. You should make sure you already created a branch, checked-out, and pulled."
echo " "
echo "       For example, copy to /bitbucket/<your user id>/tos_splunk_apps/dev/forward/apps/${forwarderName}  and serverclassApps/${forwarderName}Pointer"
echo " "
echo "       Then check-in, submit pull request, get it approved, and merge back to master."
echo " "
echo "3.  Perform a deployment of what is in bitbucket when ready."
echo " "

