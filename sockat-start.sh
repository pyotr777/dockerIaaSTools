#!/bin/bash
# Start socat TCP proxy to docker socket on specific port. Default is 4243.

port=4243
if [ -n "$1" ]; then
	port=$1
fi

echo "Start TCP proxy to docker socket runs on port $port"
socat TCP-LISTEN:$port,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock &