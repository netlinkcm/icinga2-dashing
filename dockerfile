# Dockerfile for dashing icinga2 with icingaweb2
# https://github.com/netlink/dashing-icinga2

FROM debian:jessie

MAINTAINER Jean-Francis Ahanda

ENV DEBIAN_FRONTEND noninteractive
ENV ICINGA2_FEATURE_GRAPHITE false
ENV ICINGA2_FEATURE_GRAPHITE_HOST graphite
ENV ICINGA2_FEATURE_GRAPHITE_PORT 2003

RUN apt-get -qq update && \
  apt-get -qqy upgrade && \
  apt-get -qqy install --no-install-recommends bash sudo procps ca-certificates wget supervisor mysql-server mysql-client apache2 pwgen unzip php5-ldap ssmtp mailutils vim php5-curl

RUN wget --quiet -O - https://packages.icinga.org/icinga.key | apt-key add - && \
  echo "deb http://packages.icinga.org/debian icinga-jessie main" >> /etc/apt/sources.list && \
  apt-get -qq update && \
  apt-get -qqy install --no-install-recommends icinga2 icinga2-ido-mysql icinga-web nagios-plugins icingaweb2 icingacli && \
  apt-get clean

ADD content/ /

RUN chmod u+x /opt/supervisor/mysql_supervisor /opt/supervisor/icinga2_supervisor /opt/supervisor/apache2_supervisor /opt/run 

# Temporary hack to get icingaweb2 modules via git
RUN mkdir -p /etc/icingaweb2.dist/enabledModules && \
  wget --no-cookies "https://github.com/Icinga/icingaweb2/archive/v2.3.4.zip" -O /tmp/icingaweb2.zip && \
  unzip /tmp/icingaweb2.zip "icingaweb2-2.3.4/modules/doc/*" "icingaweb2-2.3.4/modules/monitoring/*" -d "/tmp/icingaweb2" && \
  cp -R /tmp/icingaweb2/icingaweb2-2.3.4/modules/monitoring /etc/icingaweb2.dist/modules/ && \
  cp -R  /tmp/icingaweb2/icingaweb2-2.3.4/modules/doc /etc/icingaweb2.dist/modules/ && \
  rm -rf /tmp/icingaweb2.zip /tmp/icingaweb2

# Icinga Director
RUN wget --no-cookies "https://github.com/Icinga/icingaweb2-module-director/archive/master.zip" -O /tmp/director.zip && \
  unzip /tmp/director.zip -d "/tmp/director" && \
  cp -R /tmp/director/icingaweb2-module-director-master/* /etc/icingaweb2.dist/modules/director/ && \
  rm -rf /tmp/director.zip /tmp/director && \
  cp -R /etc/icingaweb2/* /etc/icingaweb2.dist/ && \
  cp -R /etc/icinga-web/* /etc/icinga-web.dist/ && \
  cp -R /etc/icinga2 /etc/icinga2.dist

EXPOSE 80 443 5665

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

# Prep for node install
Run apt-get install g++ curl libssl-dev apache2-utils -y
RUN apt-get install git-core -y

# Install Node
RUN git clone git://github.com/ry/node.git
RUN cd node;./configure;make;sudo make install

# Install Dashing
RUN gem install dashing
    
# Create a default dashboard
RUN dashing new mydashboard
RUN cd mydashboard;bundle

# Launch the dashboard
CMD cd /mydashboard;dashing start

# Initialize and run Supervisor
ENTRYPOINT ["/opt/run"]
