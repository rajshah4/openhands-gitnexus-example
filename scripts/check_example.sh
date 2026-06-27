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

missing=0

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf "ok   %-12s %s\n" "$name" "$(command -v "$name")"
  else
    printf "miss %-12s required\n" "$name"
    missing=1
  fi
}

echo "OpenHands + GitNexus example preflight"
echo

check_command git
check_command node
check_command npm
check_command uv
check_command npx

echo

if command -v node >/dev/null 2>&1; then
  node_version="$(node -p "process.versions.node")"
  if node -e "const [maj,min]=process.versions.node.split('.').map(Number); process.exit(maj > 22 || (maj === 22 && min >= 12) ? 0 : 1)"; then
    echo "ok   node version $node_version"
  else
    echo "warn node version $node_version is below 22.12.x"
  fi
fi

echo

agent_canvas_ready=0
sdk_ready=0
agent_canvas_indexed=0
sdk_indexed=0

if [ -d "$AGENT_CANVAS_DIR/.git" ]; then
  echo "ok   agent-canvas checkout: $AGENT_CANVAS_DIR"
  agent_canvas_ready=1
else
  echo "miss agent-canvas checkout: $AGENT_CANVAS_DIR"
fi

if [ -d "$SOFTWARE_AGENT_SDK_DIR/.git" ]; then
  echo "ok   software-agent-sdk checkout: $SOFTWARE_AGENT_SDK_DIR"
  sdk_ready=1
else
  echo "info software-agent-sdk checkout not found yet: $SOFTWARE_AGENT_SDK_DIR"
fi

if [ -d "$AGENT_CANVAS_DIR/.gitnexus" ]; then
  echo "ok   GitNexus index found for agent-canvas"
  agent_canvas_indexed=1
else
  echo "info GitNexus index not found for agent-canvas"
fi

if [ -d "$SOFTWARE_AGENT_SDK_DIR/.gitnexus" ]; then
  echo "ok   GitNexus index found for software-agent-sdk"
  sdk_indexed=1
else
  echo "info GitNexus index not found for software-agent-sdk"
fi

echo

if command -v lsof >/dev/null 2>&1; then
  if lsof -nP -iTCP:8000 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "info port 8000 is already in use, likely Agent Canvas or another local app"
  else
    echo "ok   port 8000 is free for Agent Canvas"
  fi

  if lsof -nP -iTCP:4747 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "info port 4747 is already in use, likely GitNexus serve"
  else
    echo "ok   port 4747 is free for optional GitNexus visual backend"
  fi
fi

echo

if [ "$missing" -ne 0 ]; then
  echo "Preflight found missing required commands."
  exit 1
fi

echo "Preflight complete."
if [ "$agent_canvas_ready" -eq 0 ] || [ "$sdk_ready" -eq 0 ]; then
  echo "Next: ./scripts/setup_example.sh"
elif [ "$agent_canvas_indexed" -eq 0 ] || [ "$sdk_indexed" -eq 0 ]; then
  echo "Next: ./scripts/index_repos.sh"
else
  echo "Next: ./scripts/start_agent_canvas.sh"
fi
