#!/bin/bash
#
# Start container if it's not running.
# Run commands inside user container.
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2014 RIKEN AICS.
#
# Special commands (SSH_ORIGINAL_COMMAND):
# commit - commit container
# remove - remove continaer


version="3.2.25"

log_file="/docker.log"

# mount table file lists folders, that should be mount on container startup (docker run command)
# file format:
# username@mountcommand1;mountcommand2;...
# mountcommand format: 
# [host-dir]:[container-dir]:[rw|ro]
mount_file="/var/mounttable.txt"

# Verbose logs for debugging
debuglog=1
dockercommand="docker -H localhost:4243"
user_table_file="/var/usertable.txt"

# 1 if we started container
container_started=0

# FUNCTIONS

# Return host-side port number mapped to the port 
getPort() {
	cont_port=""
	if [ -z $1 ]
	then
		cont_port="22/tcp"
	else 
		cont_port=$1
	fi

	PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["'"$1"'"]' | jq -r .[0].HostPort)
	if [ $debuglog -eq 1 ]
	then
		echo "Port mapping $cont_port->$PORT" >> $log_file
	fi
	echo $PORT
}

# Read from mount_file, search for username@... line,
# return part of Docker run command for mounting volumes
# like this: "-v hostdir:contdir -v hostdir:contdir:ro"

getMounts() {
    mount_command=""
    mounts=$(grep $1 $mount_file | awk -F"@" '{ print $2 }')  
    if [ -z "$mounts" ]
    then 
        echo ""
        exit 0
    fi      
    IFS=';' read -ra mounts_arr <<< "$mounts"
    for mnt in "${mounts_arr[@]}"
    do
        mount_command="$mount_command-v=$mnt "
    done                   
    echo $mount_command
}


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

if [ "$SSH_ORIGINAL_COMMAND" = port ]
    then 
    if [ $debuglog -eq 1 ]
    then
        echo "Return container $cont_name ssh port number" >> $log_file
    fi 
    PORT=$(getPort "22/tcp")
    echo $PORT
    exit 0
fi



# Get running containers names
# If user container name not in the list,
# start user container,
# get SSH port external number
ps=$(eval "$dockercommand ps" | grep "$cont_name ")
if [ "$ps" ] && [ $debuglog -eq 1 ]
then
    echo "Container is running" >> $log_file
fi


if [ -z "$ps" ]
then
    psa=$(eval "$dockercommand ps -a" | grep "$cont_name ")
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
        mounts=$(getMounts $USER)
		# Permissions to mount with sshfs inside container
		moptions=""
		if [ "permit_mounts" ]
		then
		    moptions=" --cap-add SYS_ADMIN --device /dev/fuse"
	    fi
        options="run -d --name $cont_name $mounts $moptions -P $image"
        cont=$($dockercommand $options)
        if [ $debuglog -eq 1 ]
            then
            echo "Start container $cont with command: $options" >> $log_file
        fi
        container_started=1
        sleep 1
    fi
    
    #   get running container port number
    PORT=$(getPort "22/tcp")
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
    echo "started container with open port $PORT" >> $log_file    
fi



# get running container port number
if [ -z "$PORT" ]
then	
    PORT=$(getPort "22/tcp")
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
fi

echo "> $(date)" >> $log_file

# Execute commands in container
# -----------------------------

# Set environment variables in container

if [ $container_started -eq 1 ]
	then
	# SSH external port number
	command1='echo . /root/.getport >> /root/.bashrc'
	command2='echo export SSH_PORT='"$PORT"' > /root/.getport'
	commands=( "${sshcommand[@]}" "$command1; $command2" )
	if [ $debuglog -eq 1 ]
	then
		echo "setting environment variables" >> $log_file
	    echo "${commands[@]}" >> $log_file
	fi
	"${commands[@]}"
fi

commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
if [ $debuglog -eq 1 ]
then
    echo "${commands[@]}" >> $log_file
fi
"${commands[@]}"
# -----------------------------

echo "<" $(date) >> $log_file
echo " " >> $log_file
