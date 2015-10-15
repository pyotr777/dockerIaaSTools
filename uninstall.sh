#!/bin/bash

# Uninstall Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.31a07"
debug=1

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

source ./install.sh -c
source $diaasconfig

deleteFile() {
	file=$1
	if [ -a "$file" ]; then
		echo -n "Delete $file? [y/n]"
		read -n 1 delfile
		if [[ $delfile != "y" ]]; then
			printf "\nBye!\n"
			exit 0
		fi
		printf "\n%s\t\t" "$file"
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
	echo -n "Remove users? [y/n]"
	read -n 1 rmusers
	printf "\n"
	if [[ $rmusers == "y" ]]; then
		mapfile -t userlines <<< "$(cat $usersfile)"
		for userline in "${userlines[@]}"; do
			read -ra userarray <<< "$userline"
			deteteUser ${userarray[0]}
		done
	fi
fi

# Group 

if [ -n "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n "Remove $diaasgroup? [y/n]"
	read -n 1 rmgroup
	if [[ $rmgroup != "y" ]]; then
		printf "\nBye!\n"
		exit 0
	fi
	groupdel "$diaasgroup"
	printf "\nGroup %s\t\t\tremoved.\n" "$diaasgroup"
fi

# Remove files

deleteFile "$forcecommand" 
deleteFile "$forcecommandlog"
if [ -d "$tablesfolder" ]; then 
	deleteFile "$tablesfolder" 
fi

# Edit SSH config file
if [ -a "$ssh_conf" ]; then
	if grep -q "$diaasgroup" "$ssh_conf"; then
		printf "Unpatch %s\n" "$ssh_conf"
		text="$(cat $sshd_config_patch)"
		eval "cat <<$text" > "tmp_$sshd_config_patch"
		patch -R "$ssh_conf" < "tmp_$sshd_config_patch"
		if [[ $? -eq 1 ]]; then
			echo "error."
			echo "Error: Could not patch $ssh_conf." 1>&2
			exit 1
		fi
		rm "tmp_$sshd_config_patch"
		echo "OK."
	fi
else
	echo "Error: SSH configuration file $ssh_conf not found." 1>&2
	exit 1
fi

echo "Restart sshd? [y/n]"
read -n 1 restartssh
if [[ $restartssh == "y" ]]; then
	printf "\n"
	service ssh restart			
fi

# Remove DIaaS config file
rm $diaasconfig
echo "Configuration file $diaasconfig deleted."

echo "Uninstallation comlete."