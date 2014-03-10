#!/bin/bash
#
# Run commands inside user container.
# Call
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 Riken AICS. All rights reserved.

version="2.7.51"

# Output to separate log files for every thread
separatelog=1
welcome="Welcome, $USER !"

# Log file name
basename="/logs/container"
if [ $separatelog -eq 1 ]
then	
	num=0
	filename="$basename$num.log"
	while [ -a 	$filename ]
	do
		num=$((num + 1))
		filename="$basename$num.log"
	done
	log_file=$filename	
else 
	log_file="$basename.log"
fi
# Counter files
counter_file="/tmp/dockeriaas_cc"
stop_file="/tmp/dockeriaas_nostop"

if [ ! -w $log_file ];
then
    touch $log_file
fi

echo "container.sh $version" >> $log_file
echo "----- start -----" >> $log_file
echo "USR: $USER" >> $log_file
echo "LOG: $LOGNAME" >> $log_file
echo "CLT: $SSH_CLIENT" >> $log_file
echo "CON: $SSH_CONNECTION" >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file
echo "TTY: $SSH_TTY" >> $log_file
echo "DIS: $DISPLAY" >> $log_file

echo "> $(date)" >> $log_file

# If login from localhost, run commands without counting connections
# and exit.
if [[ $SSH_CLIENT == "::1 *" ]]
then 
	$SSH_ORIGINAL_COMMAND
	exit 0;
fi

# Increment connection counter
#eval "nohup /synchro_increment.sh $counter_file $stop_file\ < /dev/null &" >> $log_file 2>&1
commands=( /synchro_increment.sh "$counter_file" "$stop_file" )
"${commands[@]} &" >> $log_file 2>&1

# Execute commands in container
# -----------------------------
commands=("$SSH_ORIGINAL_COMMAND")
if [ -z "$SSH_ORIGINAL_COMMAND" ]
then
#	echo "$(date) $welcome" >> $log_file
    $SHELL -i
    echo "$(date)" >> $log_file
else
    echo "exec \"${commands}\"" >> $log_file
    eval "$commands"
fi
# -----------------------------

# After user commands exit,
# decrement connection counter

commands=(/synchro_decrement.sh "$counter_file" "$stop_file")
"${commands[@]} &" >> $log_file 2>&1

echo "<" $(date) >> $log_file
echo "..." >> $log_file
