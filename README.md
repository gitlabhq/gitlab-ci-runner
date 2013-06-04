## GitLab CI is an open-source continuous integration server

[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner.png)](https://codeclimate.com/github/gitlabhq/gitlab-ci-runner)

![Screen](https://github.com/downloads/gitlabhq/gitlab-ci/gitlab_ci_preview.png)

## This is Runner repository. This code responsible for running tests

### Requirements

**The project is designed for the Linux operating system.**

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux


### Installation

```bash
# Get code
git clone https://github.com/gitlabhq/gitlab-ci-runner.git

# Enter code dir
cd gitlab-ci-runner

# Install dependencies
bundle install

# Install runner in interactive mode
./bin/install
```

### Run

```bash
./bin/runner
```
