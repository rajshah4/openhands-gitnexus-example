#!/usr/bin/env sh
set -eu

event_json="$(cat)"
project_dir="${OPENHANDS_PROJECT_DIR:-.}"
log_file="$project_dir/.openhands/gitnexus-hook-events.log"

{
  printf '%s\n' '---'
  date -u '+%Y-%m-%dT%H:%M:%SZ'
  printf '%s\n' "$event_json"
} >> "$log_file"

printf '%s\n' '{"decision":"allow","reason":"GitNexus OpenHands hook example allowed the prompt.","additionalContext":"OpenHands loaded a UserPromptSubmit hook from .openhands/hooks.json for this workspace. A GitNexus-aware hook could call GitNexus for repo-scale hints, symbol context, or blast-radius context before the agent starts reading files."}'
