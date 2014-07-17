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

version="3.1.8"
echo "createuser.sh $version"

# Initialization
if [ $# -lt 1 ]
then
    read -r -d '' hlp <<-'EOF'
	Creates user with designated SSH key, creates Docker image "localhost/username".
	Makes set up for automatic user login to the container
	with SSH and agent forwarding.

Parameters:
	user name,
	Docker image name to use for container,
	file with public SSH key,

EOF
    echo "$hlp"
    exit 0
fi

username=$1
image=$2
public_key_file=$3

user_table_file="/var/usertable.txt"
container_connections_counter="/tmp/dockeriaas_cc"
container_config="/tmp/dockeriaas_conf"
container_home="/root"
service_folder="service"
service_container_folder="/usr/local/bin"


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

if [[ -z "$image" ]]
then
    echo "Need Docker image."
    echo "Possible values:"
    docker images | grep -v REPOSITORY
    exit 1
fi

avail_image=$(docker images | grep $image)
if [[ -z "$avail_image" ]]
then
    echo "Not found Docker image $image."
    echo "Try one of these:"
    docker images | grep -v REPOSITORY | awk '{ print $1 }'
    exit 1
fi

# Create Dockerfile 

read -r -d '' dockerfile_string <<EOF
FROM $image
EXPOSE 22
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8
RUN apt-get install -y ssh
RUN mkdir -p /var/run/sshd

# Disable pam_loginuid to correct SSH login bug
RUN sed -r -i "s/session\s+required\s+pam_loginuid\.so/session optional pam_loginuid.so/" /etc/pam.d/sshd

# ENV DEBIAN_FRONTEND dialog

RUN mkdir $container_home/.ssh
ADD $public_key_file $container_home/.ssh/authorized_keys
ADD $service_folder/ $service_container_folder/

RUN echo 0 > $container_connections_counter
RUN printf "timeout:2\n" > $container_config
RUN mkdir /logs

# Disable password login
# RUN sed -r -i "s/^.*PasswordAuthentication[yesno ]+$/PasswordAuthentication no/" /etc/ssh/sshd_config

RUN printf "\nForceCommand $service_container_folder/container.sh" >> /etc/ssh/sshd_config
ENV DEBIAN_FRONTEND dialog
CMD ["/usr/sbin/sshd","-D"]
EOF

echo "$dockerfile_string" > Dockerfile

# Build image

docker build -t localhost/$username .

# Remove Dockerfile
rm Dockerfile

# Register user and conatiner names in user table file
echo "$username $username" >> $user_table_file

# Create user
useradd -m $username
usermod -a -G dockertest $username
usermod -a -G ssh $username
echo "User $username created on server"

if [ ! -d "/home/$username/.ssh" ]
then
    mkdir -p /home/$username/.ssh
fi
cat $public_key_file > /home/$username/.ssh/authorized_keys
chown -R $username:$username /home/$username/

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

# docker run -d -name $username -P localhost/$username

