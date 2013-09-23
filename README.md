## GitLab CI is an open-source continuous integration server

[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner.png)](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner)

![Screen](https://github.com/downloads/gitlabhq/gitlab-ci/gitlab_ci_preview.png)

## This is Runner repository. This code will only run tests. For more information and the test coordinator please see the [gitlab-ci repo](https://github.com/gitlabhq/gitlab-ci).

### Requirements

**The project is designed for the Linux operating system.**

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux

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

    mkdir /tmp/ruby
    cd /tmp/ruby
    curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz | tar xz
    cd ruby-1.9.3-p392
    ./configure
    make
    sudo make install

b) MacOSX (make sure you have the Xcode command line tools installed), UNTESTED

    brew update
    brew install rbenv
    brew install ruby-build
    brew install openssl
    CC=gcc-4.7 RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-gcc=gcc-4.7 --enable-shared" rbenv install 1.9.3-p392
    echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.profile
    rbenv global 1.9.3-p194

Install the runner:

    mkdir /tmp/runner
    cd /tmp/ruby
    git clone https://github.com/gitlabhq/gitlab-ci-runner.git
    cd gitlab-ci-runner

Install the gems for the runner:

    gem install bundler
    bundle install

Install the runner interactively:

    bundle exec ./bin/install

Install the runner non-interactively:

    CI_SERVER_URL=https://ci.example.com REGISTRATION_TOKEN=replaceme bundle exec ./bin/install

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
gitlab_ci_runner@server:/home/gitlab_ci_runner$ sudo cp ./gitlab-ci-runner/lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
gitlab_ci_runner@server:/home/gitlab_ci_runner$ cd ~
administrator@server:~$ sudo chmod +x /etc/init.d/gitlab-ci-runner
administrator@server:~$ sudo update-rc.d gitlab-ci-runner defaults 21 
administrator@server:~$ sudo service gitlab-ci-runner start
```


