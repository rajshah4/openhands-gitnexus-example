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
AGENT_CANVAS_DIR="${AGENT_CANVAS_DIR:-$WORKSPACE_ROOT/openhands-agent-canvas}"
USE_SOURCE="${USE_SOURCE:-0}"
AGENT_CANVAS_PACKAGE="${AGENT_CANVAS_PACKAGE:-@openhands/agent-canvas@latest}"
OH_AGENT_SERVER_VERSION="${OH_AGENT_SERVER_VERSION:-1.31.0}"

if [ "$USE_SOURCE" = "1" ]; then
  if [ ! -d "$AGENT_CANVAS_DIR" ]; then
    echo "Agent Canvas checkout not found: $AGENT_CANVAS_DIR"
    echo "Run ./scripts/setup_example.sh first."
    exit 1
  fi

  if [ ! -d "$AGENT_CANVAS_DIR/node_modules" ]; then
    echo "Agent Canvas source dependencies are not installed."
    echo "Run: INSTALL_AGENT_CANVAS_DEPS=1 ./scripts/setup_example.sh"
    exit 1
  fi

  echo "Starting Agent Canvas from local source checkout."
  echo "UI: http://localhost:8000"
  cd "$AGENT_CANVAS_DIR"
  exec npm run dev
fi

echo "Starting published Agent Canvas package through npx:"
echo "  $AGENT_CANVAS_PACKAGE"
echo "OpenHands Agent Server version:"
echo "  $OH_AGENT_SERVER_VERSION"
echo "UI: http://localhost:8000"
export OH_AGENT_SERVER_VERSION
exec npx -y "$AGENT_CANVAS_PACKAGE"
