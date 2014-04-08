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
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.9.04"

# Connections counter
counter_file="/tmp/dockeriaas_cc"
stop_file="/tmp/dockeriaas_nostop"
config_file="/tmp/dockeriaas_conf"
config_reader="/readconf.py"
timeout=5

# Read timeout from config file
val=$(python $config_reader $config_file)
#echo "Configuration file:"
#echo $val
eval "$val"

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
pparent=${stat[4]}

echo "/$pparent $(date +'%Y-%m-%d %H:%M:%S.%N') dockerwatch.sh ($version),timeout $timeout."

sleep $timeout

# Check "nostop" state
if [ -a $stop_file ]
then
    NOSTOP=$(cat $stop_file)
    echo "/dw nostop: $NOSTOP"

    # If "nostop" file has 1, exit dockerwatch
    if [ $NOSTOP -gt "0" ]
    then
        echo "/dw Nostop state"
        exit 0
    fi
fi

# Open connections counter file for reading
exec 20<$1
# Lock file with shared lock
flock -x 20
COUNTER=$(cat $1)
echo "/$pparent $(date +'%Y-%m-%d %H:%M:%S.%N') dw counter: $COUNTER"

# If connection counter is 0 or less, stop container
if [ $COUNTER -le "0" ]
then
    # Stop container
    echo "/$pparent $(date +'%Y-%m-%d %H:%M:%S.%N') dw Stopping container"
    echo " "
    kill 1
fi

# If unlock file is not called, file is unlocked automatically after process get killed.
flock -u 20


