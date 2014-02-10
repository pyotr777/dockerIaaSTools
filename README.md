# Docker containers as a service tools

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
Executes user's commands in the container.



### dockerwatch.sh

Called by docker.sh to stop container in due time.



### nostop.sh

Command to be run inside a container to prevent dockerwatch from stopping the container.



### stop.sh

Command to be run inside a container to set the container to be stopped after ssh session is closed.


### stopnow.sh

Command to be run inside a container to stop the container immediately.


## Scheme

![Scheme](dockerservice.pdf)
