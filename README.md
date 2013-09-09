## GitLab CI is an open-source continuous integration server

[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner.png)](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner)

![Screen](https://github.com/downloads/gitlabhq/gitlab-ci/gitlab_ci_preview.png)

## This is Runner repository. This code will only run tests. For more information and the test coordinator please see the gitlab-ci repo.

### Requirements

**The project is designed for the Linux operating system.**

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux


### Installation

First we need to compile ruby. Install dev packages:

    sudo apt-get install -y wget curl gcc checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev


Then download Ruby and compile it:

    mkdir /tmp/ruby && cd /tmp/ruby
    curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz | tar xz
    cd ruby-1.9.3-p392
    ./configure
    make
    sudo make install

Now continue.

```bash
# Get code
git clone https://github.com/gitlabhq/gitlab-ci-runner.git

# Enter code dir
cd gitlab-ci-runner

# Install dependencies

# a) Linux
sudo apt-get install libicu-dev

# b) MacOSx (make sure you have brew installed)
sudo brew install icu4c

gem install bundler
bundle install

# Install runner in interactive mode
bundle exec ./bin/install

# SSH into your GitLab server and confirm to add host key to known_hosts
ssh git@<your gitlab url>
```

### Run

```bash
bundle exec ./bin/runner
```

### Autostart Runners

On linux machines you can have your runners operate like daemons with the following steps

```
# make sure you install any system dependancies first

administrator@server:~$ sudo adduser --disabled-login --gecos 'GitLab CI Runner' gitlab_ci_runner
administrator@server:~$ sudo su gitlab_ci_runner
gitlab_ci_runner@server:/home/administrator$ cd ~/

# perform the setup above

gitlab_ci_runner@server:~$ exit;
gitlab_ci_runner@server:/home/gitlab_ci_runner$ sudo cp ./gitlab-ci-runner/lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
gitlab_ci_runner@server:/home/gitlab_ci_runner$ cd ~
administrator@server:~$ sudo chmod +x /etc/init.d/gitlab-ci-runner
administrator@server:~$ sudo update-rc.d gitlab-ci-runner defaults 21 
administrator@server:~$ sudo service gitlab-ci-runner start
```


