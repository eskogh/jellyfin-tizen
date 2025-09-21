# syntax=docker/dockerfile:1.7
FROM debian:stable-slim

LABEL maintainer="erik@skogh.org" \
      org.opencontainers.image.source="https://github.com/eskogh/jellyfin-tizen"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Tizen Studio 4.5.1 requires Java 8; Jellyfin web builds work fine with Node 18 LTS.
# We also install required build tooling.
RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        unzip \
        zip \
        xz-utils \
        openssl \
        gpg \
        openjdk-8-jdk \
        python3 \
        python3-venv \
        python3-pip \
        bash \
        procps \
        dumb-init; \
    rm -rf /var/lib/apt/lists/*

# Node 18 (LTS) via NodeSource
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" > /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    rm -rf /var/lib/apt/lists/*; \
    corepack enable || true

# Non-root user
RUN useradd -rm -d /home/jellyfin -s /bin/bash -u 1001 jellyfin
USER jellyfin
WORKDIR /home/jellyfin

# Paths
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PATH="/home/jellyfin/tizen-studio/tools/ide/bin:/home/jellyfin/tizen-studio/tools:/home/jellyfin/.local/bin:${PATH}"

# Fetch sources
RUN set -eux; \
    mkdir -p /jellyfin; \
    git clone --depth=1 https://github.com/jellyfin/jellyfin-web.git /jellyfin/jellyfin-web; \
    git clone --depth=1 https://github.com/jellyfin/jellyfin-tizen.git /jellyfin/jellyfin-tizen

# Install web deps (build-time). jellyfin-web uses npm/yarn; npm ci preferred.
WORKDIR /jellyfin/jellyfin-web
RUN set -eux; \
    npm ci --no-audit --loglevel=error; \
    npx browserslist@latest --update-db || true

# Install tizen app deps (yarn)
WORKDIR /jellyfin/jellyfin-tizen
RUN set -eux; \
    corepack yarn install --immutable || yarn install

# Install Tizen Studio CLI (web-cli)
WORKDIR /home/jellyfin
RUN set -eux; \
    mkdir -p /home/jellyfin/.tizen-download; \
    cd /home/jellyfin/.tizen-download; \
    wget -q https://download.tizen.org/sdk/Installer/tizen-studio_4.5.1/web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin; \
    chmod +x web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin; \
    ./web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin --accept-license /home/jellyfin/tizen-studio; \
    rm -f web-cli_Tizen_Studio_4.5.1_ubuntu-64.bin

# Prepare directories
RUN set -eux; \
    mkdir -p /home/jellyfin/.config /home/jellyfin/.cache; \
    mkdir -p /home/jellyfin/tizen-studio-data/keystore/author; \
    mkdir -p /home/jellyfin/tizen-studio-data/profile

# Copy helper scripts
USER root
COPY bin/tizen-cert.sh /usr/local/bin/tizen-cert
COPY bin/tizen-build.sh /usr/local/bin/tizen-build
COPY bin/tizen-send.sh  /usr/local/bin/tizen-send
COPY bin/tizen-jellyfin /usr/local/bin/tizen-jellyfin
RUN chmod +x /usr/local/bin/tizen-* && chown jellyfin:jellyfin /usr/local/bin/tizen-*

USER jellyfin
WORKDIR /jellyfin/jellyfin-tizen

# Default command shows usage
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/tizen-jellyfin", "--help"]
