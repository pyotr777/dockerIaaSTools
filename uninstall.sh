#!/bin/bash

# Uninstall Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.31a08"
debug=1

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

source ./install.sh -c
source $diaasconfig

# Define output format
format="%-50s %-20s\n"

deleteFile() {
	file=$1
	if [ -a "$file" ]; then
		echo -n "Delete $file? [y/n]"
		read -n 1 delfile
		printf "\n"
		if [[ $delfile != "y" ]]; then
			printf "Bye!\n"
			exit 0
		fi
		printf "%s\t\t" "$file"
		rm -rf $file
		if [[ $? -eq 1 ]]; then
			printf "error.\n"
			echo "Error: Could not delete $file." 1>&2
			exit 1
		fi
		printf "deleted.\n"
	fi
}

deleteUser() {
	username=$1
	./cleanuser.sh $username
	printf "User %s deleted.\n" "$username"
}

# Delete users
users=$(cat $usersfile | wc -l)
if [ $users -ge 1 ]; then
	echo -n "Delete Docker IaaS users? [y/n]"
	read -n 1 rmusers
	printf "\n"
	if [[ $rmusers == "y" ]]; then
		mapfile -t userlines <<< "$(cat $usersfile)"
		for userline in "${userlines[@]}"; do
			read -ra userarray <<< "$userline"
			deleteUser ${userarray[0]}
		done
	fi
fi
printf "$format" "Users deleted" "OK"

# Group 
if [ -n "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n "Remove $diaasgroup? [y/n]"
	read -n 1 rmgroup
	printf "\n"
	if [[ $rmgroup != "y" ]]; then
		printf "Bye!\n"
		exit 0
	fi
	groupdel "$diaasgroup"
	printf "$format" "Group $diaasgroup"  "deleted"
fi

# Remove files
deleteFile "$forcecommand" 
printf "$format" "$forcecommand"  "deleted"
deleteFile "$forcecommandlog"
printf "$format" "$forcecommandlog"  "deleted"
if [ -d "$tablesfolder" ]; then 
	deleteFile "$tablesfolder" 
	printf "$format" "$tablesfolder"  "deleted"
fi

# Edit SSH config file
if [ -a "$ssh_conf" ]; then
	if grep -q "$diaasgroup" "$ssh_conf"; then
		if [ -a "tmp_$sshd_config_patch" ]; then
			patch -R "$ssh_conf" < "tmp_$sshd_config_patch"
			if [[ $? -eq 1 ]]; then
				echo "Error: Could not patch $ssh_conf." 1>&2
				exit 1
			fi
			rm "tmp_$sshd_config_patch"
			printf "$format" "Unpatch $ssh_conf" "OK"
		fi
	fi
else
	echo "Error: SSH configuration file $ssh_conf not found." 1>&2
	exit 1
fi

echo "Restart sshd? [y/n]"
read -n 1 restartssh
printf "\n"
if [[ $restartssh == "y" ]]; then
	service ssh restart			
fi

# Remove DIaaS config file
rm $diaasconfig
printf "$format" "Configuration file $diaasconfig" "deleted"

echo "Uninstallation comlete."