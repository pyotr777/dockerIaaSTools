#!/bin/bash

# Synchronized incrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.7.83"

echo "+Increment counter ($version) $(date +'%Y-%m-%dT %H:%M:%S.%N') $1"

if [ $# -lt 1 ]
then
    echo "Need file name to read from" >&2
    echo "Usage:" >&2
    echo "synchro_increment.sh filename" >&2
    exit 1
fi

# Open file for reading and writing
exec 20<>$1
# Exclusively lock file
flock -x -w 5 20 || (echo "Cannot lock $1"; exit 1;)
COUNTER=$(cat <&20);
if [ -z $COUNTER ]
then
    COUNTER=0
fi
echo $((COUNTER + 1)) > $1
echo "+COUNTER=$(cat <&20)"
# Unlock file
flock -u 20
