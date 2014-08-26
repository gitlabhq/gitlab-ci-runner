# gitlab-ci-runner

FROM ubuntu:14.04
MAINTAINER  Sytse Sijbrandij "sytse@gitlab.com"

# This script will start a runner in a docker container.
#
# First build the container and give a name to the resulting image:
# docker build -t gitlabhq/gitlab-ci-runner github.com/gitlabhq/gitlab-ci-runner
#
# Then set the environment variables and run the gitlab-ci-runner in the container:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -e GITLAB_SERVER_FQDN=gitlab.example.com gitlabhq/gitlab-ci-runner
#
# After you start the runner you can send it to the background with ctrl-z
# The new runner should show up in the GitLab CI interface on /runners
#
# You can start an interactive session to test new commands with:
# docker run -e CI_SERVER_URL=https://ci.example.com -e REGISTRATION_TOKEN=replaceme -e HOME=/root -i -t gitlabhq/gitlab-ci-runner:latest /bin/bash
#
# If you ever want to freshly rebuild the runner please use:
# docker build -no-cache -t gitlabhq/gitlab-ci-runner github.com/gitlabhq/gitlab-ci-runner

# Get rid of the debconf messages
ENV DEBIAN_FRONTEND noninteractive

# Update your packages and install the ones that are needed to compile Ruby
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y curl libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libssl-dev patch build-essential zlib1g-dev openssh-server libyaml-dev libicu-dev

# Download Ruby and compile it
RUN mkdir /tmp/ruby
RUN cd /tmp/ruby && curl --silent ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p481.tar.gz | tar xz
RUN cd /tmp/ruby/ruby-2.0.0-p481 && ./configure --disable-install-rdoc && make install

RUN gem install bundler

# Set an utf-8 locale
RUN echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

# Prepare a known host file for non-interactive ssh connections
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/known_hosts

# Install the runner
RUN curl --silent -L https://gitlab.com/gitlab-org/gitlab-ci-runner/repository/archive.tar.gz | tar xz
RUN cd gitlab-ci-runner.git && bundle install --deployment

WORKDIR /gitlab-ci-runner.git

# When the image is started add the remote server key, set up the runner and run it
CMD ssh-keyscan -H $GITLAB_SERVER_FQDN >> /root/.ssh/known_hosts && bundle exec ./bin/setup_and_run

## Optional dependencies
##
## Install packages commonly required to test Rails projects before the test run starts
## If they are not here you have to add them to the test script in the project settings
#RUN apt-get install -y libqtwebkit-dev # test with capybara
#RUN apt-get install -y sqlite3 libsqlite3-dev # sqlite is the default datastore
#RUN apt-get install -y libmysqlclient-dev # native extensions for the mysql2 gem
#RUN apt-get install -q -y mysql-server # install MySQL with blank root password
#RUN cd /root && wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz && cd redis-stable && make
#
## Install PostgreSQL, after install this should work: psql --host=127.0.0.1 roottestdb
#RUN apt-get install -y postgresql
#RUN cat /dev/null > /etc/postgresql/9.3/main/pg_hba.conf
#RUN echo "# TYPE DATABASE USER ADDRESS METHOD" >> /etc/postgresql/9.3/main/pg_hba.conf
#RUN echo "local  all  all  trust" >> /etc/postgresql/9.3/main/pg_hba.conf
#RUN echo "host all all 127.0.0.1/32 trust" >> /etc/postgresql/9.3/main/pg_hba.conf
#RUN echo "host all all  ::1/128 trust" >> /etc/postgresql/9.3/main/pg_hba.conf
#RUN /etc/init.d/postgresql start && su postgres -c "psql -c \"create user root;\"" && su postgres -c "psql -c \"alter user root createdb;\"" && su postgres -c "psql -c \"create database roottestdb owner root;\""
#
## When the image is started add the remote server key, set up the runner and run it
#WORKDIR /gitlab-ci-runner.git
#
#CMD ssh-keyscan -H $GITLAB_SERVER_FQDN >> /root/.ssh/known_hosts && mysqld & /root/redis-stable/src/redis-server & /etc/init.d/postgresql start & bundle exec ./bin/setup_and_run
