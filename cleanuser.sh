#!/bin/sh

#  Removes user from server,
#  removes user record from tabel file (/usertable.txt)
#  and removes user container.
#
#  Parameters:
#  user name
#
#  Created by Peter Bryzgalov on 2014/01/23
#  Copyright (C) 2014 RIKEN AICS.

usr=$1

echo "Removing user $usr"
deluser --remove-home $usr
docker kill $usr
docker rm $usr

# remove record from /usertable.txt
sed -r -i "/$usr(\s+)$usr$/d" /usertable.txt