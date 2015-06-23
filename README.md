## GitLab Runner PROJECT IS DEPRECATED NOW, PLEASE USE NEW [GitLab CI Multu Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner) INSTEAD

## GitLab Runner

This is GitLab Runner repository, this application run tests and sends the results to GitLab CI.
[GitLab CI](https://about.gitlab.com/gitlab-ci) is the open-source continuous integration server that coordinates the testing.

[![build status](https://ci.gitlab.org/projects/8/status.png?ref=master)](https://ci.gitlab.org/projects/8?ref=master)
[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner.png)](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner)

### Requirements

### Omnibus packages and other platforms

The recommended way to install this runner are the Omnibus packages.
GitLab runners are also available for all kinds of other platforms such as Windows and OSX.
For more information about both please see the runner section of the [GitLab CI page on the website](https://about.gitlab.com/gitlab-ci/).

### Supported platforms

This projects officially support these Linux distributions:

- Ubuntu
- Debian
- CentOS
- Red Hat Enterprise Linux
- Scientific Linux
- Oracle Linux

Mac OSX and other POSIX operating systems are not supported but will work with adaptations.
Under Windows the runner will only work under POSIX compliant environments like Cygwin.
Also see the alternative Runners for Windows, Scala/Java and Node please see the runner section of the [GitLab CI page on the website](https://about.gitlab.com/gitlab-ci/).

### Install dependencies

The easiest and recommended way to install the runner is with the [GitLab Runner Omnibus package](https://gitlab.com/gitlab-org/omnibus-gitlab-runner/blob/master/doc/install/README.md).

Install operating system dependent dependencies:

a) Linux

```bash
sudo apt-get update -y
sudo apt-get install -y wget curl gcc libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev
```

b) MacOSX (make sure you have [homebrew](http://brew.sh/) installed)

```bash
brew install icu4c
```

Install Ruby from source:

a) Linux

```bash
mkdir /tmp/ruby && cd /tmp/ruby
curl --progress http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz | tar xz
cd ruby-2.1.5
./configure --disable-install-rdoc
make
sudo make install
```

b) Mac OS X (make sure you have the Xcode command line tools installed), UNTESTED

```bash
brew update
brew install rbenv
brew install ruby-build
brew install openssl
CC=gcc-4.7 RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-gcc=gcc-4.7 --enable-shared" rbenv install 2.0.0-p353
echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.profile
rbenv global 2.0.0-p353
```

### Setup runners

#### Create the runner user

Ubuntu:

```
sudo gem install bundler
sudo adduser --disabled-login --gecos 'GitLab Runner' gitlab_ci_runner
```

Centos:

```
sudo groupadd gitlab_ci_runner
sudo useradd -g gitlab_ci_runner gitlab_ci_runner
```

#### Clone the gitlab-ci-runner repository

```
sudo su gitlab_ci_runner
cd ~/
git clone https://gitlab.com/gitlab-org/gitlab-ci-runner.git
cd gitlab-ci-runner
git checkout VERSION_YOU_NEED # Ex. v5.0.0
```

Install the gems for the runner:

```
bundle install --deployment
```

Setup the runner interactively:

```
bundle exec ./bin/setup
```

OR

Setup the runner non-interactively:

```
CI_SERVER_URL=https://ci.example.com REGISTRATION_TOKEN=replaceme bundle exec ./bin/setup
```

The registration token can be found at: <http://gitlab-ci-domain.com/admin/runners>, accessible through Header > Runners.

By default the configuration file for your new runner gets written in the directory where the gitlab-ci-runner source code was installed, e.g. in `/home/gitlab_ci_runner/gitlab-ci-runner/config.yml`.
You can tell `bin/setup` to use a different directory with the `-C` switch.

```
bin/setup -C /my/runner/working/directory
```

You can also specify RUNNER_DESCRIPTION and RUNNER_TAG_LIST during setup.

To unlink the runner from the coordinator you can run following command:

```
bin/unlink
```

It will remove the runner's information from the coordinator and remove the given token from the current runner

#### Create an Upstart job (Ubuntu, Centos 6)

```
exit;
sudo cp /home/gitlab_ci_runner/gitlab-ci-runner/lib/support/upstart/gitlab-ci-runner.conf /etc/init/
```


#### Set up an init.d script (other distributions)

```
exit;
sudo cp /home/gitlab_ci_runner/gitlab-ci-runner/lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
sudo chmod +x /etc/init.d/gitlab-ci-runner
sudo update-rc.d gitlab-ci-runner defaults 21
```

### Runners default file

```
cd /home/gitlab_ci_runner/gitlab-ci-runner
sudo cp ./lib/support/init.d/gitlab_ci_runner.default.example /etc/default/gitlab_ci_runner
```

### Run

Using the system service with Upstart/init.d script:

```bash
sudo service gitlab-ci-runner start
```

OR

Manually:

```bash
sudo su gitlab_ci_runner
cd /home/gitlab_ci_runner/gitlab-ci-runner
bundle exec ./bin/runner
```

If you are using a custom working directory you can tell the runner about it with the `-C` switch.
The default working directory is the directory where the gitlab-ci-runner source code was installed, e.g. `/home/gitlab_ci_runner/gitlab-ci-runner`.

```
bundle exec bin/runner -C /my/runner/working/directory
```

### Update

In order to update the runner to a new version just go to runner directory and do next:

```bash
sudo su gitlab_ci_runner
cd ~/gitlab-ci-runner
git fetch
git checkout VERSION_YOU_NEED # Ex. v5.0.0
bundle
```

And restart runner

## Easily add Runners to existing GitLab CI

See [omnibus gitlab runner](https://gitlab.com/gitlab-org/omnibus-gitlab-runner/blob/master/doc/install/README.md).

## Development

To work on the GitLab runner we recommend you install the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
