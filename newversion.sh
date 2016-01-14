#!/bin/bash

# Change version numbers in all .sh file to $1
# Original version number is obtained from install.sh

basefile="install.sh"

tmp=$(grep "version=" $basefile)
eval "$tmp"

if [ $# -lt 1 ]; then
	echo "Need new version number"
	echo "old version=$version"
	exit 1
fi
newversion=$1
echo "New version $newversion"
if grep -q GNU <<<$(sed --version 2>/dev/null); then  
	find . -name "*.sh" | xargs sed -i "s/$version[a-z0-9]*/$newversion/" 
else
	find . -name "*.sh" | xargs sed -i '' "s/$version[a-z0-9]*/$newversion/" 
fi
