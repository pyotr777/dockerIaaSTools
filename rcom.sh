#!/bin/bash
version=0.1
mkdir -p /Users/peterbryzgalov/work/Kscope_projects/NICAMdock
sshfs -p 2225 peterbryzgalov@172.17.42.1:/Users/peterbryzgalov/work/Kscope_projects/NICAMdock /Users/peterbryzgalov/work/Kscope_projects/NICAMdock
cd /Users/peterbryzgalov/work/Kscope_projects/NICAMdock
echo "ver $version";pwd;ls -l;export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/go/bin:/applications/tau/tau/apple/bin:/opt/omnixmp/bin;make
