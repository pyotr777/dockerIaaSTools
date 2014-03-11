# Tools for creating a basic Infrastructure-as-a-Service

This is a set of bash-script files for creating a basic IaaS on a Linux server. 
The purpose is to give every user a personal virtual machine in the form of a Docker container. Users containers can be based on any Docker image (https://index.docker.io). Users have root privileges inside their containers. 

Users are created on the server machine, every user is assigned one container. Service users are added to dockertest group. 
When a user connects to the server with SSH he/she automatically logins into his/her container. It is absolutely seamless for users. 

Authentication is based on ssh-key and key forwarding. SSH-key authentication and key-forwarding for the server must be enabled on the user side. 

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


## Files


### cleanuser.sh

Removes user on the server and removes users's containers.



### createuser.sh

Creates user on the server and creates user's container, set up the server and container for automatic user login to container with SSH key. 

#### Arguments:
	user name
	public key file
	Docker image
	
#### Requires:
	sshpass
	jq



### docker.sh

Is called every time Docker user logs in with SSH to server.
docker.sh starts user's container if it is stopped.
Creates SSH connection from server to container.

It must be placed in the server root directory. 

### container.sh

This file is called on every SSH connection to a container. It counts SSH connections and stops the container if there are no active connactions and the container is not in “nostop” mode. 

### dockerwatch.sh

Called by container.sh and stop.sh to stop container in due time - when all active SSH connections to the container are closed.


### nostop.sh

Enabling “nostop” mode. This command is to be called inside a container to prevent it from stopping when there are no active SSH connectinos.


### stop.sh

Command is to be called inside a container to tur off “nostop” mode: to set the container to be stopped after all SSH sessions are closed.


### stopnow.sh

Command is to be run inside a container to stop the container immediately.



