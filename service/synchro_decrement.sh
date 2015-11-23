#!/bin/bash

# Synchronized decrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2015 Riken AICS. All rights reserved

version="0.40a02"

echo "$0 v$version"

# This will be replaced by createuset.sh
initvariables

if [ $# -lt 2 ]
then
    echo 'Need file names of counter and nostop files.' >&2
    echo "Usage:" >&2
    echo "synchro_decrement.sh counter_filename nostop_filename log_filename" >&2
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
dockerwatch=($servdir/dockerwatch.sh "$counter_file" "$stop_file")
echo "-$PPID starting: ${dockerwatch[@]}" >> $log_file
eval "nohup ${dockerwatch[@]}" >> $log_file 2>&1 &
echo "-$PPID quit."
