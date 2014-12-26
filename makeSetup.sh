#!/bin/bash

# Mount local folder into container on a server.
# To be executed on user local computer.
# Parameters:
#  remote user
#  server address
#  server port number (must be free)
#  path to directory to mount
#
# Ex.:
# makeSetup.sh user@server:port /path
#
# Copyright © 2014 Peter Bryzgalov Japan, Riken, AICS

usage="Usage:\nmakeSetup.sh <username>@<server address>:<server port> <path to mount>"

# Split string by delimiter
# First parameter - string
# Second parameter - delimiter
# Third parameter - number of element to return (first element number is 0)
splitString() {
	#echo "argument 1: $1"
	if [ -z $1 ]
	then
		exit 1
	fi
	
	dlm=":"
	if [ $2 ]
	then
		dlm=$2
	fi

	part="1"
	if [ $3 ]
	then
		part=$3
	fi

	# echo -e "$1\n$dlm\n$part"
	rIFS=IFS
	IFS=$dlm
	arr=($1)
	# echo -e "Array: ${arr[@]}. Need element $part: ${arr[$part]}"
	IFS=$rIFS
	val=${arr[$part]}

	echo $val
}

remote_port=2225
local_user=$USER

if [ -z $1 ]
then
	echo -e "$usage"
	exit 1
fi

if [ -z $2 ]
then
	echo -e "$usage"
	exit 1
fi

# Parse first argument

remoteuser=$(splitString $1 @ 0)

if [ -z "$remoteuser" ]
then
	echo "Error in argument $1"
	echo -e "$usage"
	exit 1
fi

addr_port=$(splitString $1 @ 1)

if [ -z "$addr_port" ]
then
	echo "Error in argument $1"
	echo -e "$usage"
	exit 1
fi

server=$(splitString $addr_port : 0)
port=$(splitString $addr_port : 1)

# Second argument is path

path=$2

container_port=$(ssh $remoteuser@$server port)
echo "SSH port of container=$container_port"

# 1
command="ssh -f $remoteuser@$server -R $port:localhost:22 -N"
echo $command
#$command &
#echo $$
#echo $!
#ssh_tunnel=$!
#echo "tunnel PID=$ssh_tunnel"

# ssh
remote_commands="mkdir -p $path\nsshfs -p $port $local_user@172.17.42.1:$path $path\ncd $path\necho \"ver \$version\";pwd;ls -l;export PATH=$PATH:/opt/omnixmp/bin;make"

cmd_file="rcom.sh"
echo "#!/bin/bash" > $cmd_file
echo "version=0.1" >> $cmd_file
echo -e $remote_commands >> $cmd_file
chmod +x $cmd_file
cp_command="scp -P $container_port $cmd_file root@$server:/"
echo $cp_command
$cp_command
command="ssh -A $remoteuser@$server '/$cmd_file'"
echo $command
$command
rm $cmd_file



