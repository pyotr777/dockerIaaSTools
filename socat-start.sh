#!/bin/bash
# Start socat TCP proxy to docker socket on specific port. Default is 4243.
# File with Docker IaaS Tools settings must exist. 
# If socat is not running, it will be started.
# If socat pid is alreary in settings file (an old one), it will be
# replaced with new PID.
#
# Parameters:
#	"savepid" flag to save socat pid to file (optional)
#
# Requires:
# 	docker
#	socat
#	apt-get
#	sed
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.42socat_exec03"

if [[ $debug ]]; then
	echo "$@"
fi

# Read parameters from diaas config file
eval $(./install.sh -c)
if [ ! -f "$diaasconfig" ]; then
	echo "Configuration file not found. DIaaS may not have been installed."
	exit 1
fi
source $diaasconfig
 
# Set port number and savepid flag
port=$dockerport
if [[ -n "$1" ]]; then
	savepidtest="$(echo $1 | grep savepid)"
	if [[ -n "$savepidtest" ]]; then
		savepid="yes"
	fi
fi

# Check that socat is installed
socat &>/dev/null
if [[ $? -gt 1 ]]; then
	echo -n " Install socat? [y/n]"
	read -n 1 install
	printf "\n"
	if [[ $install != "y" ]]; then
		printf "Bye!\n"
		exit 1
	fi
	apt-get install -y socat
fi

# Check if socat already running
read pid junk <<<"$(ps a | grep socat | grep $port | grep docker | grep -v grep)"
if [[ -n "$pid" ]]; then
	echo "Socat already running with PID $pid"
else
	# Start socat
	socat TCP-LISTEN:$port,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock &
	pid=$!
	status=$?
	if [[ $debug ]]; then
		echo "Socat started with PID $pid with status $status"
	fi
	if grep -qE "socatpid=\"[0-9]+\"" "$diaasconfig"; then
		error=$( { sed -ri "s/socatpid=\"[0-9]+\"/socatpid=$pid/" "$diaasconfig" > /dev/null; } 2>&1 )
		if [ -n "$error" ]; then
			# OSX version
			sed -E -i '' "s/socatpid=\"[0-9]+\"/socatpid=$pid/" "$diaasconfig"
		fi
	fi
fi
# Replace old PID with new one in diaas configuration file

if [[ -n "$savepid" ]]; then
	# Save socat PID in a file
	echo $pid > socat.pid
	# This file will be deleted right after parent process reads it
fi
printf "$format"  "socat" "started with PID $pid"
