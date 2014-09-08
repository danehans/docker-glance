# Glance
# VERSION               0.0.1
# Tested on RHEL7 and OSP5 (i.e. Icehouse)

FROM      systemd_rhel7
MAINTAINER Daneyon Hansen "daneyonhansen@gmail.com"

WORKDIR /root

# Uses Cisco Internal Mirror. Follow the OSP 5 Repo documentation if you are using subscription manager.
RUN curl --url http://173.39.232.144/repo/redhat.repo --output /etc/yum.repos.d/redhat.repo
RUN yum -y update; yum clean all

# Required Utilities
RUN yum -y install openssl ntp wget

# Glance
RUN yum -y install openstack-glance
RUN mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.save
RUN mv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.save
RUN mv /etc/glance/glance-cache.conf /etc/glance/glance-cache.conf.save
RUN mv /etc/glance/glance-scrubber.conf /etc/glance/glance-scrubber.conf.save
ADD glance-api.conf /etc/glance/
ADD glance-registry.conf /etc/glance/
ADD glance-cache.conf /etc/glance/
ADD glance-scrubber.conf /etc/glance/
RUN chown glance:glance /etc/glance/glance-api.conf
RUN chown glance:glance /etc/glance/glance-registry.conf
RUN chown glance:glance /etc/glance/glance-cache.conf
RUN chown root:glance /etc/glance/glance-scrubber.conf
RUN touch /var/log/glance/api.log
RUN chown glance:glance /var/log/glance/api.log
RUN touch /var/log/glance/registry.log
RUN chown glance:glance /var/log/glance/registry.log
RUN systemctl enable openstack-glance-api
RUN systemctl enable openstack-glance-registry

# Initialize the Glance MySQL DB
RUN glance-manage db_sync

# Expose Glance TCP ports
EXPOSE 9191 9292 

CMD ["/usr/sbin/init"]
