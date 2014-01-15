## GitLab CI Runner

This is GitLab CI **Runner** repository, this application run tests but it doesn't coordinate the testing. In the [GitLab CI repo](https://gitlab.com/gitlab-org/gitlab-ci) you can find the open-source continuous integration server that coordinates the testing.

[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner.png)](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner)

### Requirements

**This project is designed for the Linux operating system.**

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux

Mac OSX and other POSIX operating systems are not supported but will work with adaptations.

Under Windows the runner will only work under POSIX compliant environments like Cygwin.

To run GitLab CI we recommend using GitLab 6.0 or higher, for LDAP login this is required.

### Installation

Install operating system dependent dependencies:

a) Linux

    sudo apt-get update -y
    sudo apt-get install -y wget curl gcc libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev

b) MacOSX (make sure you have [homebrew](http://brew.sh/) installed)

    sudo brew install icu4c

Install Ruby from source:

a) Linux

    mkdir /tmp/ruby && cd /tmp/ruby
    curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz | tar xz
    cd ruby-2.0.0-p353
    ./configure --disable-install-rdoc
    make
    sudo make install

b) Mac OS X (make sure you have the Xcode command line tools installed), UNTESTED

    brew update
    brew install rbenv
    brew install ruby-build
    brew install openssl
    CC=gcc-4.7 RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-gcc=gcc-4.7 --enable-shared" rbenv install 2.0.0-p353
    echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.profile
    rbenv global 2.0.0-p353

Download the code for the runner:

    # Use any directory you like
    mkdir ~/gitlab-runners
    cd ~/gitlab-runners
    git clone https://gitlab.com/gitlab-org/gitlab-ci-runner.git
    cd gitlab-ci-runner

Install the gems for the runner:

    gem install bundler
    bundle install

Setup the runner interactively:

    bundle exec ./bin/setup

Setup the runner non-interactively:

    CI_SERVER_URL=https://ci.example.com REGISTRATION_TOKEN=replaceme bundle exec ./bin/setup

SSH into your GitLab server and confirm to add host key to known_hosts:

    ssh git@<your gitlab url>

### Run

```bash
bundle exec ./bin/runner
```

### Autostart Runners

On Linux machines you can have your runners operate like daemons with the following steps

```
# make sure you install any system dependancies first

administrator@server:~$ sudo adduser --disabled-login --gecos 'GitLab CI Runner' gitlab_ci_runner
administrator@server:~$ sudo su gitlab_ci_runner
gitlab_ci_runner@server:/home/administrator$ cd ~/

# perform the setup above

gitlab_ci_runner@server:~$ exit;
administrator@server:~$ cd /home/gitlab_ci_runner/gitlab-runners
administrator@server:~$ sudo ln -s ./gitlab-ci-runner/lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
administrator@server:~$ sudo update-rc.d gitlab-ci-runner defaults 21
administrator@server:~$ sudo service gitlab-ci-runner start
```


### Update

In order to update runner to vew version just go to runner directory and do next:

    git fetch
    git checkout VERSION_YOU_NEED # Ex. v4.0.0
    bundle

And restart runner
