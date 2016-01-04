#!/bin/bash

# Synchronized incrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2015 Riken AICS. All rights reserved

version="0.42"

echo "$0 v$version"

if [ $# -lt 1 ]
then
    echo "Need file name to read from" >&2
    echo "Usage:" >&2
    echo "synchro_increment.sh filename" >&2
    exit 1
fi

# Open descriptor for reading
exec 20<$1

echo "+$PPID $(date +'%Y-%m-%d %H:%M:%S.%N') ($version)"

# Exclusively lock file
flock -x 20 || (echo "Cannot lock $1"; exit 1;)
COUNTER=$(cat $1);
if [ -z "$COUNTER" ]
then
    COUNTER=0
fi
echo $((COUNTER + 1)) >$1
# Unlock file
flock -u 20

echo "+$PPID $(date +'%Y-%m-%d %H:%M:%S.%N') COUNTER=$(cat $1) "
