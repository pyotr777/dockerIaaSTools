#!/bin/bash

# Synchronized decrementation of a value in file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.32"

if [ $# -lt 1 ]
then
    echo 'Need file name to read from' >&2
    echo "Usage:" >&2
    echo "synchro_increment.sh filename" >&2
exit 1
fi

echo "Decrement counter ($version) $(cat $1)"
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