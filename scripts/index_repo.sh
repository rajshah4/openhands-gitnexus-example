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
REPO_PATH="$(resolve_path "${1:-${TARGET_REPO_DIR:-$VSCODE_REPO_DIR}}")"
REPO_ALIAS="${2:-${GITNEXUS_REPO_ALIAS:-vscode-benchmark-repo}}"

export GITNEXUS_SKIP_OPTIONAL_GRAMMARS="${GITNEXUS_SKIP_OPTIONAL_GRAMMARS:-1}"

if ! command -v npx >/dev/null 2>&1; then
  echo "Missing required command: npx"
  exit 1
fi

if [ ! -d "$REPO_PATH/.git" ]; then
  echo "Repository checkout not found:"
  echo "  $REPO_PATH"
  echo
  echo "Clone a repository first, or pass a repository path:"
  echo "  ./scripts/index_repo.sh /path/to/repo repo-alias"
  exit 1
fi

echo "Indexing repository with GitNexus:"
echo "  path:  $REPO_PATH"
echo "  alias: $REPO_ALIAS"

npx -y gitnexus@latest analyze "$REPO_PATH" \
  --name "$REPO_ALIAS" \
  --skip-embeddings \
  --skills

echo
echo "GitNexus indexing complete."
echo "In Agent Canvas, add a custom stdio MCP server:"
echo "  Name: gitnexus"
echo "  Command: npx"
echo "  Args:"
echo "    -y"
echo "    gitnexus@latest"
echo "    mcp"
