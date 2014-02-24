#!/bin/bash
#
# Check connection counter
# If equal to 0, then stop container.
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.33"

# Connections counter
counter_file="/tmp/connection_counter"
if [ $1 ]
then
    counter_file=$1
fi
timeout=5

echo "Start dockerwatch $version watching $counter_file"
echo "$(date) sleep $timeout..."
echo "Started v.$version with counter $(cat $counter_file)" > /dockerwatch.log
sleep $timeout
echo "test" >> /dockerwatch.log
echo "counter: $(cat $counter_file)"
COUNTER=$(eval "/synchro_read.sh $counter_file")
echo "counter: $COUNTER"
if [ $COUNTER -le "0" ]
then
    # Stop container
    echo "Stopping container"
    echo "------------------"
    kill 1
fi
