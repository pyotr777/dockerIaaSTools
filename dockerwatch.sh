#!/bin/bash

# Check processes inside container
# If "sacred process" is not running, then stop container;
# If stop_dockerwatch string found inside sacred_proc_file, then exit dockerwatch.
#
# Created by Bryzgalov Peter on 2014/01/31.
# Copyright (c) 2013 Riken AICS. All rights reserved

version="1.46"

# Sacred processes read from file
sacred_proc_file="/tmp/proc.tmp"
# Store list of processes in tmp file
tmp_file="/tmp/ps.tmp"
# If this stinrg found in sacred_proc_file, then exit dockerwatch
stop_dockerwatch="stopdockerwatch"
timeout=3

ps_command="ps ax"

function procsCheck {
    # Check sacred process in running processes

    $ps_command
    $ps_command > $tmp_file
    sacred_proc=$(cat $sacred_proc_file)
    if grep -q "$sacred_proc" $tmp_file
    then
        echo "Matched"
        return 1
    else
        echo "Sacred process not found in $tmp_file"
    fi
    # Check stop_dockerwatch string inside sacred_proc_file
    if grep -q "$stop_dockerwatch" $sacred_proc_file
    then
        echo "Exit dockerwatch command found in $sacred_proc_file. Exiting."
        exit 0
    else
        echo "Exit dockerwatch command not found in in $sacred_proc_file."
    fi
    return 0
}

echo "Start dockerwatch $version. Sacred process: $(cat $sacred_proc_file)"
echo "--------------------------------------"
procsCheck
matched=$?

while [ $matched -eq 1 ]
do
    sleep $timeout
    # Check value in sacred proc file
    procsCheck
    matched=$?
done

# Stop container
echo "Stopping container"
echo "------------------"
kill 1
