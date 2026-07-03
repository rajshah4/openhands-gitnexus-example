#!/usr/bin/env bash
set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$EXAMPLE_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$EXAMPLE_ROOT/.env"
  set +a
fi

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$EXAMPLE_ROOT/$1" ;;
  esac
}

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

REPO_PATH="$(resolve_path "$REPO_PATH")"

if [ ! -d "$REPO_PATH" ]; then
  echo "Repository path not found: $REPO_PATH"
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "Missing required command: rg"
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "Missing required command: npx"
  exit 1
fi

echo "Query:"
echo "  $QUERY"
echo
echo "Plain text search:"
echo "  rg -n -i --fixed-strings \"$QUERY\" \"$REPO_PATH\""
echo

matches_file="$(mktemp)"
trap 'rm -f "$matches_file"' EXIT

if rg -n -i --fixed-strings \
  --glob '!node_modules' \
  --glob '!dist' \
  --glob '!build' \
  --glob '!coverage' \
  "$QUERY" "$REPO_PATH" >"$matches_file"; then
  sed -n '1,12p' "$matches_file"
  total_matches="$(wc -l <"$matches_file" | tr -d ' ')"
  if [ "$total_matches" -gt 12 ]; then
    echo "  ... $((total_matches - 12)) more exact phrase matches"
  fi
else
  echo "  no exact phrase matches"
fi

echo
echo "GitNexus query:"
echo "  npx -y gitnexus@latest query -r \"$REPO_ALIAS\" \"$QUERY\""
echo

NO_COLOR=1 npx -y gitnexus@latest query -r "$REPO_ALIAS" "$QUERY"
