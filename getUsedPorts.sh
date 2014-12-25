netstat --tcp -n | grep : | awk '{ print $4 }' |  awk -F ':' '{ print $2 }'
