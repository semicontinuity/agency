#!/usr/bin/env bash
###
# Runs claude code in docker
###
#
# Env vars (optional)
#
# AGENT_SANDBOX_DEBUG    Do not run claude, but bash (for debugging)
# AGENT_SANDBOX_PATH     Extra PATH entries for claude (:-separated)
# AGENT_SANDBOX_MOUNTS   Extra folders to mount (space-separated) (same in container and in host)
# AGENT_SANDBOX_VOLUMES  Extra folders to mount (space-separated)
###

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

if [[ -n $AGENT_SANDBOX_DEBUG ]]; then
  ENTRYPOINT=bash
  set --
else
  ENTRYPOINT=claude
fi

# Extra volumes: AGENT_SANDBOX_VOLUMES is a newline- or space-separated list;
# pass each item with -v.
EXTRA_VOLUMES=()

for vol in $AGENT_SANDBOX_VOLUMES; do
  EXTRA_VOLUMES+=(-v "$vol")
done
for mnt in $AGENT_SANDBOX_MOUNTS; do
  EXTRA_VOLUMES+=(-v "$mnt:$mnt")
done

# Extra env vars: AGENT_SANDBOX_ENV_VARS is a newline- or space-separated list;
# pass each item with -e.
EXTRA_ENV_VARS=()
for env_var in $AGENT_SANDBOX_ENV_VARS; do
  EXTRA_ENV_VARS+=(-e "$env_var")
done

if [[ -n $AGENT_SANDBOX_PATH ]]; then
  AGENT_SANDBOX_PATH="$AGENT_SANDBOX_PATH:"
fi
AGENT_SANDBOX_PATH="$AGENT_SANDBOX_PATH$AGENT_HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$AGENT_HOME/integration/bin"

docker run -it --rm \
  --entrypoint "$ENTRYPOINT" \
  --group-add $(getent group docker | cut -d: -f3) \
  -v "$PROJECT_ROOT:$PROJECT_ROOT:rslave" \
  -v "$SCRIPT_DIR/integration:$AGENT_HOME/integration"   \
  -v "$AGENT_HOME/.claude-ext:$AGENT_HOME/.claude-ext"   \
  -v "$SCRIPT_DIR/.claude:$AGENT_HOME/.claude"           \
  -v "$SCRIPT_DIR/.claude.json:$AGENT_HOME/.claude.json" \
  -v /var/run/docker.sock:/var/run/docker.sock           \
  "${EXTRA_VOLUMES[@]}"                                  \
  "${EXTRA_ENV_VARS[@]}"                                 \
  -e "PATH=$AGENT_SANDBOX_PATH"                          \
  -w "$WORKDIR"                                          \
  $CLAUDE_DOCKER_OPTIONS                                 \
  claude-code-agent                                      \
  "$@"
