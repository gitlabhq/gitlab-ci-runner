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

### Install dependencies

Install operating system dependent dependencies:

a) Linux

```bash
sudo apt-get update -y
sudo apt-get install -y wget curl gcc libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev make build-essential zlib1g-dev openssh-server git-core libyaml-dev postfix libpq-dev libicu-dev
```

b) MacOSX (make sure you have [homebrew](http://brew.sh/) installed)

```bash
sudo brew install icu4c
```

Install Ruby from source:

a) Linux

```bash
mkdir /tmp/ruby && cd /tmp/ruby
curl --progress ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz | tar xz
cd ruby-2.0.0-p353
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

Create the CI runner user and clone the gitlab-ci-runner repository:

```
sudo gem install bundler
sudo adduser --disabled-login --gecos 'GitLab CI Runner' gitlab_ci_runner
sudo su gitlab_ci_runner
cd ~/
git clone https://gitlab.com/gitlab-org/gitlab-ci-runner.git
cd gitlab-ci-runner
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

SSH into your GitLab server and confirm to add host key to known_hosts:

```bash
ssh git@<your gitlab url>
```

Place the init.d file:

```
exit;
cd /home/gitlab_ci_runner/gitlab-ci-runner
sudo cp ./lib/support/init.d/gitlab_ci_runner /etc/init.d/gitlab-ci-runner
sudo chmod +x /etc/init.d/gitlab-ci-runner
sudo update-rc.d gitlab-ci-runner defaults 21 
```


### Run

Using the system service with init.d script:

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

### Update

In order to update the runner to a new version just go to runner directory and do next: 

```bash
sudo su gitlab_ci_runner
cd ~/gitlab-ci-runner
git fetch
git checkout VERSION_YOU_NEED # Ex. v4.0.0
bundle
```

And restart runner

## Easily add Runners to existing GitLab CI

GitLab.com uses GitLab-CI to test our own builds. To quickly spin up some extra runners in time of need, we have setup a runner as described above, with all the relevant dependencies for our builds and have taken a snapshot of this runner.

To quickly add a runner, have the registration token at hand and:

- instantiate a new VPS with the snapshot `ci-gitlab-org-runner`
- `bundle exec ./bin/setup`
- `sudo service gitlab-ci-runner start`

Now the runner will start to pick up builds automatically. When you are done with it, you can destroy the VPS without worrying about anything. For testing GitLab itself, use of a runner with >= 2GB RAM is recommended.
