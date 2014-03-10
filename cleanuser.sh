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

version="2.7.0"
usr=$1

echo "Delete user $usr v.$version"
user_table_file="/var/usertable.txt"

# remove record from user_table_file
pattern="^$usr\s+$usr$"
test=$(grep -E "$pattern" $user_table_file)
if [ -z "$test" ]
then
    echo "Record for $usr not found"
    exit 0
fi
echo "Removing user $usr"
out=$((docker kill $usr) 2>&1)
if [[ $out == *Error* ]]
then
	echo $out
    exit 0
fi
out=$((docker rm $usr) 2>&1)
if [[ $out == *Error* ]]
then
	echo $out
    exit 0
fi
deluser --remove-home $usr
sed -r -i "/$pattern/d" $user_table_file
echo "User $usr removed"
