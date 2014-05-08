# Update Runner from v4 to v5

## 1. Stop runner

    sudo service gitlab-ci-runner stop

## 2. Get recent code

    sudo su gitlab_ci_runner
    cd ~/gitlab-ci-runner
    git fetch origin
    git checkout 5-0-stable
    bundle install --deployment

## 3. Start Runner

    sudo service gitlab-ci-runner start