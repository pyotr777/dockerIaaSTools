#!/bin/bash
#
# Run commands inside user container.
# Call
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 Riken AICS. All rights reserved.

version="2.7.37"

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
#echo "USR: $USER" >> $log_file
#echo "CLT: $SSH_CLIENT" >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file

echo "> $(date)" >> $log_file
# Increment connection counter
#eval "nohup /synchro_increment.sh $counter_file $stop_file\ < /dev/null &" >> $log_file 2>&1
eval "/synchro_increment.sh $counter_file $stop_file" >> $log_file 2>&1

# Execute commands in container
# -----------------------------
commands=$SSH_ORIGINAL_COMMAND
if [ -z "$SSH_ORIGINAL_COMMAND" ]
then
    echo "$(date) $welcome" >> $log_file
    $SHELL -l
    echo "$(date)" >> $log_file
else
    echo "$commands" >> $log_file
    eval "$commands"
fi
# -----------------------------

# After user commands exit,
# decrement connection counter

sd_call_command="/synchro_decrement.sh $counter_file $stop_file &"
#eval "$sd_call_command" >> $log_file 2>&1
eval "/synchro_decrement.sh $counter_file $stop_file" >> $log_file 2>&1

echo "<" $(date) >> $log_file
echo "..." >> $log_file
