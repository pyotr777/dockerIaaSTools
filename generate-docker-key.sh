#!/bin/bash
if [[ -z "$1" ]]; then
    echo -n "Enter key file name:"
    read filename
else
    filename="$1"
fi
echo -n "Create key ${filename}? [y/n]"
read -n 1 start
if [[ $start == "y" ]]; then
    ssh-keygen -t rsa -N "" -f $filename
fi
