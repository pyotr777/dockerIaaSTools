#!/bin/bash
#
# Start container if it's not running.
# Run commands inside user container.
#
# Special commands (SSH_ORIGINAL_COMMAND):
# commit - commit container
# remove - remove continaer
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2015 RIKEN AICS.

version="0.40a02"

# Will be substituted with path to cofig file during installation
source diaasconfig

# mount table file lists folders, that should be mount on container startup (docker run command)
# file format:
# username@mountcommand1;mountcommand2;...
# mountcommand format: 
# [host-dir]:[container-dir]:[rw|ro]

# Verbose logs for debugging
debuglog=1

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
		echo "Port mapping $cont_port->$PORT" >> $forcecommandlog
	fi
	echo $PORT
}

# Print free port number.
# Loops through the port range and returns first port number that is not used.
getFreePort() {
	# Port range. Use dynamic port numbers.
	startport=49152
	endport=65535

	# Which netstat?
	test=$(netstat -V 2>/dev/null)

	if [[ $test == *"net-tools"* ]]
	then    
		# Array of used port numbers
		used=( $(netstat -n -t | grep : | awk '{ print $4 }' |  awk -F ':' '{ print $2 }') )
	else 
		used4=( $(netstat -n -p tcp | grep "tcp4" | awk '{ print $4 }' |  awk -F '.' '{ print $5 }') )
		used6=( $(netstat -n -p tcp | grep "tcp6" | awk '{ print $4 }' |  awk -F '.' '{ print $2 }') )
		used=( "${used4[@]}" "${used6[@]}" )
	fi

	for port in $(seq $startport $endport)
	do
		isused="false"
		for uport in "${used[@]}"
		do
			if [ "$port" == "$uport" ]
			then 
				isused="true"
				break
			fi
		done
		if [ "$isused" == "false" ]
		then
			echo "$port"
			break           
		fi
	done
}


# Read from mountfile, search for username@... line,
# return part of Docker run command for mounting volumes
# like this: "-v hostdir:contdir -v hostdir:contdir:ro"
getMounts() {
	mount_command=""
	mounts=$(grep $1 $mountfile | awk -F"@" '{ print $2 }')  
	if [ -z "$mounts" ]; then 
		echo ""
		exit 0
	fi      
	IFS=';' read -ra mounts_arr <<< "$mounts"
	for mnt in "${mounts_arr[@]}"; do
		mount_command="$mount_command-v=$mnt "
	done                   
	echo $mount_command
}


if [ ! -w $forcecommandlog ];then
	touch $forcecommandlog
fi

if [ ! -f $usersfile ];then
	echo "Cannot find file $usersfile" >> $forcecommandlog
	exit 1;
fi

# Start socat if docker is not accessible with dockercommand
error=$( { $dockercommand ps > /dev/null; } 2>&1 )
if [[ -n "$error" ]]; then
	${install_path}/socat-start.sh >> $forcecommandlog
fi

echo "$0 $version" >> $forcecommandlog
echo "----- start -----" >> $forcecommandlog
date >> $forcecommandlog
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $forcecommandlog
if [ $debuglog -eq 1 ]; then
	echo "USR: $USER" >> $forcecommandlog
	echo "CON: $SSH_CONNECTION" >> $forcecommandlog
fi

# Get user container name from table in file usersfile
cont_name=$(grep -E "^$USER " $usersfile| awk '{ print $2 }')
if [ -z "$cont_name" ]; then
	echo "No user $USER registered here." >&2
	exit 1
fi

image="localhost/$USER"

if [ $debuglog -eq 1 ]; then
	echo "User container: $cont_name, Image: $image" >> $forcecommandlog
fi

# Check SSH_ORIGINAL_COMMAND
if [ "$SSH_ORIGINAL_COMMAND" = commit ]; then 
	if [ $debuglog -eq 1 ]; then
		echo "Commit container $cont_name" >> $forcecommandlog
	fi    
	command="$dockercommand commit $cont_name $image"
	$command
	exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = stop ]; then
	if [ $debuglog -eq 1 ]; then
		echo "Stop container $cont_name" >> $forcecommandlog
	fi 
	command="$dockercommand kill $cont_name"
	$command
	exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = remove ]; then
	if [ $debuglog -eq 1 ]; then
		echo "Remove container $cont_name" >> $forcecommandlog
	fi 
	command="$dockercommand rm $cont_name"
	$command
	exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = port ]; then
	if [ $debuglog -eq 1 ]; then
		echo "Return container $cont_name ssh port number" >> $forcecommandlog
	fi 
	PORT=$(getPort "22/tcp")
	echo $PORT
	exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = freeport ]; then
	if [ $debuglog -eq 1 ]; then
		echo "Return free server port number" >> $forcecommandlog
	fi 
	PORT=$(getFreePort)
	echo $PORT
	exit 0
fi

# Action (command) on container
# empty string -- container is running, no actions performed
# start -- container has been stopped and was started
# run -- there were no container and a new container was created
container_action=""

# Get running containers names
# If user container name not in the list,
# start user container,
# get SSH port external number
ps=$(eval "$dockercommand ps" | grep "$cont_name ")
if [ "$ps" ] && [ $debuglog -eq 1 ]
then
	echo "Container is running" >> $forcecommandlog
fi


if [ -z "$ps" ]
then
	psa=$(eval "$dockercommand ps -a" | grep "$cont_name ")
	if [ "$psa" ] 
	then
		if [ $debuglog -eq 1 ]
			then
			echo "Container is stopped" >> $forcecommandlog
		fi
		#   Start container
		cont=$($dockercommand start $cont_name)
		if [ $debuglog -eq 1 ]
			then
			echo "Start container $cont" >> $forcecommandlog
		fi
		container_action="start"
		sleep 1
	else 
		if [ $debuglog -eq 1 ]; then
			echo "No container. Run from image." >> $forcecommandlog
		fi

		# Run container
		mounts=$(getMounts $USER)
		# Permissions to mount with sshfs inside container
		moptions=""
		if [ "permit_mounts" ]
		then
			moptions=" --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined"
		fi
		options="run -d --name $cont_name $mounts $moptions -P=true $image"
		cont=$($dockercommand $options)
		if [ $debuglog -eq 1 ]
			then
			echo "Start container $cont with command: $options" >> $forcecommandlog
		fi
		container_action="run"
		sleep 1
	fi
	
	#   get running container port number
	PORT=$(getPort "22/tcp")
	sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
	echo "started container with open port $PORT" >> $forcecommandlog    
fi



# get running container port number
if [ -z "$PORT" ]
then	
	PORT=$(getPort "22/tcp")
	sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
fi

echo "> $(date)" >> $forcecommandlog

# Execute commands in container
# -----------------------------

# SCP
if [[ "$SSH_ORIGINAL_COMMAND" =~ ^scp\ [-a-zA-Z0-9\ \.]* ]]
	then 
	tmpfile="$HOME/scp.log"
	echo "SCP detected  at $(pwd)" >> $forcecommandlog
	
	# This works
	socat -v - SYSTEM:"scp -t /dev/null",reuseaddr 2> $tmpfile
	commands=( $dockercommand cp "$tmpfile" "$cont_name:/root" )
	echo "Command: $commands" >> $forcecommandlog
elif [[ -n "$SSH_ORIGINAL_COMMAND" ]]; then
	commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
else
	# Interactive login	
	sshcommand=( ssh -p "$PORT" -Y -A -o StrictHostKeyChecking=no root@localhost )
	commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
fi
if [ $debuglog -eq 1 ]
then
	echo "${commands[@]}" >> $forcecommandlog
fi
"${commands[@]}"
# -----------------------------

echo "<" $(date) >> $forcecommandlog
echo " " >> $forcecommandlog
