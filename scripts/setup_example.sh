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
VSCODE_REMOTE_URL="${VSCODE_REMOTE_URL:-https://github.com/microsoft/vscode.git}"
VSCODE_CLONE_DEPTH="${VSCODE_CLONE_DEPTH:-1}"

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name"
    exit 1
  fi
}

require_command git

mkdir -p "$(dirname "$VSCODE_REPO_DIR")"

if [ -d "$VSCODE_REPO_DIR/.git" ]; then
  echo "Using existing VS Code / Code OSS checkout:"
  echo "  $VSCODE_REPO_DIR"
elif [ -e "$VSCODE_REPO_DIR" ]; then
  echo "Path exists but is not a git checkout:"
  echo "  $VSCODE_REPO_DIR"
  echo
  echo "Set VSCODE_REPO_DIR in .env to an existing repository, or remove the path and rerun."
  exit 1
else
  echo "Cloning VS Code / Code OSS into:"
  echo "  $VSCODE_REPO_DIR"
  git clone --depth "$VSCODE_CLONE_DEPTH" "$VSCODE_REMOTE_URL" "$VSCODE_REPO_DIR"
fi

echo
echo "Setup complete."
echo "Next:"
echo "  ./scripts/check_example.sh"
echo "  ./scripts/index_repos.sh"
echo "  ./scripts/start_agent_canvas.sh"
