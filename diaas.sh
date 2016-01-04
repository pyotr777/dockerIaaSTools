#!/bin/bash
#
# Start container if it's not running.
# Run commands inside user container.
#
# Special commands (SSH_ORIGINAL_COMMAND):
# commit - commit container
# remove - remove continaer
#
# Created by Peter Bryzgalov
# Copyright (c) 2013-2015 RIKEN AICS.

version="0.43"

# Will be substituted with path to cofig file during installation
source /home/peter/dockerIaaSTools/diaas_installed.conf

# mount table file lists folders, that should be mount on container startup (docker run command)
# file format:
# username@mountcommand1;mountcommand2;...
# mountcommand format: 
# [host-dir]:[container-dir]:[rw|ro]

# Verbose logs for debugging
debuglog=1

# 1 if we started container
container_started=0

# FUNCTIONS

# Return host-side port number mapped to the port 
getPort() {
    cont_port=""
    if [ -z $1 ]
    then
        cont_port="22/tcp"
    else 
        cont_port=$1
    fi

    PORT=$($dockercommand inspect $cont_name | jq .[0].NetworkSettings.Ports | jq '.["'"$1"'"]' | jq -r .[0].HostPort)
    if [ $debuglog -eq 1 ]
    then
        echo "Port mapping $cont_port->$PORT" >> $forcecommandlog
    fi
    echo $PORT
}

# Print free port number.
# Loops through the port range and returns first port number that is not used.
getFreePort() {
    # Port range. Use dynamic port numbers.
    startport=49152
    endport=65535

    # Which netstat?
    test=$(netstat -V 2>/dev/null)

    if [[ $test == *"net-tools"* ]]
    then    
        # Array of used port numbers
        used=( $(netstat -n -t | grep : | awk '{ print $4 }' |  awk -F ':' '{ print $2 }') )
    else 
        used4=( $(netstat -n -p tcp | grep "tcp4" | awk '{ print $4 }' |  awk -F '.' '{ print $5 }') )
        used6=( $(netstat -n -p tcp | grep "tcp6" | awk '{ print $4 }' |  awk -F '.' '{ print $2 }') )
        used=( "${used4[@]}" "${used6[@]}" )
    fi

    for port in $(seq $startport $endport)
    do
        isused="false"
        for uport in "${used[@]}"
        do
            if [ "$port" == "$uport" ]
            then 
                isused="true"
                break
            fi
        done
        if [ "$isused" == "false" ]
        then
            echo "$port"
            break           
        fi
    done
}


# Read from mountfile, search for username@... line,
# return part of Docker run command for mounting volumes
# like this: "-v hostdir:contdir -v hostdir:contdir:ro"
getMounts() {
    mount_command=""
    mounts=$(grep $1 $mountfile | awk -F"@" '{ print $2 }')  
    if [ -z "$mounts" ]; then 
        echo ""
        exit 0
    fi      
    IFS=';' read -ra mounts_arr <<< "$mounts"
    for mnt in "${mounts_arr[@]}"; do
        mount_command="$mount_command-v=$mnt "
    done                   
    echo $mount_command
}

# Return home directory in container (e.g. /root)
getContainerHome() {
    homedir=$($dockercommand exec $cont_name env | grep "HOME=")
    homedir=${homedir:5}
    echo "$homedir"
}

# Return destination path, relative to home directory
dirs=()
getPath() { 
    currentdir=$( IFS=$'/'; echo "${dirs[*]}" )
    echo "$currentdir/$1"
}

# Add directory to dirs array
addPath() {
    n=${#dirs[@]}
    dirs[$n]="$1"
}

# Remove last element from dirs array
delPath() {
    n=${#dirs[@]}
    p=$((n-1))
    unset dirs[$p]  
}

# Parse line with path and mode
# Sample line: D0744 0 tmp_dir
pathmode() {
    read -ra pathmode <<< $(echo "$1")
    mod="${pathmode[0]}"
    mod="${mod:1}"
    path="${pathmode[2]}"
    echo "mod=$mod;path=$path"
}

# Parse scp logs one line at a time
# get file path, mod and type
# or save file contents into a new file in container
infile=0  # flag that we're reading next line of file contents
copyfile="$HOME/tmp_file" # contents of the file to copy
contents=""
parseLogLine() {
    if [[ $line =~ ^[.]*[\>\<] ]]; then
        # Service string
        echo "  $line" >> $forcecommandlog
        if [[ "$infile" == "1" ]]; then
            # Finished reading file
            # Copy new file in container and set its access permissions
            # echo -e "$contents" > $copyfile
            copyfile="$host_tmp_dir/$path"
            homedir=$(getContainerHome)
            echo "COPY $mod:$copyfile->$cont_name:$homedir/$path" >> $forcecommandlog
            $dockercommand cp $copyfile "$cont_name:$homedir/$path"         
            $dockercommand exec $cont_name chmod $mod $homedir/$path
            $dockercommand exec $cont_name ls -l $homedir/$path >> $forcecommandlog
            contents=""
            infile=0
        fi
    elif [[ $line =~ ^[CD][0-9]+ ]]; then
        # Have mode line
        echo "  $line" >> $forcecommandlog
        homedir=$(getContainerHome)
        if [[ $line =~ ^C ]]; then
            # Have file
            eval $(pathmode "$line")
            path=$(getPath $path)
            echo "mod $mod $homedir/$path" >> $forcecommandlog
        elif [[ $line =~ ^D ]]; then 
            # Have directory
            # Create new directory and set its permissions
            eval $(pathmode "$line")
            addPath "$path"  # Add new directory to dirs array
            path=$(getPath) 
            $dockercommand exec $cont_name mkdir -p $homedir/$path
            $dockercommand exec $cont_name chmod $mod $homedir/$path
            echo "Created dir $homedir/$path with $mod in container"  >> $forcecommandlog
        fi
    elif [[ $line =~ ^E ]]; then
        # End directory
        delPath
    else
        # File contents
        if [[ "$infile" == "0" ]]; then
            infile=1
            contents="$line"
        else
            contents="$contents"$'\n'"$line"
        fi
    fi  
}

if [ ! -w $forcecommandlog ];then
    touch $forcecommandlog
fi

if [ ! -f $usersfile ];then
    echo "Cannot find file $usersfile" >> $forcecommandlog
    exit 1;
fi

# Start socat if docker is not accessible with dockercommand
error=$( { $dockercommand ps > /dev/null; } 2>&1 )
if [[ -n "$error" ]]; then
    ${install_path}/socat-start.sh >> $forcecommandlog
fi

echo "$0 $version" >> $forcecommandlog
echo "----- start -----" >> $forcecommandlog
date >> $forcecommandlog
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $forcecommandlog
if [ $debuglog -eq 1 ]; then
    echo "USR: $USER" >> $forcecommandlog
    echo "CON: $SSH_CONNECTION" >> $forcecommandlog
fi

# Get user container name from table in file usersfile
cont_name=$(grep -E "^$USER " $usersfile| awk '{ print $2 }')
if [ -z "$cont_name" ]; then
    echo "No user $USER registered here." >&2
    exit 1
fi

image="localhost/$USER"

if [ $debuglog -eq 1 ]; then
    echo "User container: $cont_name, Image: $image" >> $forcecommandlog
fi

# Check SSH_ORIGINAL_COMMAND
if [ "$SSH_ORIGINAL_COMMAND" = commit ]; then 
    if [ $debuglog -eq 1 ]; then
        echo "Commit container $cont_name" >> $forcecommandlog
    fi    
    command="$dockercommand commit $cont_name $image"
    $command
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = stop ]; then
    if [ $debuglog -eq 1 ]; then
        echo "Stop container $cont_name" >> $forcecommandlog
    fi 
    command="$dockercommand kill $cont_name"
    $command
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = remove ]; then
    if [ $debuglog -eq 1 ]; then
        echo "Remove container $cont_name" >> $forcecommandlog
    fi 
    command="$dockercommand rm $cont_name"
    $command
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = port ]; then
    if [ $debuglog -eq 1 ]; then
        echo "Return container $cont_name ssh port number" >> $forcecommandlog
    fi 
    PORT=$(getPort "22/tcp")
    echo $PORT
    exit 0
fi

if [ "$SSH_ORIGINAL_COMMAND" = freeport ]; then
    if [ $debuglog -eq 1 ]; then
        echo "Return free server port number" >> $forcecommandlog
    fi 
    PORT=$(getFreePort)
    echo $PORT
    exit 0
fi

# Action (command) on container
# empty string -- container is running, no actions performed
# start -- container has been stopped and was started
# run -- there were no container and a new container was created
container_action=""

# Get running containers names
# If user container name not in the list,
# start user container,
# get SSH port external number
ps=$(eval "$dockercommand ps" | grep "$cont_name ")
if [ "$ps" ] && [ $debuglog -eq 1 ]
then
    echo "Container is running" >> $forcecommandlog
fi


if [ -z "$ps" ]
then
    psa=$(eval "$dockercommand ps -a" | grep "$cont_name ")
    if [ "$psa" ] 
    then
        if [ $debuglog -eq 1 ]
            then
            echo "Container is stopped" >> $forcecommandlog
        fi
        #   Start container
        cont=$($dockercommand start $cont_name)
        if [ $debuglog -eq 1 ]
            then
            echo "Start container $cont" >> $forcecommandlog
        fi
        container_action="start"
        sleep 1
    else 
        if [ $debuglog -eq 1 ]; then
            echo "No container. Run from image." >> $forcecommandlog
        fi

        # Run container
        mounts=$(getMounts $USER)
        # Permissions to mount with sshfs inside container
        moptions=""
        if [ "permit_mounts" ]
        then
            moptions=" --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined"
        fi
        options="run -d --name $cont_name $mounts $moptions -P=true $image"
        cont=$($dockercommand $options)
        if [ $debuglog -eq 1 ]
            then
            echo "Start container $cont with command: $options" >> $forcecommandlog
        fi
        container_action="run"
        sleep 1
    fi
    
    #   get running container port number
    PORT=$(getPort "22/tcp")
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
    echo "started container with open port $PORT" >> $forcecommandlog    
fi



# get running container port number
if [ -z "$PORT" ]
then    
    PORT=$(getPort "22/tcp")
    sshcommand=( ssh -p "$PORT" -A -o StrictHostKeyChecking=no root@localhost )
fi

echo "> $(date)" >> $forcecommandlog

# Execute commands in container
# -----------------------------

# SCP / SFTP
SCP=0
if [[ "$SSH_ORIGINAL_COMMAND" =~ ^scp\ [-a-zA-Z0-9\ \.]* ]];then
    SCP=1
fi
if [[ "$SSH_ORIGINAL_COMMAND" =~ sftp-server ]];then
    SCP=1
fi

if [[ "$SCP" == "1" ]]; then
    socat_tmpfile="$HOME/scp.sh"
    #host_tmp_dir="$HOME/tmp_scp_dir"
    #mkdir -p $host_tmp_dir
    echo "SCP detected  at $(pwd)" >> $forcecommandlog
    short_scp_commad=$(expr "$SSH_ORIGINAL_COMMAND" : '^\(scp\( -[a-z]\)*\)')
    echo "scp command: $short_scp_commad"  >> $forcecommandlog
    # Get filename
    ipath=$(echo "$SSH_ORIGINAL_COMMAND" | sed 's/^scp\( -[a-z]\)* //')
    #   
    if [[ "$SSH_ORIGINAL_COMMAND" =~ ^scp\ .*-t ]];then
        echo "Destination path is $ipath" >> $forcecommandlog
        if [[ "${ipath:0:1}" == "/" ]]; then
            # Absolute path
            homedir="" 
        else
            # Relative path
            homedir="$(getContainerHome)/"
        fi
        socat_command="$dockercommand exec -i $cont_name $short_scp_commad $homedir$ipath"
        echo "$socat_command" > $socat_tmpfile
        chmod +x $socat_tmpfile
        command="socat - SYSTEM:$socat_tmpfile,reuseaddr"
        echo "Executing $command" >> $forcecommandlog
        echo "$socat_tmpfile: $(cat $socat_tmpfile)" >> $forcecommandlog
        $command 2>> $forcecommandlog
        rm $socat_tmpfile
    else
        echo "Source path is $ipath" >> $forcecommandlog
        if [[ "${ipath:0:1}" == "/" ]]; then
            # Absolute path
            homedir="" 
        else
            # Relative path
            homedir="$(getContainerHome)/"
        fi
        socat_command="$dockercommand exec -i $cont_name $short_scp_commad $homedir$ipath"
        echo "$socat_command" > $socat_tmpfile
        chmod +x $socat_tmpfile
        command="socat - SYSTEM:$socat_tmpfile,reuseaddr"
        echo "Executing $command" >> $forcecommandlog
        echo "$socat_tmpfile: $(cat $socat_tmpfile)" >> $forcecommandlog
        $command 2>> $forcecommandlog
        rm $socat_tmpfile            
    fi
    commands=()
    #rm -rf $host_tmp_dir    
elif [[ -n "$SSH_ORIGINAL_COMMAND" ]]; then
    commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
else
    # Interactive login 
    sshcommand=( ssh -p "$PORT" -Y -A -o StrictHostKeyChecking=no root@localhost )
    commands=( "${sshcommand[@]}" "$SSH_ORIGINAL_COMMAND" )
fi
if [ $debuglog -eq 1 ]
then
    echo "${commands[@]}" >> $forcecommandlog
fi
"${commands[@]}"
# -----------------------------

echo "<" $(date) >> $forcecommandlog
echo " " >> $forcecommandlog
