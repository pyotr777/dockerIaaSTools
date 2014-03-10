#!/bin/bash
#
# Check connection counter
# If equal to 0, then stop container.
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.6.56"

# Connections counter
counter_file="/tmp/dockeriaas_cc"
stop_file="/tmp/dockeriaas_nostop"
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
COUNTER=$(eval "/synchro_read.sh $counter_file")
echo "dw counter: $COUNTER"

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

# If connection counter is 0 or less, stop container
if [ $COUNTER -le "0" ]
then
    # Stop container
    echo $(date)
    echo "dw Stopping container"
    echo "------------------"
    kill 1
fi


