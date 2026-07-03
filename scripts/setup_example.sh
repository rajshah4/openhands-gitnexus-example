#!/usr/bin/env bash
set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$EXAMPLE_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$EXAMPLE_ROOT/.env"
  set +a
fi
WORKSPACE_ROOT="$(cd "$EXAMPLE_ROOT/.." && pwd)"
PROJECTS_DIR="${PROJECTS_DIR:-$WORKSPACE_ROOT/example-projects}"
AGENT_CANVAS_DIR="${AGENT_CANVAS_DIR:-$WORKSPACE_ROOT/openhands-agent-canvas}"
SOFTWARE_AGENT_SDK_DIR="${SOFTWARE_AGENT_SDK_DIR:-$PROJECTS_DIR/software-agent-sdk}"
INSTALL_AGENT_CANVAS_DEPS="${INSTALL_AGENT_CANVAS_DEPS:-0}"
USE_SOURCE="${USE_SOURCE:-0}"

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name"
    exit 1
  fi
}

require_command git
require_command node
require_command npm
require_command uv

mkdir -p "$PROJECTS_DIR"

if [ "$USE_SOURCE" = "1" ]; then
  if [ -d "$AGENT_CANVAS_DIR/.git" ]; then
    echo "Using existing Agent Canvas checkout:"
    echo "  $AGENT_CANVAS_DIR"
  else
    echo "Cloning OpenHands/agent-canvas into:"
    echo "  $AGENT_CANVAS_DIR"
    git clone --depth 1 https://github.com/OpenHands/agent-canvas.git "$AGENT_CANVAS_DIR"
  fi
else
  echo "Skipping Agent Canvas source checkout. The default start path uses the"
  echo "published @openhands/agent-canvas package through npx."
fi

if [ -d "$SOFTWARE_AGENT_SDK_DIR/.git" ]; then
  echo "Using existing software-agent-sdk checkout:"
  echo "  $SOFTWARE_AGENT_SDK_DIR"
else
  echo "Cloning OpenHands/software-agent-sdk into:"
  echo "  $SOFTWARE_AGENT_SDK_DIR"
  git clone --depth 1 https://github.com/OpenHands/software-agent-sdk.git "$SOFTWARE_AGENT_SDK_DIR"
fi

if [ "$USE_SOURCE" = "1" ] && [ "$INSTALL_AGENT_CANVAS_DEPS" = "1" ]; then
  echo "Installing Agent Canvas dependencies from source checkout..."
  npm install --prefix "$AGENT_CANVAS_DIR"
elif [ "$USE_SOURCE" = "1" ]; then
  echo "Skipping npm install. Set INSTALL_AGENT_CANVAS_DEPS=1 to install source dependencies."
else
  echo "No source dependencies needed for the published package path."
fi

echo
echo "Setup complete."
echo "Next:"
echo "  ./scripts/index_repos.sh"
echo "  ./scripts/start_agent_canvas.sh"
