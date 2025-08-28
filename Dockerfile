FROM ubuntu:22.04

LABEL version="0.1.0"
LABEL maintainer_name="Nuno Cancelo"
LABEL maintainer_email="masterzdran@gmail.com"
LABEL description="Secure DevOps analysis container"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="$PATH:/root/.dotnet/tools"

# Create users early
RUN useradd -m devuser && useradd -m analyzer

USER root

# Install curl first, then Docker Buildx
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils curl ca-certificates \
    && update-ca-certificates \
    && mkdir -p /root/.docker/cli-plugins/ \
    && curl -SL https://github.com/docker/buildx/releases/latest/download/buildx-linux-amd64 -o /root/.docker/cli-plugins/docker-buildx \
    && chmod +x /root/.docker/cli-plugins/docker-buildx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system dependencies, Node.js, and global npm packages
RUN apt-get update \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        dotnet-sdk-8.0 \
        git \
        gnupg \
        lsb-release \
        nodejs \
        openjdk-17-jdk \
        python3 \
        python3-pip \
        python3-venv \
        unzip \
        wget \
    && npm install -g npm@latest \
    && npm install -g eslint@latest jest@latest snyk@latest \
    && apt-get clean && rm -rf /var/lib/apt/lists/*



# Install Trivy
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/trivy.list \
    && apt-get update && apt-get install -y --no-install-recommends trivy \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Sonar Scanner
RUN wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip \
    && unzip sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt \
    && ln -s /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner \
    && rm sonar-scanner-cli-5.0.1.3006-linux.zip

# Install dotnet tools
RUN dotnet tool install --global dotnet-format \
    && dotnet tool install --global dotnet-reportgenerator-globaltool

# Install CodeQL
RUN wget -q https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip \
    && unzip codeql-linux64.zip -d /opt/codeql \
    && ln -s /opt/codeql/codeql /usr/local/bin/codeql \
    && rm codeql-linux64.zip

# Install DependencyCheck
RUN wget -q https://github.com/jeremylong/DependencyCheck/releases/download/v12.1.0/dependency-check-12.1.0-release.zip \
    && unzip dependency-check-12.1.0-release.zip -d /opt/dependency-check \
    && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check.sh \
    && rm dependency-check-12.1.0-release.zip

# Add devuser to docker group and set permissions
RUN groupadd -f docker \
    && usermod -aG docker devuser \
    && [ ! -e /var/run/docker.sock ] || chown root:docker /var/run/docker.sock \
    && [ ! -e /var/run/docker.sock ] || chmod 660 /var/run/docker.sock

# Install gitleaks and cloc
RUN curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64 -o /usr/local/bin/gitleaks \
    && chmod +x /usr/local/bin/gitleaks \
    && curl -sSL https://github.com/AlDanial/cloc/releases/latest/download/cloc-1.98.pl -o /usr/local/bin/cloc \
    && chmod +x /usr/local/bin/cloc

# Copy scripts and configs
COPY analyze.sh /usr/local/bin/analyze.sh
COPY .analisys-tools.yaml /usr/local/etc/.analisys-tools.yaml
RUN chmod +x /usr/local/bin/analyze.sh

# Install semgrep via pip (safer than curl | bash)
RUN pip install --no-cache-dir semgrep

USER devuser
