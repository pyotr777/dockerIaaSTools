#!/bin/bash
#
# Print free port number.
# Loops through the port range and returns first port number that is not used.
#
# Created by Bryzgalov Peter
# Copyright (c) 2014 Japan Riken AICS. All rights reserved

# Port range. Use dynamic port numbers.
startport=49152
endport=65535

# Which netstat?
test=$(netstat -V 2>/dev/null)

if [[ $test == *"net-tools"* ]]
then	
	# Array of used port numbers
	used=( $(netstat -n -t | grep : | awk '{ print $4 }' |  awk -F ':' '{ print $2 }') )
else 
	used4=( $(netstat -n -p tcp | grep "tcp4" | awk '{ print $4 }' |  awk -F '.' '{ print $5 }') )
	used6=( $(netstat -n -p tcp | grep "tcp6" | awk '{ print $4 }' |  awk -F '.' '{ print $2 }') )
	used=( "${used4[@]}" "${used6[@]}" )
fi

#echo "${used[@]}"

for port in $(seq $startport $endport)
do
	isused="false"
	for uport in "${used[@]}"
	do
		if [ "$port" == "$uport" ]
		then 
			isused="true"
			break
		fi
	done
	if [ "$isused" == "false" ]
	then
		echo "$port"
		break			
	fi
done

