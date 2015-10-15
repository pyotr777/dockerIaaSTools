#!/bin/bash 

# Install Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.31a06"
debug=1

### Configuration section
diaasconfig="diaas_installed.conf"

##### These variables saved to the above file
forcecommand="/usr/local/bin/diaas.sh"
forcecommandlog="/var/log/diaas.log"
tablesfolder="/var/lib/diaas"
mountfile="$tablesfolder/mounttable.txt"
usersfile="$tablesfolder/userstable.txt"
#dockercommand="docker -H localhost:4243"
dockercommand="docker"
diaasgroup="diaasgroup"
ssh_conf="/etc/ssh/sshd_config"
sshd_pam="/etc/pam.d/sshd"
sshd_config_patch="sshd_config.patch"
### Configuration section end

read -rd '' usage << EOF
Installation script for Docker IaaS tools v$version

Usage: \$ sudo $0 [-c]
Options: 
	-c print configuration variables and exit (can be used with source command). 
	This option does not require root privileges.
Docker IaaS tools requirements: bash, Docker, socat, jq.
Required OS: Ubuntu, Debian.
EOF

# Check section
# Exit if something's wrong

if [ $# -gt 2 ]; then
	printf "%s" "$usage"
	exit 0
fi

if [[ "$1" == "-c" ]]; then 
	export diaasconfig="$diaasconfig"
	return
elif [[ -n "$1" ]]; then
	printf "%s" "$usage"
	exit 1
fi

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

echo -n "Start installation of Docker IaaS tools? [y/n]"
read -n 1 start
if [[ $start != "y" ]]; then
	printf "\nBye!\n"
	exit 0
fi
printf "\n"

# Write variables to config file diaas_installed.conf
read -rd '' conf <<- CONF
	export forcecommand="$forcecommand"
	export forcecommandlog="$forcecommandlog"
	export tablesfolder="$tablesfolder"
	export mountfile="$mountfile"
	export usersfile="$usersfile"
	export dockercommand="$dockercommand"
	export diaasgroup="$diaasgroup"
	export ssh_conf=$ssh_conf
	export sshd_pam=$sshd_pam
	export sshd_config_patch=$sshd_config_patch
CONF
su $SUDO_USER -c "printf \"%s\" \"$conf\" > $diaasconfig"
echo "Configuration saved to file $diaasconfig"


dockerimagesline=$($dockercommand images 2>/dev/null | grep IMAGE | wc -l)
if [[ $dockerimagesline -eq 0 ]]; then
	printf "\nError: Cannot connect to Docker with command:\n%s" "$dockercommand" 1>&2
	exit 1
elif [[ $dockerimagesline -eq 1 ]]; then
	printf "\nConnection to Docker\t\t\tOK."
else
	printf "\nSomethings wrong :%s" "$dockerimagesline"
fi
printf "\n"
# Check section end

# Group diaasgroup - create if not exists

if [ -z "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n "Create group $diaasgroup? [y/n]"
	read -n 1 creategroup
	if [[ $creategroup != "y" ]]; then
		echo "\nBye!\n"
		exit 0
	fi
	groupadd "$diaasgroup"
	printf "\nGroup $diaasgroup\t\t\tcreated.\n"
else
	printf "Group $diaasgroup\t\t\texists.\n"
fi
 
# Copy files
printf "Copy %s\t\t" "$forcecommand"
cp docker.sh "$forcecommand"
if [[ $? -eq 1 ]]; then
	printf "error.\n"
	echo "Error: Could not copy file $(pwd)/docker.sh to $forcecommand" 1>&2
	exit 1
fi
printf "OK.\n"

if [ ! -a "$forcecommandlog" ]; then
	printf "Create %s\t\t" "$forcecommandlog"
	touch "$forcecommandlog"
	if [[ $? -eq 1 ]]; then
		printf "error.\n"
		echo "Error: Could not create $forcecommandlog." 1>&2
		exit 1
	fi
	printf "OK.\n"
fi


if [ ! -d "$tablesfolder" ]; then 
	if [ -f "$tablesfolder" ]; then
		echo "Error: $tablesfolder exists, but is a regular file. Need directory." 1>&2
		exit 1
	fi
	printf "Create %s\t\t" "$tablesfolder"
	mkdir -p "$tablesfolder"
	if [[ $? -eq 1 ]]; then
		printf "error.\n"
		echo "Error: Could not create $tablesfolder." 1>&2
		exit 1
	fi
	printf "OK.\n"
fi

if [ ! -a "$mountfile" ]; then
	printf "Create %s\t\t" "$mountfile"
	touch "$mountfile"
	if [[ $? -eq 1 ]]; then
		printf "error.\n"
		echo "Error: Could not create $mountfile." 1>&2
		exit 1
	fi
	printf "OK.\n"
fi

if [ ! -a "$usersfile" ]; then
	printf "Create %s\t\t" "$usersfile"
	touch "$usersfile"
	if [[ $? -eq 1 ]]; then
		printf "error.\n"
		echo "Error: Could not create $usersfile." 1>&2
		exit 1
	fi
	printf "OK.\n"
fi


# Edit config files
if [ -a "$sshd_pam" ]; then
	sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' "$sshd_pam"
	if [[ $? -eq 0 ]]; then
		printf "%s\t\t\t\tedited.\n(session required pam_loginuid.so -> session optional pam_loginuid.so)\n" "$sshd_pam"
	fi
fi


if [ -a "$ssh_conf" ]; then
	if grep -q "$diaasgroup" "$ssh_conf"; then
		# do nothing
		echo "$ssh_conf already patched."
	else
		printf "Patch %s\n" "$ssh_conf"
		text="$(cat $sshd_config_patch)"
		eval "cat <<$text" > "tmp_$sshd_config_patch"
		patch "$ssh_conf" < "tmp_$sshd_config_patch"
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
	service ssh restart			
else
	printf "\nPlease, restart sshd later with\n\$ sudo service ssh restart\n"
fi

echo "Installation comlete."