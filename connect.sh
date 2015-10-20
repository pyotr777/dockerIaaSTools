#!/bin/bash

# Mount local folder into container on a server.
# To be executed on user local computer.
# Parameters:
#  remote user
#  server address
#  local path to mount inside container
#  path to ssh-key (optional)
#  commands to be executed in container (optional)
#
# Requires:
#	tar
#	sshd running on port 22 on local computer
#	ssh-agent
#
# Created by Bryzgalov Peter
# Copyright (c) 2015 RIKEN AICS. All rights reserved

version="0.34a01"
debug=""

usage="Usage:\nconnect.sh -u <username> -h <server address> -p <server port number> \
-l <local directory to mount> -i <path to ssh-key> \
-a <add to PATH> -m <remote command>"

remote_port=0
local_user=$USER
hostIP="172.17.42.1"  # server IP as seen from inside containers


# Defauts
remote_commands=""
add_path="/opt/omnixmp/bin"

echo "$0 v$version"
if [ -n "$debug" ]; then 
	echo "Called with parameters: $@."
fi

# Trim quotes around a string
trimQuotes() {
	v=$1
	val=$(echo $v | sed 's/^\"//' | sed 's/\"$//')
	echo "$val"
}

# Copy file with bash script into container
# and execute it in container.
# Paramter: script file name.
# Uses variables: $SSH_PARAMETERS and $debug.
copyRCfileAndExecute() {
	if [ -n "$debug" ]; then
		echo "Called copyRCfileAndExecute with parameter: $1"
		echo "ssh_parameters=$SSH_PARAMETERS"
		echo "debug=$debug"	
	fi
	cmd_file=$1
	if [ -n "$debug" ]; then
		echo "Command file:"
		eval "cat $cmd_file"
		echo "....."
	fi
	cp_command="tar -cf - $cmd_file | ssh $SSH_PARAMETERS \"tar -xf - -C /\""
	if [ -n "$debug" ]; then
		echo "Copying RC file:"
		echo $cp_command
	fi
	eval "$cp_command"	
	command="ssh $SSH_PARAMETERS \"chmod +x /$cmd_file\""
	if [ -n "$debug" ]; then
		echo "Executing chmod command: $command"
	fi
	eval "$command" # 2>&1 | grep -i "error"
	command="ssh $SSH_PARAMETERS '/$cmd_file'"
	if [ -n "$debug" ]; then
		echo "Executing RC command: $command"
	fi
	eval "$command 2>&1" # | grep -i "error"
}

while getopts "u:h:l:i:k:m:a:p:" opt; do
	case $opt in
	u)
		remoteuser=$(trimQuotes "$OPTARG")
		;;
	h)
		server=$(trimQuotes "$OPTARG")
		;;
	l)
		path=$(trimQuotes "$OPTARG")
		;;
	m)
		remote_commands=$(trimQuotes "$OPTARG")
		;;
	k)
		ssh_key=$(trimQuotes "$OPTARG")
		;;
	i)
		ssh_key=$(trimQuotes "$OPTARG")
		;;
	a)
		add_path=$(trimQuotes "$OPTARG")
		;;
	p)
		server_port="-p $(trimQuotes $OPTARG)"
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		echo -e "$usage"
		exit 1
		;;
	esac
done

if [ -z "$path" ]
	then
	path=$(pwd)
	echo "Use current folder: $path"
fi

# Check that necessary arguments provided

if [ -z "$remoteuser" ]
	then
	echo "Need user name."
	echo -e "$usage"
	exit 1
fi

if [ -z "$server" ]
	then
	echo "Need server address."
	echo -e "$usage"
	exit 1
fi

if [ -n "$ssh_key" ]; then
	key_in_ssh_add=$(ssh-add -l | grep $ssh_key | wc -l)
	if [ $key_in_ssh_add -le 0 ]; then
		echo "Add SSH_KEY $ssh_key to agent."
		ssh-add $ssh_key
		ssh_key_added=1
	fi
	keyoption="-i $ssh_key"
fi

SSH_PARAMETERS="-A $server_port -q $remoteuser@$server"

free_port="$(ssh $SSH_PARAMETERS freeport 2>/dev/null)"

echo "SSH server port: $free_port"

command="ssh $SSH_PARAMETERS -R 0.0.0.0:$free_port:localhost:22 -N"
if [ -n "$debug" ]; then
	echo "tunnel command: $command"
fi
$command & 
ssh_tunnel=$!
echo "tunnel PID=$ssh_tunnel"

# File for remote commands
cmd_file="rcom.sh"
# ssh
if [ -z "$remote_commands" ]
then  # No commands -- interactive shell login
	read -rd ''  setup_commands <<- RCOM
	mkdir -p "$path"
	sshfs -o StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null,nonempty -p $free_port "$local_user@$hostIP:$path" "$path"
	cd "$path"
	echo "v\$version"
	echo "mounted $path with $(ls -l | wc -l) files."
	export PATH="\$PATH:$add_path"
RCOM
	# Save remote commands to a file. Execute it in container.
	if [ -n "$debug" ]; then
		echo "Save remote commands to a file. Execute it in container."
		echo "#!/bin/bash -x" > $cmd_file
	else 
		echo "#!/bin/bash" > $cmd_file
	fi
	echo "version=$version" >> $cmd_file
	printf "%s\n" "$setup_commands" >> $cmd_file
	copyRCfileAndExecute "$cmd_file"
	command="ssh -Y -o StrictHostKeyChecking=no $SSH_PARAMETERS"
	if [ -n "$debug" ]; then
		echo "Executing interactive login:"
		echo $command
	fi
	$command 
else 
	# Execute remote commands. No interactive shell login.
	# testcommand ="ssh -vv -p $free_port $local_user@$hostIP;echo "'$HOST'";exit;\n"
	read -rd '' setup_commands <<- RCOM2
	mkdir -p "$path"
	sshfs -o StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null,nonempty -p $free_port "$local_user@$hostIP:$path" "$path"
	cd "$path"
	echo "v\$version"
	echo "mounted $path with $(ls -l | wc -l) files."
	export PATH="\$PATH:$add_path"
RCOM2
	setup_commands="$setup_commands\n$remote_commands"
	echo -e $setup_commands

	# Save remote commands to a file. Execute it in container.
	
	echo "#!/bin/bash" > $cmd_file
	echo "version=$version" >> $cmd_file
	echo -e $setup_commands >> $cmd_file
	
	if [ -n "$debug" ]; then
		echo "Command file:"
		cat $cmd_file
		echo "---"
	fi
	# Copy command file into container using container SSH port number as seen from server-side.
	copyRCfileAndExecute "$cmd_file"
fi

# Stop container if it was started or unmount local folder
if [ -n "$container_started" ]
then
	ssh $SSH_PARAMETERS "nodaemon" 2>/dev/null
	echo "Container will stop now"
else
	# Unmount SSHFS mount
	echo "Unmount SSHFS"
	ssh $SSH_PARAMETERS "umount \"$path\"" 2>/dev/null
fi
kill "$ssh_tunnel"
if [ $ssh_key_added ] 
	then
	echo "Remove SSH_KEY $ssh_key from agent."
	ssh-add -d $ssh_key
fi

# Remove file with commands
rm $cmd_file
