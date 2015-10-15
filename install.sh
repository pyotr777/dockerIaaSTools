#!/bin/bash 

# Install Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.31a09"
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
printf "\n"
if [[ $start != "y" ]]; then
	printf "Bye!\n"
	exit 0
fi



# Define output format
format="%-50s %-20s\n"

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
	export format="$format"
CONF
su $SUDO_USER -c "printf \"%s\" \"$conf\" > $diaasconfig"
echo "Configuration saved to file $diaasconfig"


dockerimagesline=$($dockercommand images 2>/dev/null | grep IMAGE | wc -l)
if [[ $dockerimagesline -eq 0 ]]; then
	printf "Error: Cannot connect to Docker with command:\n%s\n" "$dockercommand" 1>&2
	exit 1
elif [[ $dockerimagesline -eq 1 ]]; then
	printf "$format" "Connection to Docker" "OK"
else
	printf "Somethings wrong :%s\n" "$dockerimagesline"
	exit 1
fi
# Check section end

# Group diaasgroup - create if not exists

if [ -z "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n "Create group $diaasgroup? [y/n]"
	read -n 1 creategroup
	printf "\n"
	if [[ $creategroup != "y" ]]; then
		echo "Bye!"
		exit 0
	fi
	groupadd "$diaasgroup"
	printf "$format" "Group $diaasgroup" "created"
else
	printf "$format" "Group $diaasgroup" "exists"
fi
 
# Copy files
cp docker.sh "$forcecommand"
if [[ $? -eq 1 ]]; then
	echo "Error: Could not copy file $(pwd)/docker.sh to $forcecommand" 1>&2
	exit 1
fi
printf "$format" "Copy $forcecommand" "OK"

if [ ! -a "$forcecommandlog" ]; then
	touch "$forcecommandlog"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $forcecommandlog." 1>&2
		exit 1
	fi
	printf "$format" "Create $forcecommandlog" "OK"
fi


if [ ! -d "$tablesfolder" ]; then 
	if [ -f "$tablesfolder" ]; then
		echo "Error: $tablesfolder exists, but is a regular file. Need directory." 1>&2
		exit 1
	fi
	mkdir -p "$tablesfolder"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $tablesfolder." 1>&2
		exit 1
	fi
	printf "$format" "Create $tablesfolder" "OK"
fi

if [ ! -a "$mountfile" ]; then
	touch "$mountfile"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $mountfile." 1>&2
		exit 1
	fi
	printf "$format" "Create $mountfile" "OK"
fi

if [ ! -a "$usersfile" ]; then
	touch "$usersfile"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $usersfile." 1>&2
		exit 1
	fi
	printf "$format" "Create $usersfile" "OK"
fi


# Edit config files
if [ -a "$sshd_pam" ]; then
	sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' "$sshd_pam"
	if [[ $? -eq 0 ]]; then
		printf "$format"  "$sshd_pam" "edited"
		echo "(session required pam_loginuid.so -> session optional pam_loginuid.so)"
	fi
fi

# Patch /etc/ssh/sshd_conf
if [ -a "$ssh_conf" ]; then
	if grep -q "$diaasgroup" "$ssh_conf"; then
		# do nothing
		printf "$format" "$ssh_conf" "already patched"
	elif grep -qi "forcecommand" "$ssh_conf"; then
		printf "$format" "$ssh_conf" "already has ForceCommand.\nCheck that it has the following:\n"
		echo "AllowAgentForwarding yes"
		echo "Match Group $diaasgroup"
		echo "	ForceCommand $forcecommand"
		echo "----------"
		echo "Fragment of your $ssh_conf file:"
		grep -C 4 "$diaasgroup" "$ssh_conf"
		echo -n "Please confirm [press any key]"
		read -n 1 foo
		printf "\n"
	else
		text="$(echo EOF;cat $sshd_config_patch;echo EOF)"
		eval "cat <<$text" > "tmp_$sshd_config_patch"
		patch "$ssh_conf" < "tmp_$sshd_config_patch"
		if [[ $? -eq 1 ]]; then
			echo "Error: Could not patch $ssh_conf." 1>&2
			exit 1
		fi
		printf "$format" "Patch $ssh_conf" "OK"
	fi
else
	echo "Error: SSH configuration file $ssh_conf not found." 1>&2
	exit 1
fi

echo -n "Restart sshd? [y/n]"
read -n 1 restartssh
printf "\n"
if [[ $restartssh == "y" ]]; then
	service ssh restart			
else
	printf "Please, restart sshd later with:\n\$ sudo service ssh restart\n"
fi

echo "Installation comlete."