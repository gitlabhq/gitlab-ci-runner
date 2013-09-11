# gitlab-ci-runner

FROM ubuntu:12.04
MAINTAINER  Sytse Sijbrandij "sytse@gitlab.com"
ORIGINAL    weisjohn "weis.john@gmail.com"

# Update your packages and install the ones that are needed to compile Ruby

RUN apt-get update -y
RUN apt-get install -y wget curl gcc libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev

# Download Ruby and compile it

RUN mkdir /tmp/ruby && cd /tmp/ruby && curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz | tar xz
RUN cd /tmp/ruby/ruby-1.9.3-p392 && ./configure && make && make install

# Install the runner

RUN git clone https://github.com/dosire/gitlab-ci-runner.git /gitlab-ci-runner

## Install the gems for the runner

RUN cd /gitlab-ci-runner && gem install bundler && bundle install

# Install the runner

ENV HOME /root
RUN cd /gitlab-ci-runner && bundle exec ./bin/install MY_GITLAB_URL MY_RUNNER_TOKEN

# setup ssh (deprecated)
## sub-optimal... it seems that ssh-keygen doesn't honor $HOME
## mkdir for .ssh keys in the base director
#  run         mkdir /.ssh
## modify ssh config to use the appropriate key 
#  run         echo "\nIdentityFile /.ssh/id_rsa" >> /etc/ssh/ssh_config


## the default command to be run when this docker image is started
cmd         /gitlab-ci-runner/bin/runner
