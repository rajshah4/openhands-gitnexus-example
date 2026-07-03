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
prompts, and a worked VS Code / Code OSS example. It is not a fork of
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
3. Index a local repository with GitNexus.
4. Ask OpenHands to use GitNexus before broad manual search.
5. Walk through a VS Code example that compares plain search with GitNexus.
6. Optionally inspect the included OpenHands hook pattern.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `README.md` | Overview and setup. |
| `.env.example` | Local configuration template. |
| `.openhands/` | Optional OpenHands hook example. |
| `examples/` | Worked examples, including VS Code / Code OSS. |
| `prompts/` | Reusable OpenHands prompts that ask the agent to use GitNexus context. |
| `scripts/` | Setup, preflight, indexing, and startup helpers. |

Local notes, personal environment files, cloned repositories, and scratch
outputs belong in ignored paths such as `.local/`, `.env`, and
`example-projects/`.

## Prerequisites

- Node.js `22.12.x` or newer
- `npm` / `npx`
- `uv`
- `git`
- `curl`
- `jq`
- `rg` / ripgrep
- OpenHands Agent Canvas backed by OpenHands `1.31.0` or newer
- an LLM configured in Agent Canvas

## Quick Start

Copy the local configuration template:

```bash
cp .env.example .env
```

Check local prerequisites:

```bash
./scripts/check_example.sh
```

Prepare the VS Code / Code OSS checkout used by the worked example:

```bash
./scripts/setup_example.sh
```

If you already have a checkout, set `VSCODE_REPO_DIR` in `.env` to that path
instead.

Index the repository with GitNexus:

```bash
./scripts/index_repos.sh
```

Start Agent Canvas from the published package:

```bash
./scripts/start_agent_canvas.sh
```

The default Agent Canvas package is `@openhands/agent-canvas@latest`. The script
also sets `OH_AGENT_SERVER_VERSION=1.31.0` because the MCP compatibility fix
lives in the OpenHands Agent Server / SDK package. To pin either value, set
`AGENT_CANVAS_PACKAGE` or `OH_AGENT_SERVER_VERSION` in `.env`.

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

You can also smoke test the released OpenHands + GitNexus MCP path from this
repo after Agent Canvas is running:

```bash
./scripts/test_gitnexus_mcp.sh
```

The smoke test uses Agent Canvas' local MCP test endpoint. It verifies GitNexus
tool discovery, calls `context` with `kind: "Method"`, and calls `impact` with
`kind: "Function"` against the VS Code example.

## OpenHands MCP Compatibility Note

OpenHands MCP support depends on the `software-agent-sdk` version used by Agent
Canvas. Use OpenHands `1.31.0` or newer for GitNexus MCP tools whose schemas
include an argument named `kind`.

The `1.31.0` release includes the MCP argument alias fix from
[OpenHands/software-agent-sdk#3803](https://github.com/OpenHands/software-agent-sdk/pull/3803).
Without that fix, GitNexus tools can appear during discovery but fail when a
tool call sends a valid MCP argument named `kind`, because older OpenHands SDK
versions could collide with their internal discriminator field.

With OpenHands `1.31.0` or newer, the standard GitNexus MCP configuration above
should be enough.

## Prompt OpenHands To Use GitNexus

Use these prompts as starting points:

1. [Repo Orientation](prompts/01-repo-orientation.md)
2. [Blast Radius](prompts/02-blast-radius.md)
3. [Architecture Watch](prompts/03-architecture-watch.md)

They are written to work whether GitNexus MCP is available or not. When GitNexus
is available, the prompts ask OpenHands to use it before falling back to manual
file inspection.

## Worked Example: VS Code

See [examples/vscode.md](examples/vscode.md) for the full setup and query
walkthrough.

The example shows how to:

- index a local VS Code / Code OSS checkout as `vscode-benchmark-repo`
- configure GitNexus as an OpenHands MCP server
- compare plain text search with a GitNexus graph-backed query
- inspect `CommandService.executeCommand` with symbol context
- run blast-radius analysis on `localize`

The quick comparison helper is:

```bash
./scripts/compare_query.sh vscode-benchmark-repo "$VSCODE_REPO_DIR" \
  "extension activation command registration execute command"
```

To use the same helper on another repository, pass that repository's GitNexus
alias and local path.

In the local run this question produced:

- plain search: no exact phrase match, followed by loose token hits
- GitNexus: `CommandService.executeCommand` in
  `src/vs/workbench/services/commands/common/commandService.ts`

Follow-up GitNexus commands such as `context` and `impact` provide the symbol
neighborhood and likely blast radius before an agent edits code.

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
