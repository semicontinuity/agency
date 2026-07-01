#!/usr/bin/env bash
docker build -t claude-code-agent \
  --build-arg AGENT_USER="$(id -un)" \
  --build-arg AGENT_UID="$(id -u)" \
  --build-arg AGENT_GID="$(id -g)" \
  --build-arg DOCKER_GID="$(getent group docker | cut -d: -f3)" \
  .
