FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        wget \
        git \
        jq \
        unzip \
        libicu-dev

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    && usermod -aG docker ubuntu

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install
        
WORKDIR /app

RUN mkdir /app/actions-runner && \
    chown -R ubuntu:ubuntu /app

USER ubuntu

RUN cd actions-runner && \
    # Download the latest runner package
    curl -o actions-runner-linux-x64-2.320.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.320.0/actions-runner-linux-x64-2.320.0.tar.gz && \
    # Optional: Validate the hash
    echo "93ac1b7ce743ee85b5d386f5c1787385ef07b3d7c728ff66ce0d3813d5f46900  actions-runner-linux-x64-2.320.0.tar.gz" | shasum -a 256 -c && \
    # Extract the installer
    tar xzf ./actions-runner-linux-x64-2.320.0.tar.gz

COPY entrypoint.sh entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]