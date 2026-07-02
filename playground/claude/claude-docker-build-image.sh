#!/usr/bin/env bash
###
# Build the claude-code-agent image, passing host user/UID/GID and docker GID
# as build args (consumed by the Dockerfile's ARGs). Run before claude-docker.sh.
###
docker build -t claude-code-agent \
  --build-arg AGENT_USER="$(id -un)" \
  --build-arg AGENT_UID="$(id -u)" \
  --build-arg AGENT_GID="$(id -g)" \
  --build-arg DOCKER_GID="$(getent group docker | cut -d: -f3)" \
  .
