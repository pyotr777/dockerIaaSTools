# Tools for creating a basic Infrastructure-as-a-Service (v.3.1)

This is a set of bash-script files for creating a basic IaaS on a Linux server. 
The purpose is to give every user a personal virtual machine in the form of a docker container (https://index.docker.io). Users’ containers can be buit from any docker image. Users have root privileges inside their containers. 

Users are created on the server machine, every user is assigned one container. Service users are added to dockertest group. 
When a user connects to the server with SSH he/she automatically logins into his/her container. It is absolutely seamless for users. 

Authentication is based on ssh-key and key forwarding. SSH-key authentication and key-forwarding for the server must be enabled on the user side. 

When host administrator created a user, the following acctions are performed:
* User created on the host (server) and added to groups dockertest and ssh
Dockertest group is used for assigning Force command, and ssh groups can be used to restrict ssh login to the host only to this group members.
* User's docker image is built


## Scheme

![Scheme](docker-IaaS.jpg)

## Demonstration video

http://youtu.be/_SvzsBcp5wQ


## Set up on the server machine

SSH key forwarding must be enabled on the server. 
Force command must be set for dockertest group.
docker.sh file must be placed in the server root directory.

In /etc/ssh/sshd_config:

```
AllowAgentForwarding yes

Match Group dockertest
  ForceCommand /docker.sh
```

## SSH commands

There are special ssh commands, that when run from local computer will not be executed inside the container. These commands are for manipulationg user container.

### commit

Commit user container. The user's docker image is updated with the current container state.

### stop

Stop user container.

### remove

Remove user container. User's docker image is not removed, so when user logs in a new container will be created from user's docker image. 


## Files


### cleanuser.sh

Removes user on the server and removes users's containers.



### createuser.sh

Creates user on the server and creates user's container, set up the server and container for automatic user login to container with SSH key. 

#### Arguments:
	user name
	docker image
	public key file
	
	
#### Requires:
	jq


### docker.sh

Is called every time user logs in with SSH to the host.
docker.sh starts user's container if it is stopped, creates SSH connection from the host to the container.

It must be placed in the host root directory. 

### container.sh

This file is called on every SSH connection to a container. It counts SSH connections and stops the container if there are no active connections and the container is not in “daemon” mode. 

### dockerwatch.sh

Called by container.sh and stop.sh to stop container in due time - when all active SSH connections to the container are closed.


### daemon

Enabling “daemon” mode. This command is to be called inside a container to prevent it from stopping when there are no active SSH connections.


### nodaemon

Command is to be called inside a container to turn off “daemon” mode: to set the container to be stopped after all SSH sessions are closed.


### stopnow

Command is to be run inside a container to stop the container immediately.



