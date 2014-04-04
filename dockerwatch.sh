#!/bin/bash
#
# Check connection counter
# If equal to 0, then stop container.
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.7.7"

# Connections counter
counter_file="/tmp/dockeriaas_cc"
stop_file="/tmp/dockeriaas_nostop"
conifg_file="/tmp/conf"
timeout=5

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

echo "dockerwatch.sh $version watching $counter_file and $stop_file, timeout $timeout."
sleep $timeout

# Check "nostop" state
if [ -a $stop_file ]
then
    NOSTOP=$(eval "/synchro_read.sh $stop_file")
    echo "dw nostop: $NOSTOP"

    # If "nostop" file has 1, exit dockerwatch
    if [ $NOSTOP -gt "0" ]
    then
        echo "dw Nostop state"
        exit 0
    fi
fi

# Open connections counter file for reading
exec 20<$1
# Lock file with shared lock
flock -s 20
COUNTER=$(cat <&20)
echo "dw counter: $COUNTER"

# If connection counter is 0 or less, stop container
if [ $COUNTER -le "0" ]
then
    # Stop container
    echo $(date)
    echo "dw Stopping container"
    echo "------------------"
    kill 1
fi

# Unlock file is not called, but file is unlocked automatically.
# flock -u 20


