#!/bin/bash

# Script for debugging create-ssh-tunnel.sh

port=2222
server=localhost
remoteuser=user

SSH_PARAMETERS="-A $server_port $remoteuser@$server"

# Create tunnel if necessary
command="create-ssh-tunnel.sh $remoteuser $server $port"
echo "command: $command"
# ! No quotes here:
source $command
echo "Received tunnel PID is $ssh_tunnel"
