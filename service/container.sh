#!/bin/bash
#
# Run commands inside user container.
# Call connection counters (increment-decrement).
# Stop container when connection counter is 0.
#
# Created by Bryzgalov Peter 
# Copyright (c) 2013-2016 Riken AICS. All rights reserved.

version="0.45c"

# Output to separate log files for every ssh connection
separatelog=0
# Verbose logs for debugging
debuglog=1

# This will be replaced by createuset.sh
initvariables

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

if [ ! -w $log_file ];
then
    touch $log_file
fi

echo "> $$ $(date +'%Y-%m-%d %H:%M:%S.%N') container.sh ($version)" >> $log_file
if [ $debuglog -eq 1 ]
then
    echo "----- start -----" >> $log_file
    echo "CON: $SSH_CONNECTION" >> $log_file
    echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file
    echo "USR: $USER" >> $log_file
    echo "MNT: $(mount | grep sshfs)" >> $log_file
    echo "CLT: $SSH_CLIENT" >> $log_file
    echo "TTY: $SSH_TTY" >> $log_file
    echo "DIS: $DISPLAY" >> $log_file
    echo "$servdir" >> $log_file
fi

# Increment connection counter
commands=( $servdir/synchro_increment.sh "$counter_file" )
"${commands[@]}" >> $log_file 2>&1

# Execute commands in container
# -----------------------------
commands=("$SSH_ORIGINAL_COMMAND")
if [ -z "$SSH_ORIGINAL_COMMAND" ]
then
    #echo "start shell" >> $log_file
    $SHELL -i
    #echo "exit shell" >> $log_file
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

echo "starting $servdir/synchro_decrement.sh" >> $log_file
nohup $servdir/synchro_decrement.sh >>$log_file 2>&1 & 
sleep 2  # If this script dies before the child process started, child is never started.

echo "< $$ $(date +'%Y-%m-%d %H:%M:%S.%N')" >> $log_file
echo " " >> $log_file
