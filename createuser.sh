#!/bin/bash

#  Creates user with designated key, creates Docker container with user name.
#  Makes set up for automatic user login to the container
#  with SSH and agent forwarding.
#
#  Parameters:
#  user name,
#  file with public SSH key,
#  Docker image name to use for container.
#
#  User and container names are stored in user tabel file (/usertable.txt).
#
#  Use cleanuser.sh with user name for removing user from server,
#  removing user record from tabel file and removing user container.
#
#  Requires:
#  sshpass
#  jq
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2014 RIKEN AICS. All rights reserved

version="2.7.1"
echo "createuser.sh $version"

# Initialization
if [ $# -lt 1 ]
then
    echo 'Creates user with designated SSH key, creates Docker container with user name.\nMakes set up for automatic user login to the container\nwith SSH and agent forwarding.\n\n  Parameters:\n  user name,\n  file with public SSH key,\n  Docker image name to use for container (optional, default = peter/ssh).'
    exit 0
fi

username=$1
public_key_file=$2
image=$3
user_table_file="/var/usertable.txt"
container_connections_counter="/tmp/dockeriaas_cc"

userExists() {
    awk -F":" '{ print $1 }' /etc/passwd | grep -x $1 > /dev/null
    return $?
}

if [ "$username" = "dockertest" ]
then
    echo "Name dockertest is reserved. Try different user name."
    exit 1
fi

userExists $username
if [ $? = 0 ]
then
    echo "User $username already exists. Try different name."
    exit 1
fi

if [ ! -f $public_key_file ]
then
    echo "Public key file $public_key_file not found."
    exit 1
fi

# Register user and conatiner names in user table file
echo "$username $username" >> $user_table_file

# Create container with SSH service runnning
cont=$(docker run -d -name $username -p 22 $image /usr/sbin/sshd -D)
echo "Container: $cont"
if [ -z "$cont" ]
then
    echo "ERROR: Could not create container."
    exit 1
fi

port=$(docker inspect $cont | jq .[0].NetworkSettings.Ports | jq '.["22/tcp"]' | jq -r .[0].HostPort)

ssh="sshpass -p \"docker\" ssh -o StrictHostKeyChecking=no -p $port root@localhost"

echo "Contacting container with $ssh"
# test SSH
ssherr=$(eval "$ssh ls" 2>&1 > /dev/null)
# if have another key in known_hosts, clean out
if [[ "$ssherr" == *WARNING* ]]
then
    clean_command="ssh-keygen -f \"/root/.ssh/known_hosts\" -R [localhost]:$port"
    echo "Clean known_hosts: $clean_command"
    eval $clean_command
fi

echo "Creating user $username with public key in $public_key_file"

if [ -z $3 ]
then
    image="peter/ssh"
else
    image=$3
fi
echo "Using image $image"

# Create user
userExists $username
if [ ! $? = 0 ]
then
    useradd -m $username
    echo "User $username created on server"
fi
if [ ! -d "/home/$username/.ssh" ]
then
    mkdir -p /home/$username/.ssh
fi
cat $public_key_file > /home/$username/.ssh/authorized_keys
chown -R $username:$username /home/$username/

usermod -a -G dockertest $username
usermod -a -G ssh $username


eval "$ssh 'locale-gen en_US.UTF-8'"
# Put necessary files into container
eval "$ssh 'mkdir ~/.ssh'"
# Copy public key to the container
pub_key=`cat $public_key_file`
eval "$ssh 'echo $pub_key >> ~/.ssh/authorized_keys'"

# Connections counter
eval "$ssh \"echo 0 > $container_connections_counter\""

# Copy service files
echo "copying files into container"
sshpass -p "docker" scp -P $port dockerwatch.sh root@localhost:/
sshpass -p "docker" scp -P $port container.sh root@localhost:/
sshpass -p "docker" scp -P $port stop.sh root@localhost:/
sshpass -p "docker" scp -P $port stopnow.sh root@localhost:/
sshpass -p "docker" scp -P $port nostop.sh root@localhost:/
sshpass -p "docker" scp -P $port synchro_decrement.sh root@localhost:/
sshpass -p "docker" scp -P $port synchro_increment.sh root@localhost:/
sshpass -p "docker" scp -P $port synchro_read.sh root@localhost:/
eval "$ssh 'mkdir /logs'"
eval "$ssh 'ls -l /'"


# Disable password login
#eval "$ssh 'sed -r -i \"s/^.*PasswordAuthentication[yesno ]+$/PasswordAuthentication no/\" /etc/ssh/sshd_config'"

# Set ForceCommand to run container.sh
eval "$ssh 'printf \"\nForceCommand /container.sh\" >> /etc/ssh/sshd_config'"

docker kill $username
echo "Created continer $username ($cont)"
echo "Finished."

# Check TCP connection to Docker remote API
# Required for automatic login to container
dockercommand="docker -H localhost:4243"
test=$($dockercommand ps)
if [ -z "$test" ]
then
    echo "ERROR: Cannot connect to Docker API on port 4243"
    echo "Try executing commands (socid will have process number):"
    echo "socat TCP-LISTEN:4243,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock &"
    echo "socid=\$!"
fi
