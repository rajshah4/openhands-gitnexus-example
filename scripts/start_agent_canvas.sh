#!/usr/bin/env bash
set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$EXAMPLE_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$EXAMPLE_ROOT/.env"
  set +a
fi
AGENT_CANVAS_PACKAGE="${AGENT_CANVAS_PACKAGE:-@openhands/agent-canvas@latest}"
OH_AGENT_SERVER_VERSION="${OH_AGENT_SERVER_VERSION:-1.31.0}"

if ! command -v npx >/dev/null 2>&1; then
  echo "Missing required command: npx"
  exit 1
fi

echo "Starting published Agent Canvas package through npx:"
echo "  $AGENT_CANVAS_PACKAGE"
echo "OpenHands Agent Server version:"
echo "  $OH_AGENT_SERVER_VERSION"
echo "UI: http://localhost:8000"
export OH_AGENT_SERVER_VERSION
exec npx -y "$AGENT_CANVAS_PACKAGE"
