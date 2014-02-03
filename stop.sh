#!/bin/sh

# Stop user container after SSH session finishes.
# Start dockerwatch, sacred process is "sshd: root@"
#  
# Created by Bryzgalov Peter on 2014/01/31
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="1.46"

sacred_proc="sshd: root@"
sacred_proc_file="/tmp/proc.tmp"

echo $version
echo "After you quit SSH session container will be stopped"
echo $sacred_proc > $sacred_proc_file

# Start dockerwatch
commands="/dockerwatch.sh > /dockerwatch.log &"
echo "Starting dockerwatch: $commands"
eval "$commands"