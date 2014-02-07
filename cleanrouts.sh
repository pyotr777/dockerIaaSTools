#!/bin/bash

# Remove IP addresse rules from iptables

lines=$(iptables -t nat -L OUTPUT | grep '172' | awk '{ print $1 ";" $5 }')
for l in $lines
do
    IFS=$";" read -ra lp <<< "$l"
    echo "${lp[0]} -> ${lp[1]}"
    cont_name="${lp[0]}"
    ext_IP="${lp[1]}"
    v1="iptables -t nat -D PREROUTING -d $ext_IP -j $cont_name"
    v2="iptables -t nat -D OUTPUT -d $ext_IP -j $cont_name"
    v4="iptables -t nat -X $cont_name"
    echo $v1
    eval $v1
    echo $v2
    eval $v2
    echo $v4
    eval $v4
done
