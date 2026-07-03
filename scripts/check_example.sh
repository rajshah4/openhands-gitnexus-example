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

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$EXAMPLE_ROOT/$1" ;;
  esac
}

PROJECTS_DIR="$(resolve_path "${PROJECTS_DIR:-$WORKSPACE_ROOT/example-projects}")"
VSCODE_REPO_DIR="$(resolve_path "${VSCODE_REPO_DIR:-$PROJECTS_DIR/vscode-benchmark-repo}")"
GITNEXUS_REPO_ALIAS="${GITNEXUS_REPO_ALIAS:-vscode-benchmark-repo}"
AGENT_CANVAS_PACKAGE="${AGENT_CANVAS_PACKAGE:-@openhands/agent-canvas@latest}"
OH_AGENT_SERVER_VERSION="${OH_AGENT_SERVER_VERSION:-1.31.0}"
agent_canvas_running=0

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
check_command jq
check_command curl
check_command rg

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

echo "ok   agent-canvas published package path: npx $AGENT_CANVAS_PACKAGE"
echo "ok   openhands-agent-server version: $OH_AGENT_SERVER_VERSION"

if [ -d "$VSCODE_REPO_DIR/.git" ]; then
  echo "ok   VS Code example checkout: $VSCODE_REPO_DIR"
else
  echo "info VS Code example checkout not found yet: $VSCODE_REPO_DIR"
fi

if [ -d "$VSCODE_REPO_DIR/.gitnexus" ]; then
  echo "ok   GitNexus index found for $GITNEXUS_REPO_ALIAS"
else
  echo "info GitNexus index not found for $GITNEXUS_REPO_ALIAS"
fi

echo

if command -v lsof >/dev/null 2>&1; then
  if lsof -nP -iTCP:8000 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "info port 8000 is already in use, likely Agent Canvas or another local app"
    agent_canvas_running=1
  else
    echo "ok   port 8000 is free for Agent Canvas"
  fi
fi

echo

if [ "$missing" -ne 0 ]; then
  echo "Preflight found missing required commands."
  exit 1
fi

echo "Preflight complete."
if [ ! -d "$VSCODE_REPO_DIR/.git" ]; then
  echo "Next: ./scripts/setup_example.sh"
elif [ ! -d "$VSCODE_REPO_DIR/.gitnexus" ]; then
  echo "Next: ./scripts/index_repos.sh"
elif [ "$agent_canvas_running" -eq 1 ]; then
  echo "Next: ./scripts/test_gitnexus_mcp.sh"
else
  echo "Next: ./scripts/start_agent_canvas.sh"
fi
