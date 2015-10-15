#!/bin/bash

# Change version numbers in all .sh file to $1
# Original version number is obtained from install.sh

if [ $# -lt 1 ]; then
	echo "Need new version number"
	exit 1
fi

version=$(grep "version=" install.sh)
eval "$version"
echo "old version=$version"
newverison=$1

find . -name "*.sh" | xargs sed -i"s#$version#$newverison#"