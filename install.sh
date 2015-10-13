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

Usage: \$ sudo $0

Docker IaaS tools requirements: bash, Docker, socat, jq.
Required OS: Ubuntu, Debian.
EOF

# Check section
# Exit if something's wrong

if [ $# -ge 1 ]; then
	printf "%s" "$usage"
	exit 0
fi

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

echo -n "Start installation of Docker IaaS tools? [y/n]"
read -n 1 start

if [[ $start != "y" ]]; then
	printf "\n%s" "$usage"
	exit 0
fi

dockerimagesline=$($dockercommand images 2>/dev/null | grep IMAGE | wc -l)
if [[ $dockerimagesline -eq 0 ]]; then
	printf "\nError: Cannot connect to Docker with command:\n%s" "$dockercommand" 1>&2
	exit 1
elif [[ $dockerimagesline -eq 1 ]]; then
	printf "\nConnection to Docker	OK."
else
	printf "\nSomethings wrong :%s" "$dockerimagesline"
fi
printf "\n"
# Check section end

# Group diaasgroup - create if not exists

if [ -z "$(cat /etc/group | grep "$diaasgroup:")" ]; then
	echo -n "Creating group $diaasgroup. OK? [y/n]"
	read -n 1 creategroup
	if [[ $creategroup != "y" ]]; then
		echo "\nBye!\n"
		exit 0
	fi
	groupadd "$diaasgroup"
fi
 

