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

export GITNEXUS_SKIP_OPTIONAL_GRAMMARS="${GITNEXUS_SKIP_OPTIONAL_GRAMMARS:-1}"

require_repo() {
  local path="$1"
  if [ ! -d "$path/.git" ]; then
    echo "Missing repo checkout: $path"
    echo "Run ./scripts/setup_example.sh first."
    exit 1
  fi
}

require_repo "$AGENT_CANVAS_DIR"
require_repo "$SOFTWARE_AGENT_SDK_DIR"

index_repo() {
  local path="$1"
  local name="$2"
  echo
  echo "Indexing $name with GitNexus:"
  echo "  $path"
  npx -y gitnexus@latest analyze "$path" --skip-embeddings --skills
}

index_repo "$AGENT_CANVAS_DIR" "OpenHands Agent Canvas"
index_repo "$SOFTWARE_AGENT_SDK_DIR" "OpenHands software-agent-sdk"

echo
echo "GitNexus indexing complete."
echo "In Agent Canvas, add a custom stdio MCP server:"
echo "  Name: gitnexus"
echo "  Command: npx"
echo "  Args:"
echo "    -y"
echo "    gitnexus@latest"
echo "    mcp"
