#!/bin/bash

#  Synchronized reading from file
#
# Created by Bryzgalov Peter on 2014/02/19
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.20"

if [ $# -lt 1 ]
then
    echo 'Need file name to read from' >&2
    echo "Usage:" >&2
    echo "synchro_read.sh filename" >&2
    exit 1
fi

echo "Read value from $1"
exec 20>$1
flock -x -w 2 20
VALUE=$(cat $1)
flock -u 20
echo $VALUE
