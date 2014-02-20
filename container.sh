# !/bin/bash
#
# Run commands inside user container.
# Increment connections counter before commands,
# decrement the counter after commands exit,
# start dockerwatch.sh to check connections counter and stop container if 0.
#
# Created by Bryzgalov Peter on 2014/02/19
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.10"

# Procedure for syncronized increment of connections counter
function synchro_increase {
    counter_file=$1
    flock -x -w 5 $counter_file sh -c "COUNTER=$(cat $counter_file); echo $((COUNTER + 1)) > $counter_file"
}

# Procedure for syncronized decrement of connections counter
function synchro_decrease {
    counter_file=$1
    flock -x -w 5 $counter_file sh -c "COUNTER=$(cat $counter_file); echo $((COUNTER - 1)) > $counter_file"
}

# Connections counter
counter_file="/tmp/connection_counter"
log_file="/container.log"
dockerwatch_log="/dockerwatch.log"

if [ ! -w $log_file ]
then
    touch $log_file
fi

if [ ! -w $counter_file ]
then
    touch $counter_file
fi

if [ ! -w $dockerwatch_log ]
then
    touch $dockerwatch_log
fi

# Increase connection counter
synchro_increase $counter_file

function synchro_read {
    counter_file=$1
    exec 20>$counter_file
    flock -x -w 2 20
    COUNTER=$(cat $counter_file)
    return $COUNTER
}

echo "container.sh $version" >> $log_file
synchro_read $counter_file
COUNTER=$?
echo "----- start at $COUNTER -----" >> $log_file
date >> $log_file
echo "USR: $USER" >> $log_file
echo "CLT: $SSH_CLIENT" >> $log_file
echo "ORC: $SSH_ORIGINAL_COMMAND" >> $log_file

if [ "$SSH_ORIGINAL_COMMAND" ]
then
# Execute commands
    commands="$SSH_ORIGINAL_COMMAND"
    echo "Execute: $commands" >> $log_file
    $commands 2>> $log_file
else
# or start bash
    eval "/bin/bash"
fi

# Increase connection counter
synchro_decrease $counter_file


# Start dockerwatch.sh
echo "Starting dockerwatch" >> $log_file
/dockerwatch.sh >> $dockerwatch_log  2>> $log_file &

synchro_read $counter_file
COUNTER=$?
echo "Exit at $COUNTER" >> $log_file
echo "<" $(date) >> $log_file
echo "-----------------------" >> $log_file
