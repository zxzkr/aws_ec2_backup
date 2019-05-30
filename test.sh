#!/bin/bash

# region check #
region=$1
tmpfile=$(mktemp /tmp/region.XXXXXXXXX)
aws ec2 describe-regions --output text | cut -f3 > $tmpfile
if [[ $region == "" ]] ; then echo -e "region input : $0 {\e[38;3;1mREGION NAME\e[0m} "; cat $tmpfile && rm -rf $tmpfile;exit 1;elif [ $(cat $tmpfile | grep $region | wc -l) -eq 0 ];then echo -e " \e[38;5;1mREGION NAME checking plz.\e[0m : $region "; cat $tmpfile && rm -rf $tmpfile ;exit 1;fi

# ec2 list file name #
running_ec2_list=list_${region}.txt

######## SSH KEY ########
#mzdev-public="./key/pub"
#mzdev-private="./key/pri"
#mzdev-dmz="./key/dmz"
#
######## Amazon AMI  #########
#ami-078e96948945fc2c9="ubuntu"
#ami-067c32f3d5b9ace91="ubuntu"
#ami-06cf2a72dadf92410="centos"

# ec2 list IP save #
aws ec2 --region $1 describe-instances --filters "Name=instance-state-name,Values=running"  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`]|[0].Value,PrivateIpAddress,ImageId,KeyName]' --output=text > $running_ec2_list
##echo >> Hostname, Private IP, AMI ID, key pair ####
#sampel >> local.mzdev.www 10.99.101.81    ami-078e96948945fc2c9   mzdev-private ####
#for i in {16..21} {21..16} ; do echo -en "\e[48;5;${i}m \e[0m" ; done ; echo
#cat $running_ec2_list



for i in {196..201} {201..196} ; do echo -en "\e[48;5;${i}m M Z C\e[0m" ; done ; echo
printf "%-25s %-15s %-21s %-20s\n" "Hostname" "Private IP" "AMI ID" "Key pair name"
echo "------------------------- --------------- --------------------- ---------------"
while read LINE; do
	#echo $LINE
	ec2_hostname=$(echo $LINE | awk '{print $1}')
	ec2_pri_ip=$(echo $LINE | awk '{print $2}')
	ec2_ami_id=$(echo $LINE | awk '{print $3}')
	ec2_key_name=$(echo $LINE | awk '{print $4}')
	printf "%-25s %-15s %-21s %-20s" $ec2_hostname $ec2_pri_ip $ec2_ami_id $ec2_key_name
	echo ""
done < $running_ec2_list
for i in {196..201} {201..196} ; do echo -en "\e[48;5;${i}m M Z C\e[0m" ; done ; echo


############ clear file
rm -rf $tmpfile
rm -rf $running_ec2_list

