#!/bin/bash

#  Removes user from server,
#  removes user record from tabel file (/usertable.txt)
#  and removes user container.
#
#  Parameters:
#  user name
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2014 RIKEN AICS.

version="3.0.1"
usr=$1
container=$usr
image=localhost/$usr

echo "Delete user $usr v.$version"
user_table_file="/var/usertable.txt"

userExists() {
    awk -F":" '{ print $1 }' /etc/passwd | grep -x $1 > /dev/null
    return $?
}


echo "Removing container $container"

out=$(docker kill $container 2>&1) 

if [[ $out == *Error* ]]
then
	echo $out
	exit 1
fi
out=$(docker rm $container 2>&1)
if [[ $out == *Error* ]]
then
	echo $out
    exit 1
fi

echo "Removing image $image"
out=$(docker rmi $image 2>&1)
if [[ $out == *Error* ]]
then
	echo $out
    exit 1
fi

# remove record from user_table_file
pattern="^$usr\s+$usr$"
test=$(grep -E "$pattern" $user_table_file)

if [ -z "$test" ]
then
	echo "Record for $usr not found"
	exit 1
fi


deluser --remove-home $usr
sed -r -i "/$pattern/d" $user_table_file
echo "User $usr removed"
