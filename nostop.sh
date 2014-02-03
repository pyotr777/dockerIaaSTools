#!/bin/sh

# Call to prevent stopping user container
# Write "stopdockerwatch" to sacred_proc_file
#
# Created by Bryzgalov Peter on 2014/01/31
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="1.46"

sacred_proc_file="/tmp/proc.tmp"
stop_dockerwatch="stopdockerwatch"

echo $version
echo "Container will not be stopped by dockerwatch."
echo $stop_dockerwatch > $sacred_proc_file