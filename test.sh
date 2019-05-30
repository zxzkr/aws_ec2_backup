#!/bin/bash

# region check #
region=$1
if [[ $region == "" ]] ; then echo -e "region input : $0 \e[38;3;1mREGION NAME\e[0m "; aws ec2 describe-regions --output text | cut -f3 ;exit 1 ;fi

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
for i in {196..201} {201..196} ; do echo -en "\e[48;5;${i}m LIST\e[0m" ; done ; echo
#for i in {16..21} {21..16} ; do echo -en "\e[48;5;${i}m \e[0m" ; done ; echo
cat $running_ec2_list
for i in {196..201} {201..196} ; do echo -en "\e[48;5;${i}m LIST\e[0m" ; done ; echo






