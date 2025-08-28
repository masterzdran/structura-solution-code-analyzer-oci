FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Create non-root user
RUN useradd -m devuser

USER root
WORKDIR /home/devuser/workspace

# Install core development tools, Node.js 20, npm, and common Python/Node tools for testing
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    docker.io \
    dotnet-sdk-8.0 \
    git \
    gnupg \
    lsb-release \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    unzip \
    wget \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir pylint bandit coverage pytest \
    && npm install -g eslint jest \
    # Install Docker Buildx for BuildKit support
    && mkdir -p ~/.docker/cli-plugins \
    && curl -sSL https://github.com/docker/buildx/releases/latest/download/buildx-linux-amd64 -o ~/.docker/cli-plugins/docker-buildx \
    && chmod +x ~/.docker/cli-plugins/docker-buildx

# Add devuser to docker group for Docker socket access
RUN usermod -aG docker devuser

# Set PATH for dotnet tools (for both root and devuser)
ENV PATH="$PATH:/root/.dotnet/tools:/home/devuser/.dotnet/tools"

USER devuser
WORKDIR /home/devuser/workspace
