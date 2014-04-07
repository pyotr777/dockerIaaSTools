#!/bin/bash

# Call to prevent stopping user container
# Write "stopdockerwatch" to sacred_proc_file
#
# Created by Bryzgalov Peter
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.6.5"

stop_file="/tmp/dockeriaas_nostop"

echo "Nostop $version"
exec 20<>$stop_file
flock -x -w 2 20
echo "1" > $stop_file
flock -u 20
echo "Enter nostop state"