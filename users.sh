#!/bin/bash
#
# Display list of Docker IaaS users
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.34a03"

eval $(./install.sh -c)
if [ ! -f "$diaasconfig" ]; then
	echo "No Docker IaaS Tools installed in this directory."
	exit 0
fi
source $diaasconfig

users=$(cat $usersfile) 2>/dev/null
if [ -n "$users" ]; then
	printf "Users:\n%s" "$users"
fi
