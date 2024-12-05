FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        wget \
        git \
        cron \
        supervisor \
        jq \
        sudo \
        libicu-dev \
    # && mkdir -p /etc/supervisor/conf.d/ \
    && rm -rf /var/lib/apt/lists/*
        
# WORKDIR /app

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # echo "runner:runner" | chpasswd && \
    # mkdir /app/actions-runner && \
    usermod -aG sudo runner && \
    usermod -aG crontab runner
    # chown -R runner:runner /app

ENV HOME=/home/runner

WORKDIR ${HOME}

USER runner

RUN mkdir actions-runner && cd actions-runner && \
# Download the latest runner package
curl -o actions-runner-linux-x64-2.320.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz && \
# Optional: Validate the hash
echo "93ac1b7ce743ee85b5d386f5c1787385ef07b3d7c728ff66ce0d3813d5f46900  actions-runner-linux-x64-2.320.0.tar.gz" | shasum -a 256 -c && \
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.320.0.tar.gz

ENV RUNNER_MANAGER_DIR=${HOME}/Runner_Manager_Scripts

COPY --chown=runner:runner Runner_Manager_Scripts ${RUNNER_MANAGER_DIR}

ENTRYPOINT [ "Runner_Manager_Scripts/entrypoint.sh" ]