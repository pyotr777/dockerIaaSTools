#!/bin/bash

# Uninstall Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.45"
debug=1

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

eval $(./install.sh -c)
if [ ! -f "$diaasconfig" ]; then
	echo "Configuration file not found. DIaaS may not have been installed."
	exit 1
fi
source $diaasconfig

deleteFile() {
	file=$1
	if [ -a "$file" ]; then
		rm -rf $file
		if [[ $? -eq 1 ]]; then
			echo "Error: Could not delete $file." 1>&2
			exit 1
		fi
		printf "$format" "$file" "deleted"
	fi
}

deleteUser() {
	username=$1
	./cleanuser.sh $username
	printf "$format" "User $username" "deleted"
}

# Delete users
users=$(cat $usersfile | wc -l)
if [ $users -ge 1 ]; then
	echo -n " Delete Docker IaaS users? [y/n]"
	read -n 1 rmusers
	printf "\n"
	if [[ $rmusers == "y" ]]; then
		mapfile -t userlines <<< "$(cat $usersfile)"
		for userline in "${userlines[@]}"; do
			read -ra userarray <<< "$userline"
			deleteUser ${userarray[0]}
		done
	fi
	printf "$format" "Users deleted" "OK"
fi

# Group 
if [ -n "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n " Remove $diaasgroup? [y/n]"
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
deleteFile "$forcecommandlog"
deleteFile "$tablesfolder" 

# Restore SSH config file
if [ -f "$ssh_backup" ]; then
	echo -n " Restore backed up version of $ssh_conf? [y/n]"
	read -n 1 restoressh
	printf "\n"
	if [[ $restoressh != "y" ]]; then
		printf "$format" "$ssh_conf" "Leave untached"
	else 
		mv "$ssh_backup" "$ssh_conf"
		printf "$format" "$ssh_conf" "Restored original version"
	fi
else
	echo "Error: SSH configuration file $ssh_conf not found." 1>&2
fi

# Edit /etc/pam.d/sshd
if [ -n "$sshd_pam_edited" ]; then
	sed -ri 's/^session\s+optional\s+pam_loginuid.so$/session    required      pam_loginuid.so/' "$sshd_pam"
	if [[ $? -eq 0 ]]; then
		printf "$format"  "$sshd_pam" "restored: session optional pam_loginuid.so -> session required pam_loginuid.so"
	fi
fi

echo -n " Restart sshd? [y/n]"
read -n 1 restartssh
printf "\n"
if [[ $restartssh == "y" ]]; then
	service ssh restart			
fi

# Remove DIaaS config file
rm $diaasconfig
printf "$format" "$diaasconfig" "deleted"

# Kill socat
if [[ -n $socatpid ]]; then
	kill $socatpid
	printf "$format" "socat proxy" "killed"	
fi

echo "Uninstallation comlete."
