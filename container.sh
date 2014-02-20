# !/bin/bash
#
# Run commands inside user container.
# Increment connections counter before commands,
# decrement the counter after commands exit,
# start dockerwatch.sh to check connections counter and stop container if 0.
#
# Created by Bryzgalov Peter on 2014/02/19
# Copyright (c) 2013-2014 Riken AICS. All rights reserved

version="2.20"


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

# Increment connection counter
exec "/synchro_increment.sh $counter_file" >> $log_file 2>&1

echo "container.sh $version" >> $log_file
COUNTER=$(exec "/synchro_read.sh $counter_file")
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
#else
# or start bash
#    eval "/bin/bash"
fi

