#!/bin/bash
###############################################################################
#
#  This script will register a new RHEL machine with mycorp's Satellite
#  system.
#
#  Robert Leonhard, April 2019
#
###############################################################################
PATH=/bin:/usr/bin:/sbin:/usr/sbin


# First make sure all the ports are open
PORTS="80 443 5000 5647 8140 8443 9090"
for p in $PORTS
do
	(echo > /dev/tcp/capsule.mycorp.com/$p)
	if [ $? -ne 0 ]; then
		echo "Cannot connect to capsule.mycorp.com on port $p"
		exit 1
	fi
done

# Determine the Activation Key
OS_MR=$(lsb_release -r|awk '{print $2}'|cut -c 1)
case $OS_MR in
	"5")
		AK="AK_RHEL5_Prod_x86_64"
		AKV="AK_RHEL5_Prod_x86_64"
		;;
	"6")
		AK="AK_RHEL6_Prod_x86_64"
		AKV="AK_RHEL6_VM_x86_64,AK_RHEL6_Prod_x86_64"
		;;
	"7")
		AK="AK_RHEL7_Prod"
		AKV="AK_RHEL7_VM,AK_RHEL7_Prod"
		;;
	*)
		echo "Cannot determine OS major version"
		exit 1
		;;
esac
virt-what | grep -qi vmware && AK=$AKV

# systemz uses different AKs
if [ `uname -i` = "s390x" ]; then
	HT=$(hostname | cut -c 6-9)
	if [ $HT = some_loc ] || [ $HT = loc2 ]; then
		AK=AK_RHEL7_Prod_s390x
	else
		AK=AK_RHEL7_Dev_s390x
	fi
fi

echo "Registering with $AK ..."

# Remove old remnants
rpm -qa | grep -q "cs-os-update" \
	&& rpm -qa | grep "cs-os-update" | xargs rpm -e
rpm -qa | grep -q "katello-ca-consumer" \
	&& rpm -qa | grep "katello-ca-consumer" | xargs rpm -e
rm -f /etc/yum.repos.d/os-*.repo
touch /etc/yum.local.conf
subscription-manager clean
rm -fr /var/cache/yum/*
yum clean all

# Do the registration
rpm -i http://capsule.mycorp.com/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org=com1_mycorp --activationkey=$AK
subscription-manager config --server.no_proxy=*mycorp.com
subscription-manager repos --disable=rhel-$OS_MR-server-satellite-tools-6.*-rpms --enable=rhel-$OS_MR-server-satellite-tools-6.5-rpms
yum update -q -y facter katello-agent katello-host-tools
if [ $OS_MR = 7 ]; then
	systemctl restart goferd.service
else
	service goferd restart
fi

# Show the status
echo ""
subscription-manager identity
subscription-manager attach --auto
if [ $? -ne 0 ]; then
	echo -e "\n\n\tSatellite registration failed.\n\n"
	exit 1
fi
