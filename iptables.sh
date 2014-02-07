#!/bin/bash

# Routing to Docker containers.
#
# Created by Bryzgalov Peter on 2013/11/18.
# Copyright (c) 2013 Riken AICS. All rights reserved

cont_name=$1
int_IP=$3
ext_IP=$2

iptables -t nat -N $cont_name
iptables -t nat -A $cont_name -j DNAT --to-destination $int_IP

iptables -t nat -A PREROUTING -d $ext_IP -j $cont_name
iptables -t nat -A OUTPUT -d $ext_IP -j $cont_name