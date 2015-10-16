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
#  Copyright (c) 2014-2015 RIKEN AICS.

version="0.32a02"

if [[ -z $1 ]]
	then
	echo "$0 $version"
	echo "Need user name to delete."
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
source $diaasconfig

userExists() {
    awk -F":" '{ print $1 }' /etc/passwd | grep -x $1 > /dev/null
    return $?
}


if grep -q "$container" <<<"$($dockercommand ps)"; then
	out="$($dockercommand kill $container 2>&1)"
	if [[ $out == *Error* ]]
	then
		echo "Errors while stopping container $container"
		echo $out 	
	fi
fi

out="$($dockercommand rm $container 2>&1)"
if [[ $out == *Error* ]]
then
	echo "Errors while deleting container $container"
	echo $out    
fi

out="$($dockercommand rmi $image 2>&1)"
if [[ $out == *Error* ]]
then
	echo $out
fi

# delete record from usersfile
pattern="^$usr\s+$usr$"
test=$(grep -E "$pattern" $usersfile)
if [ -z "$test" ]
then
	echo "DIaaS user $usr not found"
	exit 1
fi

sed -r -i "/$pattern/d" $usersfile
printf "$format" "DIaaS user $usr" "deleted"

deluser --remove-home $usr
printf "$format" "OS user $usr" "deleted"

groupdel $usr
if [[ $? -eq 0 ]]; then
	printf "$format" "OS group $usr" "deleted"
fi
