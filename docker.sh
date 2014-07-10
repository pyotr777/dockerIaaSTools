#!/bin/bash
#
# Start container if it's not running.
# Run commands inside user container.
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 RIKEN AICS.
#
# If SSH_ORIGINAL_COMMAND:
# commit - commit container
# remove - remove continaer



version="3.1.4"

log_file="/docker.log"
# Verbose logs for debugging
debuglog=1
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
if [ -z "$cont_name" ] 
then
    echo "No user $USER registered here." >&2
    exit 1
fi

image="localhost/$USER"

if [ $debuglog -eq 1 ]
then
    echo "User container: $cont_name, Image: $image" >> $log_file
fi

# Check SSH_ORIGINAL_COMMAND

if [ "$SSH_ORIGINAL_COMMAND" = commit ]
    then 
    if [ $debuglog -eq 1 ]
    then
        echo "Commit container $cont_name" >> $log_file
    fi    
    command="$dockercommand commit $cont_name $image"
    $command
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = stop ]
    then 
    if [ $debuglog -eq 1 ]
    then
        echo "Stop container $cont_name" >> $log_file
    fi 
    command="$dockercommand kill $cont_name"
    $command
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = remove ]
    then 
    if [ $debuglog -eq 1 ]
    then
        echo "Remove container $cont_name" >> $log_file
    fi 
    command="$dockercommand rm $cont_name"
    $command
    exit 0
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
    psa=$(eval "$dockercommand ps -a" | grep $cont_name)
    if [ "$psa" ] 
    then
        if [ $debuglog -eq 1 ]
            then
            echo "Container is stopped" >> $log_file
        fi
        #   Start container
        cont=$($dockercommand start $cont_name)
        if [ $debuglog -eq 1 ]
            then
            echo "Start container $cont" >> $log_file
        fi
        sleep 1
    else 
        if [ $debuglog -eq 1 ]
            then
            echo "No container. Run from image." >> $log_file
        fi
        # Run container
        cont=$($dockercommand run -d --name $cont_name -P $image)
        if [ $debuglog -eq 1 ]
            then
            echo "Start container $cont from $image" >> $log_file
        fi
        sleep 1
    fi

    
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
    echo "${commands[@]}" >> $log_file
fi
"${commands[@]}"
# -----------------------------

echo "<" $(date) >> $log_file
echo " " >> $log_file
