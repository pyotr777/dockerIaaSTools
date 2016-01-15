#!/bin/bash

# Synchronized decrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2016 Riken AICS. All rights reserved

version="0.45b"

echo "$0 v$version"

# This will be replaced by createuset.sh
initvariables

log_file=${basename}.log

if [ $1 ]; then
	counter_file=$1
fi
if [ $2 ]; then
	stop_file=$2
fi
if [ $3 ]; then
	log_file=$3
fi
echo "[$counter_file $stop_file $log_file]" >> $log_file

# Open descriptor for reading
exec 20<$counter_file

echo "-$PPID $(date +'%Y-%m-%d %H:%M:%S.%N') ($version)" >> $log_file

# Exclusively lock file
flock -x 20 || (echo "Cannot lock $counter_file"; exit 1;)
COUNTER=$(cat $counter_file);
if [ -z "$COUNTER" ]
then
    COUNTER=1
fi
echo $(($COUNTER - 1)) >$counter_file
# Unlock file
flock -u 20
echo "-$PPID $(date +'%Y-%m-%d %H:%M:%S.%N') COUNTER=$(cat $counter_file)" >> $log_file #read from file

# Start dockerwatch.sh
dockerwatch="$servdir/dockerwatch.sh"
echo "-$PPID starting: $dockerwatch" >>$log_file
$dockerwatch >>$log_file 2>>$log_file
echo "-$PPID quit."
