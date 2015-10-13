#!/bin/bash 

# Install Docker IaaS tools.
# Need to be run with root privileges.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.30"
debug=1

#### Configuration section
forcecommand="/usr/local/bin/diaas.sh"
forcecommandlog="/var/log/diaas.log"
tablesfolder="/var/lib/diaas/"
#dockercommand="docker -H localhost:4243"
dockercommand="docker"
diaasgroup="diaasgroup"
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
	export forcecommand="$forcecommand"
	export forcecommandlog="$forcecommandlog"
	export tablesfolder="$tablesfolder"
	export dockercommand="$dockercommand"
	export diaasgroup="$diaasgroup"
	echo "Variable initialisation		OK"
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
	printf "\nGroup $diaasgroup\t\tcreated.\n"
else
	printf "Group $diaasgroup\t\t\texists.\n"
fi
 
# Copy files
printf "Copy %s" "$forcecommand"
cp docker.sh "$forcecommand"
if [[ $? -eq 1 ]]; then
	printf "\terror.\n"
	echo "Error: Could not copy file $(pwd)/docker.sh to $forcecommand" 1>&2
	exit 1
fi
printf "\t\tOK."