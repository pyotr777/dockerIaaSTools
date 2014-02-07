#!/bin/bash

# Remove empty chains from iptables

lines=$(iptables -t nat -L  | grep '0 references' | awk '{ print $2}')
for cont_name in $lines
do
    v="iptables -t nat -X $cont_name"
    echo $v
    eval $v
done
