docker-glance
===========

0.0.1 - 2014.1.2-1 - Icehouse

Overview
--------

Run OpenStack Glance in a Docker container.


Caveats
-------

The systemd_rhel7 base image used by the Glance container is a private image.
Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893)
to create your base rhel7 image. Then enable systemd within the rhel7 base image.
Use [Running SystemD within a Docker Container](http://rhatdan.wordpress.com/2014/04/30/running-systemd-within-a-docker-container/) to enable SystemD.

The container does not setup Keystone endpoints for Glance. This is a task the Keystone service is responsible for.

Although the container does initialize the database used by Glance, it does not create the database, permissions, etc.. These are responsibilities of the database service. Follow the steps in the [official insallation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-install.html) for these steps.

The container only includes OpenStack clients that get installed as a dependency of the Glance packages. After the Glance container is running, issues Glance commands from a host running the python-glanceclient.

Installation
------------

This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed.

### From Github

Clone the Github repo and change to the project directory:
```
yum install -y git
git clone https://github.com/danehans/docker-glance.git
cd docker-glance
```
Edit the Glance .conf files according to your deployment needs then build the Glance image. Reference the official OpenStack [installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-install.html) for help configuring the .conf files. Next, build the Docker Glance image.
```
docker build -t glance .
```
The image should now appear in your image list:
```
# docker images
REPOSITORY  TAG     IMAGE ID            CREATED             VIRTUAL SIZE
glance      latest  d8509075ad38        58 minutes ago      540.7 MB
```
Run the Glance container. The example below uses the -h flag to configure the hostame as glance within the container, exposes TCP ports 9191 and 9292 on the Docker host, names the container glance, uses -d to run the container as a daemon.
```
docker run --privileged -d -h glance -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-p 9191:9191 -p 9292:9292 --name="glance" glance
```
**Note:** SystemD requires CAP_SYS_ADMIN capability and access to the cgroup file system within a container. Therefore, --privileged and -v /sys/fs/cgroup:/sys/fs/cgroup:ro are required flags.

Verification
------------

Verify your Glance container is running:
```
# docker ps
CONTAINER ID  IMAGE           COMMAND                CREATED             STATUS              PORTS                                            NAMES
6065b523c107  glance:latest   /usr/sbin/init         48 minutes ago      Up 48 minutes       0.0.0.0:9191->9191/tcp, 0.0.0.0:9292->9292/tcp   glance
```
Access the shell of your container:
```
# docker inspect --format='{{.State.Pid}}' glance
```
The command above will provide a process ID of the Glance container that is used in the following command:
```
# nsenter -m -u -n -i -p -t <PROCESS_ID> /bin/bash
bash-4.2#
```
From here you can perform limited functions such as viewing the installed RPMs, the glance.conf file, etc..

Follow the OpenStack [official installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-verify.html) to verify the proper operation of the Glance image service.

Troubleshooting
---------------

Can you connect to the OpenStack API endpints from your Docker host and container? Verify connectivity with tools such as ping and curl.

IPtables may be blocking you. Check IPtables rules on the host(s) running the other OpenStack services:
```
iptables -L
```
To change iptables rules:
```
vi /etc/sysconfig/iptables
systemctl restart iptables.service
```
