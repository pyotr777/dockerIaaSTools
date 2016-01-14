#!/bin/bash
#
# Check connection counter
# If equal to 0, then stop container.
#
# Commandline parameters:
# - counter file for storing number of active ssh connections
# - file for storing continous mode flag
# - timeout in seconds
#
# Timeout can be set from command line or config file.
# Command line value take precedence.
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2016 Riken AICS. All rights reserved

version="0.45"

# This will be replaced by createuset.sh
initvariables

logfile=$basename.log

echo "$0 v$version" >> $logfile

timeout=5
eval $(cat $container_config)

if [ $1 ]
then
    counter_file=$1
fi

if [ $2 ]
then
    stop_file=$2
fi

if [ $3 ]
then
    timeout=$3
fi


stat=($(</proc/$$/stat))    # create an array
ppid=${stat[4]}

echo "/$ppid dw ($version),timeout $timeout."

sleep $timeout

# Check "nostop" state
if [ -a $stop_file ]
then
    NOSTOP=$(cat $stop_file)
    echo "/$ppid dw nostop: $NOSTOP"

    # If "nostop" file has 1, exit dockerwatch
    if [ $NOSTOP -gt "0" ]
    then
        echo "/$ppid Nostop state"
        exit 0
    fi
fi

# Open connections counter file for reading
exec 20<$counter_file
# Lock file with shared lock
flock -x 20
COUNTER=$(cat $counter_file)
# If unlock is not called, file is unlocked automatically after process get killed.
flock -u 20
echo "/$ppid dw counter: $COUNTER"

# If connection counter is 0 or less, stop container
if [ $COUNTER -le "0" ]
then
    # Stop container
    echo "/$ppid $(date +'%Y-%m-%d %H:%M:%S.%N') dw Stopping container"
    echo " "
    kill 1
fi
