FROM peter/ssh
EXPOSE 22
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8
RUN apt-get install -y ssh
RUN mkdir -p /var/run/sshd
#ENV DEBIAN_FRONTEND dialog

RUN mkdir /root/.ssh
ADD docker_rsa.pub /root/.ssh/authorized_keys
ADD service/ /usr/local/bin/

RUN echo 0 > /tmp/dockeriaas_cc
RUN printf "timeout:2\n" > /tmp/dockeriaas_conf
RUN mkdir /logs

# Disable password login
# RUN sed -r -i "s/^.*PasswordAuthentication[yesno ]+$/PasswordAuthentication no/" /etc/ssh/sshd_config

RUN printf "\nForceCommand /usr/local/bin/container.sh" >> /etc/ssh/sshd_config
ENV DEBIAN_FRONTEND dialog
CMD ["/usr/sbin/sshd","-D"]
