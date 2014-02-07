#!/bin/bash

# Routing to Docker containers.
#
# Created by Bryzgalov Peter on 2013/11/18.
# Copyright (c) 2013 Riken AICS. All rights reserved

cont_name=$1
echo $cont_name
ext_IP=`iptables -t nat -L PREROUTING | grep $cont_name | awk '{ print $5 }'`
echo "extIP $ext_IP"

v1="iptables -t nat -D PREROUTING -d $ext_IP -j $cont_name"
v2="iptables -t nat -D OUTPUT -d $ext_IP -j $cont_name"
v3="iptables -t nat -D $cont_name 1"
v4="iptables -t nat -X $cont_name"
echo $v1
eval $v1
echo $v2
eval $v2
echo $v3
eval $v3
echo $v4
eval $v4