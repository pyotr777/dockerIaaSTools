#!/bin/bash

# Synchronized decrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="3.1.5"

echo "synchro_decrement $version"
servdir=$(servdir.sh)

log_file="/logs/container.log" # default log file

if [ $# -lt 2 ]
then
    echo 'Need file names of counter and nostop files.' >&2
    echo "Usage:" >&2
    echo "synchro_increment.sh counter_filename nostop_filename log_filename" >&2
    exit 1
fi

counter_file=$1
stop_file=$2

if [ $3 ]
	then
	log_file=$3
fi

# Open descriptor for reading
exec 20<$1

echo "-$PPID $(date +'%Y-%m-%d %H:%M:%S.%N') ($version)" >> $log_file

# Exclusively lock file
flock -x 20 || (echo "Cannot lock $1"; exit 1;)
COUNTER=$(cat $1);
if [ -z "$COUNTER" ]
then
    COUNTER=1
fi
echo $(($COUNTER - 1)) >$1
# Unlock file
flock -u 20
echo "-$PPID  $(date +'%Y-%m-%d %H:%M:%S.%N') COUNTER=$(cat $1)" >> $log_file #read from file

# Start dockerwatch.sh
echo "-$PPID Starting dockerwatch" >> $log_file
dockerwatch=( $servdir/dockerwatch.sh "$counter_file" "$stop_file")
eval "nohup ${dockerwatch[@]}" >> $log_file 2>&1 &
