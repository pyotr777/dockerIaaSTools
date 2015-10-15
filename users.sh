#!/bin/bash
#
# Display list of Docker IaaS users
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.31a11"

source ./install.sh -c
source $diaasconfig

users=$(cat $usersfile) 2>/dev/null
if [ -n "$users" ]; then
	printf "Users:\n%s" "$users"
fi
