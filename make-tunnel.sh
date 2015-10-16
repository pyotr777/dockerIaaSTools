#!/bin/bash

# Creates SSH tunnel.
# Parameters:
# server user, server address, server port

debug="1"

read -rd '' usage << EOF
Usage:
$0 <server user name> <server address> <server ssh port>
EOF

if [ "$#" -lt 3 ]; then
	echo -e "$usage"
	exit 1
fi

server_port=$1
server=$2
user=$3

SSH_PARAMETERS="-A $server_port $remoteuser@$server"
#container_port=$(ssh $SSH_PARAMETERS port 2>/dev/null)

#if [ $container_port="null" ]; then
#	if [ $debug ]; then
#		echo "Starting container in daemon mode ($SSH_PARAMETERS)"
#	fi
#	ssh $SSH_PARAMETERS "daemon" 2>/dev/null
#	container_started="true"
#	container_port=$(ssh $SSH_PARAMETERS port 2>/dev/null)
#	if [ -z $container_port ]
#		then
#		echo "Could not reach container. Check the address, user name, connection, ..."
#		exit 1
#	fi
#fi
#
#
#free_port=$(ssh $SSH_PARAMETERS freeport 2>/dev/null)
#
#echo "SSH server port: $free_port, container port:$container_port"
#
#command="ssh $SSH_PARAMETERS -R $free_port:localhost:22 -N"
#if [ $debug ]; then 
#	echo $command
#fi
#$command & 
#ssh_tunnel=$!
ssh_tunnel=3456
echo "tunnel PID=$ssh_tunnel"
