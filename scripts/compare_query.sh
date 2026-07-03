#!/usr/bin/env bash
set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$EXAMPLE_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$EXAMPLE_ROOT/.env"
  set +a
fi

REPO_ALIAS="${1:-${GITNEXUS_REPO_ALIAS:-vscode-benchmark-repo}}"
REPO_PATH="${2:-${VSCODE_REPO_DIR:-}}"
QUERY="${3:-extension activation command registration execute command}"

if [ -z "$REPO_PATH" ]; then
  echo "Usage: $0 <gitnexus-repo-alias> <repo-path> [query]"
  echo
  echo "Or set VSCODE_REPO_DIR in .env and run:"
  echo "  $0 vscode-benchmark-repo"
  exit 1
fi

if [ ! -d "$REPO_PATH" ]; then
  echo "Repository path not found: $REPO_PATH"
  exit 1
fi

echo "Query:"
echo "  $QUERY"
echo
echo "Plain text search:"
echo "  rg -n -i --fixed-strings \"$QUERY\" \"$REPO_PATH\""
echo

if rg -n -i --fixed-strings \
  --glob '!node_modules' \
  --glob '!dist' \
  --glob '!build' \
  --glob '!coverage' \
  "$QUERY" "$REPO_PATH" | head -12; then
  true
else
  echo "  no exact phrase matches"
fi

echo
echo "GitNexus query:"
echo "  npx -y gitnexus@latest query -r \"$REPO_ALIAS\" \"$QUERY\""
echo

NO_COLOR=1 npx -y gitnexus@latest query -r "$REPO_ALIAS" "$QUERY"
