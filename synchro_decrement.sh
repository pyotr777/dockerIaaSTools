#!/bin/bash

# Synchronized decrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.6.4"

echo "Decrement counter ($version) $1 $2"
if [ $# -lt 2 ]
then
    echo 'Need file names of counter and nostop files.' >&2
    echo "Usage:" >&2
    echo "synchro_increment.sh counter_filename nostop_filename" >&2
exit 1
fi

counter_file=$1
stop_file=$2
timeout=3

exec 20<>$1
flock -x -w 2 20
COUNTER=$(cat $1);
if [ -z $COUNTER ]
then
    COUNTER=1
fi
echo $(($COUNTER - 1)) > $1
flock -u 20
echo "COUNTER="$COUNTER

# Start dockerwatch.sh
echo "Starting dockerwatch"
dockerwatch="/dockerwatch.sh $counter_file $stop_file $timeout >>/dockerwatch.log 2>&1"
eval "$dockerwatch"

