#!/usr/bin/env bash
set -euo pipefail

EXAMPLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$EXAMPLE_ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$EXAMPLE_ROOT/.env"
  set +a
fi

AGENT_CANVAS_URL="${AGENT_CANVAS_URL:-http://127.0.0.1:8000}"
AGENT_CANVAS_STATE_DIR="${AGENT_CANVAS_STATE_DIR:-$HOME/.openhands/agent-canvas}"
GITNEXUS_SKIP_OPTIONAL_GRAMMARS="${GITNEXUS_SKIP_OPTIONAL_GRAMMARS:-1}"
GITNEXUS_REPO_ALIAS="${GITNEXUS_REPO_ALIAS:-vscode-benchmark-repo}"

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

read_api_key() {
  if [ -f "$AGENT_CANVAS_STATE_DIR/api-key.txt" ]; then
    cat "$AGENT_CANVAS_STATE_DIR/api-key.txt"
    return
  fi

  if [ -f "$AGENT_CANVAS_STATE_DIR/session-api-key.txt" ]; then
    cat "$AGENT_CANVAS_STATE_DIR/session-api-key.txt"
    return
  fi

  echo "Could not find Agent Canvas API key in $AGENT_CANVAS_STATE_DIR" >&2
  exit 1
}

json_block() {
  awk '/^---$/ { exit } { print }'
}

post_mcp_test() {
  local tool_call_json="$1"

  jq -n \
    --arg skipOptional "$GITNEXUS_SKIP_OPTIONAL_GRAMMARS" \
    --argjson toolCall "$tool_call_json" \
    '{
      name: "gitnexus",
      server: {
        type: "stdio",
        command: "npx",
        args: ["-y", "gitnexus@latest", "mcp"],
        env: {
          GITNEXUS_SKIP_OPTIONAL_GRAMMARS: $skipOptional
        }
      },
      timeout: 60
    } + (if $toolCall == null then {} else {tool_call: $toolCall} end)' |
    curl -fsS -X POST "$AGENT_CANVAS_URL/api/mcp/test" \
      -H "X-Session-API-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      --data-binary @-
}

require_command curl
require_command jq
require_command npx

API_KEY="$(read_api_key)"

echo "OpenHands + GitNexus MCP smoke test"
echo

server_info="$(curl -fsS "$AGENT_CANVAS_URL/server_info")"
echo "ok   Agent Canvas: $AGENT_CANVAS_URL"
echo "ok   OpenHands version: $(jq -r '.version' <<<"$server_info")"

tools_response="$(post_mcp_test 'null')"
if ! jq -e '.ok == true' >/dev/null <<<"$tools_response"; then
  echo "MCP tool discovery failed:" >&2
  jq '.' <<<"$tools_response" >&2
  exit 1
fi
echo "ok   GitNexus tools: $(jq -r '.tools | join(", ")' <<<"$tools_response")"

repos_response="$(post_mcp_test '{"name":"list_repos","arguments":{}}')"
repos_json="$(jq -r '.tool_result.text' <<<"$repos_response" | json_block)"
repo_count="$(jq -r '.repositories | length' <<<"$repos_json")"
if [ "$repo_count" -eq 0 ]; then
  echo "No GitNexus repositories found. Index a repo first." >&2
  exit 1
fi
jq -r '.repositories[] | "ok   repo: \(.name) files=\(.stats.files) nodes=\(.stats.nodes) edges=\(.stats.edges)"' <<<"$repos_json"

context_call="$(
  jq -n --arg repo "$GITNEXUS_REPO_ALIAS" '{
    name: "context",
    arguments: {
      repo: $repo,
      name: "executeCommand",
      kind: "Method",
      file_path: "src/vs/workbench/services/commands/common/commandService.ts"
    }
  }'
)"
context_response="$(post_mcp_test "$context_call")"
context_json="$(jq -r '.tool_result.text' <<<"$context_response" | json_block)"
jq -r '"ok   context: \(.symbol.kind) \(.symbol.uid) lines \(.symbol.startLine)-\(.symbol.endLine)"' <<<"$context_json"

impact_call="$(
  jq -n --arg repo "$GITNEXUS_REPO_ALIAS" '{
    name: "impact",
    arguments: {
      repo: $repo,
      target: "localize",
      kind: "Function",
      file_path: "src/vs/nls.ts",
      direction: "upstream",
      maxDepth: 2,
      summaryOnly: true
    }
  }'
)"
impact_response="$(post_mcp_test "$impact_call")"
impact_json="$(jq -r '.tool_result.text' <<<"$impact_response" | json_block)"
jq -r '"ok   impact: risk=\(.risk) impacted=\(.impactedCount) direct=\(.summary.direct) modules=\(.summary.modules_affected)"' <<<"$impact_json"

echo
echo "Smoke test complete."
