FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies, ripgrep, and Node.js (required for Claude Code)
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ripgrep \
    git \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Match the container user to the host user so image-built files
# and bind-mounted files share an owner without runtime chown.
# These have no defaults — the build script must pass the host user's
# name/UID/GID (see claude-docker-build-image.sh).
ARG AGENT_USER
ARG AGENT_UID
ARG AGENT_GID

# Create the host user and group at the host's UID/GID.
# Ubuntu 24.04 ships a stock 'ubuntu' user/group at 1000:1000 — remove it first.
# Pre-create the dirs the installer writes to, owned by the user.
RUN userdel -r ubuntu 2>/dev/null; groupdel ubuntu 2>/dev/null; \
    groupadd -g $AGENT_GID $AGENT_USER && \
    useradd -m -u $AGENT_UID -g $AGENT_GID -s /bin/bash $AGENT_USER && \
    mkdir -p /home/$AGENT_USER/.claude /home/$AGENT_USER/.local && \
    chown -R $AGENT_UID:$AGENT_GID /home/$AGENT_USER

# Use the named user (not numeric) so $HOME=/home/$AGENT_USER during the install
USER $AGENT_USER

# Install Claude Code CLI (download then run so a failed download fails the build)
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install.sh && bash /tmp/install.sh && rm /tmp/install.sh

# Add Claude to PATH (literal path so it survives into runtime without the ARG)
ENV PATH="/home/$AGENT_USER/.local/bin:$PATH"

WORKDIR /home/$AGENT_USER

# Persist Claude Code settings in a volume
VOLUME ["/home/$AGENT_USER/.claude", "/home/$AGENT_USER/.claude.json"]

# Keep container running indefinitely
ENTRYPOINT ["sleep", "infinity"]
