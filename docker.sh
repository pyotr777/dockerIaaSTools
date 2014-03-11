#!/bin/bash
#
# Start container if it's not running.
# Run commands inside user container.
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 Riken AICS. All rights reserved.

version="2.7.6"

log_file="/docker.log"
# Verbose logs for debugging
debuglog=0
dockercommand="docker -H localhost:4243"
user_table_file="/var/usertable.txt"

if [ ! -w $log_file ];
then
    touch $log_file
fi
if [ ! -f $user_table_file ];
then
    echo "Cannot find file $user_table_file" >> $log_file
    exit 1;
fi

echo "docker.sh $version" >> $log_file
echo "----- start -----" >> $log_file
date >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file
if [ $debuglog -eq 1 ]
then
    echo "USR: $USER" >> $log_file
    echo "CON: $SSH_CONNECTION" >> $log_file
fi

# Get user container name from table in file user_table_file
cont_name=$(grep -E "^$USER " $user_table_file| awk '{ print $2 }')
if [ $debuglog -eq 1 ]
then
    echo "User container: $cont_name" >> $log_file
fi
# Get running containers names
# If user container name not in the list,
# start user container,
# get SSH port external number
ps=$(eval "$dockercommand ps" | grep $cont_name)
if [ "$ps" ] && [ $debuglog -eq 1 ]
then
    echo "Container is running" >> $log_file
fi

if [ -z "$ps" ]
then
#   Start container
    cont=$($dockercommand start $cont_name)
    echo "Start container $cont" >> $log_file
    sleep 1
#   get running container port number
    PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["22/tcp"]' | jq -r .[0].HostPort)
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
    echo "started container with open port $PORT" >> $log_file
fi

# get running container port number
if [ -z "$PORT" ]
then
    PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["22/tcp"]' | jq -r .[0].HostPort)
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
fi

echo "> $(date)" >> $log_file

# Execute commands in container
# -----------------------------
commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
if [ $debuglog -eq 1 ]
then
    echo "$commands" >> $log_file
fi
"${commands[@]}"
# -----------------------------

echo "<" $(date) >> $log_file
echo " " >> $log_file
