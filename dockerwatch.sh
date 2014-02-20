#!/bin/bash
#
# Check connection counter
# If equal to 0, then stop container.
#
# Created by Bryzgalov Peter on 2014/02/20
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.14"

# Connections counter
counter_file="/tmp/connection_counter"
timeout=2

function synchro_read {
    counter_file=$1
    exec 20>$counter_file
    flock -x -w 2 20
    COUNTER=$(cat $counter_file)
    echo "Read counter $COUNTER;"
    flock -u 20
    return $COUNTER
}

echo "Start dockerwatch $version"
echo "$(date) sleep $timeout..."
sleep $timeout
echo "$(date)"
synchro_read $counter_file
COUNTER=$?
echo "counter = $COUNTER"
if [ $COUNTER -eq "0" ]
then
    # Stop container
    echo "Stopping container"
    echo "------------------"
    kill 1
fi
