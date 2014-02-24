#!/bin/bash

# Call to prevent stopping user container
# Write "stopdockerwatch" to sacred_proc_file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.52"

stop_file="/tmp/nostop"

echo "Stop $version"
exec 20<>$stop_file
flock -x -w 2 20
echo "0" > $stop_file
flock -u 20
echo "Exit nostop state"