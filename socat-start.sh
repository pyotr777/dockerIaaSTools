#!/bin/bash
# Start socat TCP proxy to docker socket on specific port. Default is 4243.
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.32a02"

# Check that socat is installed
socat &>/dev/null
if [[ $? -gt 1 ]]; then
	echo -n "Install socat? [y/n]"
	read -n 1 install
	printf "\n"
	if [[ $install != "y" ]]; then
		printf "Bye!\n"
		exit 1
	fi
	apt-get install socat
fi

port=4243
if [ -n "$1" ]; then
	port=$1
fi

socat TCP-LISTEN:$port,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock &
PID=$!
status=$?
echo "Socat runs with PID $PID with status $status"
# Save socat PID in a file
echo $PID > socat.pid
# This file will be deleted right after parent process reads it