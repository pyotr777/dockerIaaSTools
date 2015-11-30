#!/bin/bash 

# Install Docker IaaS tools.
# Need to be run with root privileges.
#
# Requires:
# 	docker
#	sshd
#	apt-get
# 	groupadd
#	socat	
#	jq
#	sed
#
#  Created by Peter Bryzgalov
#  Copyright (C) 2015 RIKEN AICS. All rights reserved

version="0.42socat_exec01"
debug=1


# Set "$option yes" in $ssh_conf file.
# Uses sed.
# Works on OSX and Ubuntu. OSX sed is different: -E instead of -r for extended regexp, 
# no regexp enhanced features like "\s", need '' after -i. 
# Parameter: option name (AllowAgentForwarding, GatewayPorts, ...)
#
# Use global variables:
# $ssh_conf
# $format
permitOption() {
	option=$1
	if grep -qE "^\s*$option\s+(yes|no)+" "$ssh_conf"; then
		ERROR=$( { sed -ri "s/\s*$option\s+(yes|no)+\s*/$option yes/" "$ssh_conf" > /dev/null; } 2>&1 )
		if [ -n "$ERROR" ]; then
			# OSX version
			sed -E -i '' "s/[[:space:]]*$option[[:space:]]+(yes|no)+[[:space:]]*/$option yes/" "$ssh_conf"
		fi		
	else 
		printf "\n%s\n" "$option yes" >> "$ssh_conf"
	fi
	printf "$format" "$ssh_conf" "$option permitted"
}


### Configuration section
diaasconfig="diaas_installed.conf"

##### These variables saved to the above file
forcecommand="/usr/local/bin/diaas.sh"
forcecommandlog="/var/log/diaas.log"
tablesfolder="/var/lib/diaas"
mountfile="$tablesfolder/mounttable.txt"
usersfile="$tablesfolder/userstable.txt"
dockerhost="localhost"
dockerport="4243"
dockercommand="docker -H $dockerhost:$dockerport"
diaasgroup="diaasgroup"
ssh_conf="/etc/ssh/sshd_config"
ssh_backup="${ssh_conf}.diaas_back"
sshd_pam="/etc/pam.d/sshd"
install_path="$(pwd)"
config_file="/etc/diias/config"
### Configuration section end

# Define output format
format="%-50s %-20s\n"

# Array for saving variables to configuration file
config_vars=(forcecommand forcecommandlog tablesfolder mountfile usersfile \
	dockerhost dockerport dockercommand diaasgroup ssh_conf \
	ssh_backup sshd_pam format install_path config_file)

read -rd '' usage << EOF
Installation script for Docker IaaS tools v$version

Usage: \$ sudo $0 [-c]
Options: 
	-c print path to the file with configuration variables and exit. 
	Can be used with \"eval \$(./install.sh -c)\" command. 
	This option does not require root privileges.

Docker IaaS tools requirements: bash, Docker, socat, jq.
Required OS: Ubuntu, Debian.
EOF

# Check section
# Exit if something's wrong
if [ $# -gt 2 ]; then
	printf "%s" "$usage"
	exit 0
fi

if [[ "$1" == "-c" ]]; then 
	echo "export diaasconfig=\"$(pwd)/$diaasconfig\""
	exit 0
elif [[ -n "$1" ]]; then
	printf "%s" "$usage"
	exit 1
fi

if [[ $(id -u) != "0" ]]; then
	printf "Error: Must be root to use it.\n" 1>&2
	exit 1
fi

# Check jq install
jq &>/dev/null
if [[ $? -gt 1 ]]; then
	echo -n " jq is required for Docker IaaS Tools. Install jq? [y/n]"
	read -n 1 install
	printf "\n"
	if [[ $install != "y" ]]; then
		printf "Bye!\n"
		exit 1
	fi
	apt-get install -y jq
fi

# Check that port is not used
read pname pid junk <<< "$(sudo lsof -i TCP:$dockerport | grep -v COMMAND)"
if [[ -n "$pid" ]]; then
	echo "Port $dockerport is used by $pname with PID $pid. Use another port number (dockerport var in install.sh)."
	exit 1
fi

# Write variables to config file diaas_installed.conf
touch $diaasconfig
printf "" > $diaasconfig
for var in "${config_vars[@]}"; do
	echo "$var=\"$(eval echo \$$var)\"" >> $diaasconfig
done
printf "$format" "$diaasconfig" "saved"

# Start socat proxy
./socat-start.sh savepid
if [ ! -f socat.pid ]; then
	printf "$format"  "socat" "failed"
	exit 1
fi
socatpid=$(cat socat.pid)
if [[ -n "$socatpid" ]]; then
	echo "socatpid=\"$socatpid\"" >> $diaasconfig
fi
# Delete file with socat PID
rm socat.pid

dockerimagesline=$($dockercommand images 2>/dev/null | grep IMAGE | wc -l)
if [[ $dockerimagesline -eq 0 ]]; then
	printf "Error: Cannot connect to Docker with command:\n%s\n" "$dockercommand" 1>&2
	exit 1
elif [[ $dockerimagesline -eq 1 ]]; then
	printf "$format" "Connection to Docker" "OK"
else
	printf "Somethings wrong :%s\n" "$dockerimagesline"
	exit 1
fi
# Check section end

# Group diaasgroup - create if not exists

if [ -z "$(cat /etc/group | grep $diaasgroup:)" ]; then
	echo -n " Create group $diaasgroup? [y/n]"
	read -n 1 creategroup
	printf "\n"
	if [[ $creategroup != "y" ]]; then
		echo "Bye!"
		exit 0
	fi
	groupadd "$diaasgroup"
	printf "$format" "Group $diaasgroup" "created"
else
	printf "$format" "Group $diaasgroup" "exists"
fi
 
# Copy files
cp docker.sh $forcecommand
if [[ $? -eq 1 ]]; then
	echo "Error: Could not copy file $(pwd)/docker.sh to $forcecommand" 1>&2
	exit 1
fi
# Replace filename with full path to config file in docker.sh
sed -ri "s#source diaasconfig#source $(pwd)/$diaasconfig#" "$forcecommand"
printf "$format" "Copy $forcecommand" "OK"

if [ ! -f "$forcecommandlog" ]; then
	touch $forcecommandlog
	chmod a+w $forcecommandlog
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $forcecommandlog." 1>&2
		exit 1
	fi
	printf "$format" "Create $forcecommandlog" "OK"
else 
	printf "$format" "$forcecommandlog" "exists"
fi


if [ ! -d "$tablesfolder" ]; then 
	if [ -f "$tablesfolder" ]; then
		echo "Error: $tablesfolder exists, but is a regular file. Need directory." 1>&2
		exit 1
	fi
	mkdir -p $tablesfolder
	chmod a+w "$tablesfolder"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $tablesfolder." 1>&2
		exit 1
	fi
	printf "$format" "Create $tablesfolder" "OK"
else
	printf "$format" "$tablesfolder" "exists"
fi

if [ ! -f "$mountfile" ]; then
	touch $mountfile
	chmod a+w "$mountfile"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $mountfile." 1>&2
		exit 1
	fi
	printf "$format" "Create $mountfile" "OK"
else
	printf "$format" "$mountfile" "exists"
fi

if [ ! -f "$usersfile" ]; then
	touch $usersfile
	chmod +w "$usersfile"
	if [[ $? -eq 1 ]]; then
		echo "Error: Could not create $usersfile." 1>&2
		exit 1
	fi
	printf "$format" "Create $usersfile" "OK"
else
	printf "$format" "$usersfile" "exists"
fi


# Edit config files
if [ -f "$sshd_pam" ]; then
	sed -ri 's/^session\s+required\s+pam_loginuid.so$/session    optional     pam_loginuid.so/' "$sshd_pam"
	if [[ $? -eq 0 ]]; then
		printf "$format"  "$sshd_pam" "edited"
		printf "%s" "sshd_pam_edited=\"edited\"" >> $diaasconfig
	fi
fi

# Patch /etc/ssh/sshd_conf
if [ -f "$ssh_conf" ]; then
	# Save original version
	cp "$ssh_conf" "$ssh_backup"
	# Permit options
	permitOption "AllowAgentForwarding"
	permitOption "GatewayPorts"
	# Add ForceCommand for group $diaasgroup
	if grep -qEi "match\s+group\+$diaasgroup" "$ssh_conf"; then
		# do nothing
		printf "$format" "$ssh_conf" "already patched"
	elif grep -qi "forcecommand" "$ssh_conf"; then
		# /etc/ssh/sshd_conf has differnet ForceCommand
		# Need to edit manually
		printf "$format" "$ssh_conf" "already has ForceCommand. Need manual editing."
		echo "Check that it has the following:"
		echo "AllowAgentForwarding yes"
		echo "GatewayPorts yes"
		echo "Match Group $diaasgroup"
		echo "	ForceCommand $forcecommand"
		echo "----------"
		echo "Fragment of your $ssh_conf file:"
		grep -C 4 "$forcecommand" "$ssh_conf"
		echo -n " Please confirm [press any key]"
		read -n 1 foo
		printf "\n"
	else
		printf "\n%s\n\t%s\n" "Match Group $diaasgroup" "ForceCommand $forcecommand" >> "$ssh_conf"
		printf "$format" "$ssh_conf" "ForceCommand added"
	fi
	if grep -q "AllowAgentForwarding\s+no" "$ssh_conf"; then
		sed -ri 's/^\s*AllowAgentForwarding\.*$/AllowAgentForwarding yes/' "$ssh_conf"
		printf "$format" "$ssh_conf" "AllowAgentForwarding permitted"
	fi
else
	echo "Error: SSH configuration file $ssh_conf not found." 1>&2
	exit 1
fi

echo -n " Restart sshd? [y/n]"
read -n 1 restartssh
printf "\n"
if [[ $restartssh == "y" ]]; then
	service ssh restart			
else
	printf "Please, restart sshd later with:\n\$ sudo service ssh restart\n"
fi

echo "Installation comlete."
