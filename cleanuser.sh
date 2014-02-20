#!/bin/sh

#  Removes user from server,
#  removes user record from tabel file (/usertable.txt)
#  and removes user container.
#
#  Parameters:
#  user name
#
#  Created by Peter Bryzgalov on 2014/02/05
#  Copyright (C) 2014 RIKEN AICS.

usr=$1
user_table_file="/var/usertable.txt"

echo "Removing user $usr"
docker kill $usr
docker rm $usr
deluser --remove-home $usr

# remove record from user_table_file
sed -r -i "/$usr(\s+)$usr$/d" $user_table_file