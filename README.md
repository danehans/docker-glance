docker-glance
===========

0.0.1 - 2014.1.2-1 - Icehouse

Overview
--------

Run OpenStack Glance in a Docker container.


Introduction
------------
This guide assumes you have Docker installed on your host system. Use the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893] to install Docker on RHEL 7) to setup your Docker on your RHEL 7 host if needed. Reference the [Getting images from outside Docker registries](https://access.redhat.com/articles/881893#images) section to pull your base rhel7 image from Red Hat's private registry. This is required to build the rhel7-systemd base image used by the Glance container.

Make sure your Docker host has been configured with the required [OSP 5 channels and repositories](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/5/html/Installation_and_Configuration_Guide/chap-Prerequisites.html#sect-Software_Repository_Configuration)

After following the [Get Started with Docker Containers in RHEL 7](https://access.redhat.com/articles/881893) guide, verify your Docker Registry is running:
```
# systemctl status docker-registry
docker-registry.service - Registry server for Docker
   Loaded: loaded (/usr/lib/systemd/system/docker-registry.service; enabled)
   Active: active (running) since Mon 2014-05-05 13:42:56 EDT; 601ms ago
 Main PID: 21031 (gunicorn)
   CGroup: /system.slice/docker-registry.service
           ├─21031 /usr/bin/python /usr/bin/gunicorn --access-logfile - --debug ...
            ...
```
Now that you have the rhel7 base image, follow the instructions in the [docker-rhel7-systemd project](https://github.com/danehans/docker-rhel7-systemd/blob/master/README.md) to build your rhel7-systemd image.

The container does not setup Keystone endpoints for Glance. This is a task the Keystone service is responsible for. Reference the [docker-keystone](https://github.com/danehans/docker-keystone) project or official [OpenStack documentation](http://docs.openstack.org) for details.

Although the container does initialize the database used by Glance, it does not create the database, permissions, etc.. These are responsibilities of the database service.

Installation
------------

From your Docker Registry, set the environment variables used to automate the image building process.
```
Required. Name of the Github repo. Change danehans to your Github repo name if you forked this project. Otherwise set REPO_NAME to danehans.
```
export REPO_NAME=danehans
```
Required. The branch from the REPO_NAME repo. Unless you are using a different branch, set the REPO_BRANCH to master.
```
export REPO_BRANCH=master
```
Optional. Name of the Docker base image in your Docker Registry. This should be the image that includes systemd. Defaults to rhel7-systemd.
```
export BASE_IMAGE=ouruser/rhel7-systemd
```
Optional. Name to use for the Glance Docker image. Defaults to glance.
```
export IMAGE_NAME=ouruser/glance
```
Optional. The backend scheme Glance uses by default to store images. Defaults to file. Options include file and swift. **Note:** The swift option requires a function Swift cluster.
```
export DEFAULT_STORE="${DEFAULT_STORE:-file}"
```
Optional. The IP address/hostname to find the registry server. Defaults to 0.0.0.0
```
export REGISTRY_HOST="${REGISTRY_HOST:-0.0.0.0}"
```
Required. IP address/hostname of the Database server.
```
export DB_HOST=10.10.10.200
```
Optional. Password used to connect to the Glance database on the DB_HOST server. Defaults to changeme.
```
export DB_PASSWORD=changeme
```
Required. IP address/hostname of the RabbitMQ server.
```
export RABBIT_HOST=10.10.10.200
```
Required. IP address/hostname of the Keystone host. This address should resolve to the IP used by the Host and not the container.
```
export KEYSTONE_HOST=10.10.10.100
```
Optional. TCP Port used within the Keystone RC file to connect to the Keystone Public API. This should be the port that the Docoker host is listening on. Note: The Docker Registry listens on port 5000. Defaults to 5000
```
export KEYSTONE_PUBLIC_HOST_PORT=5001
```
Optional. TCP Port used within the Keystone RC file to connect to the Keystone Public API. This should be the port that the Docoker host is listening on. Note: The Docker Registry listens on port 35357. Defaults to 35357
```
export KEYSTONE_ADMIN_HOST_PORT=5001
```
Optional. The name and password of the service tenant within the Keystone service catalog. Defaults to service/changeme
```
export SERVICE_TENANT=services
export SERVICE_PASSWORD=changeme
```
Optional. Credentials used in the Keystone RC files. Defaults to changeme.
```
export ADMIN_USER_PASSWORD=changeme
export DEMO_USER_PASSWORD=changeme
```

Additional environment variables can be set as needed. You can reference the [build script](https://github.com/danehans/docker-glance/blob/master/data/scripts/build#L14-L68) to review all the available environment variables options and their default settings.

Refer to the OpenStack [Icehouse installation guide](http://docs.openstack.org/icehouse/install-guide/install/yum/content/glance-install.html) for more details on the configuration parameters.

Run the build script.
```
bash <(curl \-fsS https://raw.githubusercontent.com/$REPO_NAME/docker-glance/$REPO_BRANCH/data/scripts/build)
```
The image should now appear in your image list:
```
# docker images
REPOSITORY           TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
glance               latest              d75185a8e696        3 minutes ago       555 MB
```
Now you can run a Glance container from the newly created image. You can use the run script or run the container manually.

First, set your environment variables:
```
export IMAGE_NAME=ouruser/glance
export GLANCE_CONTAINER_NAME=glance
export GLANCE_HOSTNAME=glance.example.com
export DNS_SEARCH=example.com
```
Additional environment variables can be set as needed. You can reference the [run script](https://github.com/danehans/docker-glance/blob/master/data/scripts/run#L14-L24) to review all the available environment variables options and their default settings.


**Option 1-** Use the run script:
```
. $HOME/docker-glance/data/scripts/run
```
**Option 2-** Manually:
The example below uses the -h flag to configure the hostame as glance.example.com within the container, exposes TCP ports 9191 and 9292 on the Docker host, names the container glance, uses -d to run the container as a daemon.
```
# docker run --privileged -d -h $HOSTNAME --dns-search $DNS_SEARCH \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 9191:9191 -p 9292:9292 \
--name="$CONTAINER_NAME" $IMAGE_NAME
```
Example:
```
# docker run --privileged -d -h glance.example.com --dns-search example.com \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 9191:9191 -p 9292:9292 \
--name="glance" ouruser/glance
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

Deploy a Glance Image
---------------------

Source your Keystone credential file:
```
# For the admin user
source /root/admin-openrc.sh
# For the demo user
source /root/demo-openrc.sh
```
Download the Cirros image for testing:
```
# yum install -y wget
# wget http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
# glance image-create --name cirros --is-public=true --disk-format=qcow2 --container-format=ovf < cirros-0.3.1-x86_64-disk.img
```
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

Contributing
------------

If you require setting additional .conf configuration flags, please fork the docker-glance project, make your additions, test and submit a pull request to get your changes back upstream.

The [glance-api.conf](https://github.com/danehans/docker-glance/blob/master/data/tiller/templates/glance-api.conf.erb) file and [glance-registry.conf](https://github.com/danehans/docker-glance/blob/master/data/tiller/templates/glance-registry.conf.erb) is managed by a tool called [Tiller](https://github.com/markround/tiller/blob/master/README.md).
