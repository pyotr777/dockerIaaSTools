#!/bin/bash

# Uninstall Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.30"
debug=1

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

source ./install.sh -c

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
		printf "Edit %s\t\t" "$ssh_conf"
		read -rd '' conf <<- CONF
			AllowAgentForwarding yes

			Match Group $diaasgroup
				ForceCommand $forcecommand
		CONF
		sed '/$conf/d' "$ssh_conf"
		if [[ $? -eq 1 ]]; then
			printf "error.\n"
			echo "Error: Could not edit $ssh_conf." 1>&2
			exit 1
		fi
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

echo "Uninstallation comlete."