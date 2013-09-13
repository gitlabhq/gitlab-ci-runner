# gitlab-ci-runner

FROM ubuntu:12.04
MAINTAINER  Sytse Sijbrandij "sytse@gitlab.com"

# This script will start a runner in a docker container.
#
# First build the container and give a name to the resulting image:
# docker build -t dosire/gitlab-ci-runner github.com/dosire/gitlab-ci-runner
#
# Then set the environment variables and run the gitlab-ci-runner in the container:
# docker run -e=[CI_SERVER_URL=https://ci.example.com,RUNNER_TOKEN=replaceme,HOME=/root] dosire/gitlab-runner

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

# When the image is started unstall the runner and run it.
WORKDIR /gitlab-ci-runner
CMD bundle exec ./bin/install_and_run
