#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Container user matches the host user (see Dockerfile / build script).
AGENT_USER="$(id -un)"
AGENT_HOME="/home/$AGENT_USER"

# Ensure .claude.json exists as a file so the bind mount below doesn't
# get auto-created by Docker as a directory.
[ -e "$SCRIPT_DIR/.claude.json" ] || echo '{}' > "$SCRIPT_DIR/.claude.json"

# Mount the project at the SAME absolute path inside the container, and
# set the working dir to the host's current dir, so paths match the host.
# Resolve symlinks (realpath): Docker rejects bind-mount sources whose path
# components are symlinks ("mkdir ...: file exists").
PROJECT_ROOT="$(realpath "${PROJECT_ROOT:-$(pwd)}")"
WORKDIR="$(realpath "$(pwd)")"

docker run -it --rm \
  --entrypoint claude \
  -v "$PROJECT_ROOT:$PROJECT_ROOT:rslave" \
  -v "$SCRIPT_DIR/.claude:$AGENT_HOME/.claude" \
  -v "$SCRIPT_DIR/.claude.json:$AGENT_HOME/.claude.json" \
  -w "$WORKDIR" \
  $CLAUDE_DOCKER_OPTIONS \
  claude-code-agent \
  "$@"
