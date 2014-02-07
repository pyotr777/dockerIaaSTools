#!/bin/bash

# Creates virtual network interface for assigning
# external IP address to Docker container.
#
# Created by Bryzgalov Peter on 2013/11/18.
# Copyright (c) 2013 Riken AICS. All rights reserved.

bridge_name=$1

echo "Create bridge interface $bridge_name"

ip link add $bridge_name link eth0 type macvlan mode bridge
dhclient $bridge_name
ip link set $bridge_name up


