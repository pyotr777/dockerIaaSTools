#!/bin/bash

#  Removes user from server,
#  removes user record from tabel file (/usertable.txt)
#  removes user container,
#  removes user image.
#
#  Parameters:
#  user name
#
#  Created by Peter Bryzgalov
#  Copyright (c) 2014 RIKEN AICS.

version="3.3b01"

if [[ -z $1 ]]
	then
	echo "Enter user name to delete."
	echo "Users:"
	echo "$(./users.sh)"
	exit 1
fi

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

usr=$1
container=$usr
image="localhost/$usr"

source ./install.sh -c

echo "Delete user $usr v.$version"


userExists() {
    awk -F":" '{ print $1 }' /etc/passwd | grep -x $1 > /dev/null
    return $?
}


echo "Removing container $container"

out=$(docker kill $container 2>&1) 
if [[ $out == *Error* ]]
then
	echo $out	
fi

out=$(docker rm $container 2>&1)
if [[ $out == *Error* ]]
then
	echo $out    
fi

echo "Removing image $image"
out=$(docker rmi $image 2>&1)
if [[ $out == *Error* ]]
then
	echo $out
fi

# remove record from usersfile
echo "Removing record from $usersfile"
pattern="^$usr\s+$usr$"
test=$(grep -E "$pattern" $usersfile)

if [ -z "$test" ]
then
	echo "Record for $usr not found"
	exit 1
fi

sed -r -i "/$pattern/d" $usersfile
echo "User $usr removed"

echo "Removing user on host"
deluser --remove-home $usr

echo "Removing group on host"
groupdel $usr

