Docker-based Infrastructure as a Service Tools (DIAAS)

# Tools for creating a basic Infrastructure as a Service

## General Installation Procedure

### Ubuntu

##### Install Docker

Follow instructions here: https://docs.docker.com/installation/ubuntulinux/

##### Install DIAAS on server

```
git clone https://github.com/pyotr777/dockerIaaSTools.git
cd dockerIaaSTools/
sudo ./install.sh
```

##### Create DIAAS user on server

Copy ssh public key to DIAAS directory.
Create user with:
```
sudo ./createuser.sh <username> <docker image name> <public ssh key> 
```
##### Installation on local computer

For logging to your container running under DIAAS on a remote server you need only ssh on your local computer.
For mounting local directories into remote containers you also need connect.sh file and running sshd server on local computer.


##### Delete user
```
sudo ./cleanuser <username>
```

## Uninstall
```
sudo ./uninstall.sh
```