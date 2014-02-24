#!/bin/bash

#  Synchronized reading from file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.55"

if [ $# -lt 1 ]
then
    echo 'Need file name to read from' >&2
    echo "Usage:" >&2
    echo "synchro_read.sh filename" >&2
    exit 1
fi

exec 20<$1
flock -x -w 2 20
VALUE=$(cat $1)
flock -u 20
echo $VALUE

