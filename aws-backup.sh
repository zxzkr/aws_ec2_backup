#!/bin/bash
nowtime=$(TZ="Asia/Seoul" date '+%Y%m%d_%Hh%Mm%Ss')

# region check #
region=$1
tmpfile=$(mktemp /tmp/region.XXXXXXXXX)
aws ec2 describe-regions --output text | cut -f3 > $tmpfile
#if [[ $region == "" ]] ; then echo -e "region input : $0 {\e[38;3;1mREGION NAME\e[0m} "; cat $tmpfile && rm -rf $tmpfile;exit 1;elif [ $(cat $tmpfile | grep $region | wc -l) -eq 0 ];then echo -e " \e[38;5;1mREGION NAME checking plz.\e[0m : $region "; cat $tmpfile && rm -rf $tmpfile ;exit 1;fi
if [[ $region == "" ]] ; then 
	echo -e "region input : $0 {\e[38;3;1mREGION NAME\e[0m} "
	cat $tmpfile && rm -rf $tmpfile
	exit 1
elif [ $(cat $tmpfile | grep $region | wc -l) -eq 0 ];then 
	echo -e " \e[38;5;1mREGION NAME checking plz.\e[0m : $region "
	cat $tmpfile && rm -rf $tmpfile 
	exit 1
fi

# ec2 list file name #
running_ec2_list=list_${region}.txt

# backup run #
backuprun=$2

# default dir create#
backup_dir="/data_backup/"
backup_dir_region="${backup_dir}${region}/"
backup_dir_log="${backup_dir}log/${region}/"
mkdir -p ${backup_dir_region}
mkdir -p ${backup_dir_log}

# ec2 list IP save #
aws ec2 --region $1 describe-instances --filters "Name=instance-state-name,Values=running"  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`]|[0].Value,PrivateIpAddress,ImageId,KeyName]' --output=text > $running_ec2_list
##echo >> Hostname, Private IP, AMI ID, key pair ####


ssh_connection(){
	ssh_status="OK"
	if [ $(curl -ksfL $ec2_pri_ip:22 --connect-timeout 3 | grep SSH | wc -l) -eq 0 ]; then 
		echo " >> $ec2_hostname($ec2_pri_ip) security group checking $nowtime << " >> ${backup_dir_log}${ec2_hostname}
		ssh_status="FAIL"
	fi
}


test_print(){
	if [[ $ec2_hostname != "" ]]; then 
		printf "%-23s %-15s %-21s %-13s %-4s" $ec2_hostname $ec2_pri_ip $ec2_ami_id $ec2_key_name $ssh_status #$ec2_user $key_pair
		echo ""
	fi
}
logo_line(){
	for i in {196..201} {201..196} ; do echo -en "\e[48;5;${i}m M Z C\e[0m" ; done ; echo
#	for i in {196..200} {200..196} ; do echo -en "\e[48;5;${i}m Megazone \e[0m" ; done ; echo
}


ssh_remote_run(){
	if [[ $ec2_hostname != "" ]]&&[[ $ssh_status == "OK" ]]; then 
		mkdir -p ${backup_dir_region}${ec2_hostname}
		echo $(TZ="Asia/Seoul" date) ":::copy::::::::" $(scp -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip:/data/${ec2_hostname}.tar.gz ${backup_dir_region}${ec2_hostname}/${ec2_hostname}_${nowtime}.tar.gz < /dev/null) >> ${backup_dir_log}${ec2_hostname}
		echo $(TZ="Asia/Seoul" date) ":::delete::::::" $(ssh -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip "sudo find /data -name ${ec2_hostname}.tar.gz -mtime +1 -delete" < /dev/null) >> ${backup_dir_log}${ec2_hostname} 
	fi
}

ssh_remote_backup(){
	if [[ $ec2_hostname != "" ]]&&[[ $ssh_status == "OK" ]]; then 
		mkdir -p ${backup_dir_region}${ec2_hostname}
		echo "$(TZ="Asia/Seoul" date)" ":::delete::::::" "$(ssh -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip "sudo find /data -name ${ec2_hostname}.tar.gz -mtime +1 -delete" < /dev/null)" >> ${backup_dir_log}${ec2_hostname}
		echo "$(TZ="Asia/Seoul" date)" ":::compression:" "$(ssh -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip "sudo tar zcfp /data/${ec2_hostname}.tar.gz /data/" < /dev/null)" >> ${backup_dir_log}${ec2_hostname} 
		echo "$(TZ="Asia/Seoul" date)" ":::disk space::" "$(ssh -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip "sudo df -h /data | tail -1" < /dev/null)" >> ${backup_dir_log}${ec2_hostname} 
#		echo $(TZ="Asia/Seoul" date) ":::disk space::"$(ssh -oStrictHostKeyChecking=no -i /data_backup/key/$key_pair $ec2_user@$ec2_pri_ip "sudo df -h /data | tail -1" < /dev/null) >> ${backup_dir_log}${ec2_hostname} && cat ${backup_dir_log}${ec2_hostname} |tail -1 #echo test
	fi
}


#test_line
list_check(){
	if [ $backuprun == "copy" ]||[ $backuprun == "zip" ]; then 
		clear
		logo_line
	else
		printf "%-23s %-15s %-21s %-13s %-4s\n" "Hostname" "Private IP" "AMI ID" "RSA key pair" "F/W"
		echo "----------------------- --------------- --------------------- ------------- ----"
	fi
	while read ec2_hostname ec2_pri_ip ec2_ami_id ec2_key_name; do
		case $ec2_ami_id in
			ami-078e96948945fc2c9)
				ec2_user="ubuntu";;
			ami-067c32f3d5b9ace91)
				ec2_user="ubuntu";;
			ami-06cf2a72dadf92410)
				ec2_user="centos";;
		esac
		case $ec2_key_name in
			mzdev-public)
				key_pair="pub";;
			mzdev-private)
				key_pair="pri";;
			mzdev-dmz)
				key_pair="dmz";;
		esac
		# exception 
		case $ec2_hostname in
			kr.mzdev.relay)
				ec2_hostname="";;
		esac

		ssh_connection # ssh_connection TEST
		#data backup?
		case $backuprun in
			zip) ssh_remote_backup;;
			copy) ssh_remote_run;;
			test|*) test_print;;
		esac
	done < $running_ec2_list
}
list_check
logo_line #print end line

#############################################################################################
# info
#echo " >> Directory : $backup_dir_region "
#echo " >> Logs : $backup_dir_log"

############ clear file
rm -rf $tmpfile
rm -rf $running_ec2_list

