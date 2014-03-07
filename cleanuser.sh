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

version="2.6.9"
usr=$1

echo "Delete user $usr v.$version"
user_table_file="/var/usertable.txt"

# remove record from user_table_file
before=$(wc -l < $user_table_file)
sed -r -i "/^$usr(\s+)$usr$/d" $user_table_file
after=$(wc -l < $user_table_file)
if [ $before -eq $after ]
then
    echo "Record for $usr not found"
    exit 0
fi

echo "Removing user $usr"
docker kill $usr
docker rm $usr
deluser --remove-home $usr

