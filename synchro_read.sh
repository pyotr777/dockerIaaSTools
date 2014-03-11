#!/bin/bash

#  Synchronized reading from file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.7.61"

if [ $# -lt 1 ]
then
    echo "Need file name to read from" >&2
    echo "Usage:" >&2
    echo "synchro_read.sh filename" >&2
    exit 1
fi

# Open file for reading
exec 20<$1
# Lock file in shared (read) lock
flock -s 20
VALUE=$(cat <&20)
echo $VALUE

# Unlock file
flock -u 20


