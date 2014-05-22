#!/bin/bash

docker run -d -p 22 -name test -v $(pwd):/vol1:rw peter/ssh /usr/sbin/sshd -D
PID=$(docker top test | grep ":" | awk '{ print $2 }')
# nsenter --target $PID --mount --uts --ipc --net --pid
