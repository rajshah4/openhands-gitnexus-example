# OpenHands + GitNexus Example

This repository is a practical example for people who want to use
[GitNexus](https://github.com/abhigyanpatwari/GitNexus) with
[OpenHands Agent Canvas](https://github.com/OpenHands/agent-canvas).

It shows three integration patterns:

- connect GitNexus to OpenHands through MCP
- run GitNexus CLI commands that help an agent orient in a codebase
- optionally use an OpenHands workspace hook to inject repository context before
  an agent turn starts

The repository is intentionally small. It contains setup scripts, reusable
prompts, and notes for a large-repository scenario. It is not a fork of
GitNexus, OpenHands, or VS Code.

## Why This Is Useful

Coding agents can read files, run commands, and edit code. On a large or
unfamiliar repository, the first useful question is often:

```text
Where should the agent start?
```

Plain text search can find strings. GitNexus indexes code structure: symbols,
files, relationships, clusters, and impact paths. OpenHands can then use that
repository context while it inspects files, proposes changes, and runs
validation.

## What This Example Covers

1. Start OpenHands Agent Canvas locally.
2. Add GitNexus as a custom MCP server.
3. Index one or more local repositories with GitNexus.
4. Ask OpenHands to use GitNexus before broad manual search.
5. Compare plain text search with a GitNexus graph-backed query.
6. Optionally inspect the included OpenHands hook pattern.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `README.md` | Overview and setup. |
| `.env.example` | Local configuration template. |
| `.openhands/` | Optional OpenHands hook example. |
| `assets/` | Mermaid diagram source. |
| `prompts/` | Reusable OpenHands prompts that ask the agent to use GitNexus context. |
| `results/` | Place for sanitized, repeatable command outputs. |
| `scenarios/` | Scenario notes, including the large-repo navigation example. |
| `scripts/` | Setup, preflight, indexing, and startup helpers. |

Local notes, personal environment files, cloned repositories, and scratch
outputs belong in ignored paths such as `.local/`, `.env`, and
`example-projects/`.

## Prerequisites

- Node.js `22.12.x` or newer
- `npm` / `npx`
- `uv`
- `git`
- an OpenHands Agent Canvas setup with an LLM configured

## Quick Start

Copy the local configuration template:

```bash
cp .env.example .env
```

Check local prerequisites:

```bash
./scripts/check_example.sh
```

Clone or verify the reference OpenHands repositories:

```bash
./scripts/setup_example.sh
```

Index the repositories with GitNexus:

```bash
./scripts/index_repos.sh
```

Start Agent Canvas:

```bash
./scripts/start_agent_canvas.sh
```

Agent Canvas should be available at:

```text
http://localhost:8000
```

## Configure GitNexus MCP In Agent Canvas

In Agent Canvas:

1. Open **Customize**.
2. Open **MCP Servers**.
3. Click **Add custom**.
4. Choose **stdio**.
5. Use:

```text
Name: gitnexus
Command: npx
Arguments:
-y
gitnexus@latest
mcp
```

If the UI has a test action, run it and save the server.

## OpenHands MCP Compatibility Note

OpenHands MCP support depends on the `software-agent-sdk` version used by Agent
Canvas. If your installed OpenHands package predates the MCP argument alias fix,
GitNexus tools may appear during discovery but fail when a tool call sends
arguments whose MCP names differ from the SDK's internal field names.

If that happens, run Agent Canvas from a source checkout that includes the MCP
fix, or use the next published OpenHands package that includes it. Once your
OpenHands install includes that SDK change, the standard GitNexus MCP
configuration above should be enough.

## Prompt OpenHands To Use GitNexus

Use these prompts as starting points:

1. [Repo Orientation](prompts/01-repo-orientation.md)
2. [Blast Radius](prompts/02-blast-radius.md)
3. [Architecture Watch](prompts/03-architecture-watch.md)

They are written to work whether GitNexus MCP is available or not. When GitNexus
is available, the prompts ask OpenHands to use it before falling back to manual
file inspection.

## Large-Repo Query Comparison

The `scripts/compare_query.sh` helper compares plain repository text search
with a GitNexus graph-backed query.

To use the VS Code / Code OSS scenario, set `VSCODE_REPO_DIR` in `.env` to your
local checkout and make sure GitNexus has indexed it with the alias
`vscode-benchmark-repo`.

Run the comparison:

```bash
./scripts/compare_query.sh vscode-benchmark-repo "$VSCODE_REPO_DIR" \
  "extension activation command registration execute command"
```

In the local run this question produced:

- plain search: no exact phrase match, followed by loose token hits
- GitNexus: `CommandService.executeCommand` in
  `src/vs/workbench/services/commands/common/commandService.ts`

Follow-up GitNexus commands such as `context` and `impact` can then provide the
symbol neighborhood and likely blast radius before an agent edits code.

## Optional: OpenHands Hooks

This repository includes a small OpenHands hook example at `.openhands/hooks.json`.
It uses the `user_prompt_submit` event to add a short `additionalContext` note
before the agent turn starts.

The included hook does not call GitNexus directly. It is a minimal pattern that
can be adapted to run GitNexus CLI commands or other repository-context checks
before OpenHands begins a task.

## Secrets And Local State

Do not commit secrets or machine-specific state.

Use ignored local files or the OpenHands secret store for:

- LLM API keys
- GitHub tokens
- OpenHands API keys
- private MCP endpoints
- local repository paths

The tracked files should stay focused on helping someone understand and reuse
the OpenHands + GitNexus integration pattern.
