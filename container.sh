#!/bin/bash
#
# Run commands inside user container.
# Call connection counters (increment-decrement).
# Stop container when connection counter is 0.
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 Riken AICS. All rights reserved.

version="2.7.6"

# Output to separate log files for every ssh connection
separatelog=0
# Verbose logs for debugging
debuglog=0

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
echo "CON: $SSH_CONNECTION" >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file
if [ $debuglog -eq 1 ]
then
    echo "USR: $USER" >> $log_file
    echo "LOG: $LOGNAME" >> $log_file
    echo "CLT: $SSH_CLIENT" >> $log_file
    echo "TTY: $SSH_TTY" >> $log_file
    echo "DIS: $DISPLAY" >> $log_file
fi
echo "> $(date)" >> $log_file

# Increment connection counter
#eval "nohup /synchro_increment.sh $counter_file $stop_file < /dev/null &" >> $log_file 2>&1
commands=( /synchro_increment.sh "$counter_file" "$stop_file" )
"${commands[@]} &" >> $log_file 2>&1

# Execute commands in container
# -----------------------------
commands=("$SSH_ORIGINAL_COMMAND")
if [ -z "$SSH_ORIGINAL_COMMAND" ]
then
    $SHELL -i
else
    if [ $debuglog -eq 1 ]
    then
    	echo "exec \"${commands}\"" >> $log_file
    fi
    eval "$commands"
fi
# -----------------------------

# After user commands exit,
# decrement connection counter

commands=(/synchro_decrement.sh "$counter_file" "$stop_file")
"${commands[@]} &" >> $log_file 2>&1

echo "<" $(date) >> $log_file
echo " " >> $log_file
