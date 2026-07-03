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
VSCODE_REPO_DIR="${VSCODE_REPO_DIR:-}"
GITNEXUS_REPO_ALIAS="${GITNEXUS_REPO_ALIAS:-vscode-benchmark-repo}"

export GITNEXUS_SKIP_OPTIONAL_GRAMMARS="${GITNEXUS_SKIP_OPTIONAL_GRAMMARS:-1}"

index_repo() {
  local path="$1"
  local name="$2"
  local alias="${3:-}"
  echo
  echo "Indexing $name with GitNexus:"
  echo "  $path"
  if [ -n "$alias" ]; then
    echo "  alias: $alias"
    npx -y gitnexus@latest analyze "$path" --name "$alias" --skip-embeddings --skills
  else
    npx -y gitnexus@latest analyze "$path" --skip-embeddings --skills
  fi
}

indexed=0

if [ -n "$VSCODE_REPO_DIR" ] && [ -d "$VSCODE_REPO_DIR/.git" ]; then
  index_repo "$VSCODE_REPO_DIR" "VS Code / Code OSS example" "$GITNEXUS_REPO_ALIAS"
  indexed=1
fi

if [ -d "$AGENT_CANVAS_DIR/.git" ]; then
  index_repo "$AGENT_CANVAS_DIR" "OpenHands Agent Canvas"
  indexed=1
fi

if [ -d "$SOFTWARE_AGENT_SDK_DIR/.git" ]; then
  index_repo "$SOFTWARE_AGENT_SDK_DIR" "OpenHands software-agent-sdk"
  indexed=1
fi

if [ "$indexed" = "0" ]; then
  echo "No configured repositories found to index."
  echo
  echo "For the VS Code example, set VSCODE_REPO_DIR in .env and run again."
  echo "For OpenHands reference repos, run ./scripts/setup_example.sh first."
  exit 1
fi

echo
echo "GitNexus indexing complete."
echo "In Agent Canvas, add a custom stdio MCP server:"
echo "  Name: gitnexus"
echo "  Command: npx"
echo "  Args:"
echo "    -y"
echo "    gitnexus@latest"
echo "    mcp"
