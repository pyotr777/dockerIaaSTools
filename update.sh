#!/bin/bash 

# Update docker.sh for Docker IaaS tools.
# Need to be run with root privileges.
#  Created by Peter Bryzgalov
#  Copyright (C) 2016 RIKEN AICS. All rights reserved

version="0.45"
debug=1
read -rd '' usage << EOF
Update docker.sh script for already installed Docker IaaS tools. Must be run as root. 
Usage:
  \$ sudo $0 [configuration file]
EOF

# Check section
# Exit if something's wrong
if [ $# -gt 1 ]; then
    printf "%s" "$usage"
    exit 0
fi

if [[ $(id -u) != "0" ]]; then
    printf "Error: Must be root to use it.\n" 1>&2
    exit 1
fi

### Configuration section
diaasconfig="diaas_installed.conf"
if [[ -n "$1" ]]; then 
    diaasconfig="$1"
fi

echo "Using configuration from $diaasconfig"
if [[ ! -f "$diaasconfig" ]]; then
    echo "File $diaasconfig not found."
    exit 1
fi

source "$diaasconfig"

echo "Copy docker.sh to $forcecommand"
cp docker.sh "$forcecommand"

# Replace filename with full path to config file in docker.sh
sed -ri "s#source diaasconfig#source \"$(pwd)/$diaasconfig\"#" "$forcecommand"
chmod +x "$forcecommand"
echo "done."
