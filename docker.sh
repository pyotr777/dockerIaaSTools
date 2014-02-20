#!/bin/bash
#
# Run commands inside user container.
# Start container if it's not running.
# Stop container (if started) when extra processes inside the container quit.
#
# Created by Bryzgalov Peter on 2014/02/19
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.11"

log_file="/docker.log"
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
echo "USR: $USER" >> $log_file
echo "CLT: $SSH_CLIENT" >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file

# Get user container name from table in file user_table_file
cont_name=$(grep $USER $user_table_file| awk '{ print $2 }')
# echo "User container: $cont_name" >> $log_file
# Get running containers names
# If user container name not in the list,
# start user container,
# get SSH port external number
ps=$(eval "$dockercommand ps" | grep $cont_name)
if [ "$ps" ]
then
    echo "Running containers: $ps" >> $log_file
fi

if [ -z "$ps" ]
then
    # Start container
    cont=$($dockercommand start $cont_name)
    echo "Start container $cont" >> $log_file
    sleep 1

    # get running container port number
    PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["22/tcp"]' | jq -r .[0].HostPort)
    sshcommand="ssh -p $PORT -A -o StrictHostKeyChecking=no root@localhost"
    echo "started container with open port $PORT" >> $log_file

    eval "$sshcommand"
fi

# get running container port number
if [ -z "$PORT" ]
then
    PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["22/tcp"]' | jq -r .[0].HostPort)
    sshcommand="ssh -p $PORT -A -o StrictHostKeyChecking=no root@localhost"
fi

echo "> $(date)" >> $log_file

# Execute commands in container
if [ "$SSH_ORIGINAL_COMMAND" ]
then
    commands="$SSH_ORIGINAL_COMMAND"
    echo "Execute: $commands" >> $log_file
else
    commands=""
fi
eval "$sshcommand \"$commands\"" 2>> $log_file

echo "<" $(date) >> $log_file
echo "-----------------------" >> $log_file
