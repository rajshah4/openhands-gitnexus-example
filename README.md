# OpenHands + GitNexus Example

This repository is a practical example for people who want to use
[GitNexus](https://github.com/abhigyanpatwari/GitNexus) with
[OpenHands Agent Canvas](https://github.com/OpenHands/agent-canvas).

It shows a small integration pattern:

- index a local repository with GitNexus
- connect GitNexus to an existing OpenHands Agent Canvas through MCP
- ask OpenHands to use graph-backed repo context before broad manual search

The repository is intentionally small. It contains a worked VS Code / Code OSS
example and an optional OpenHands hook example. It is not a fork of GitNexus,
OpenHands, or VS Code.

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

1. Use an existing OpenHands Agent Canvas instance.
2. Index a local repository with GitNexus.
3. Add GitNexus as a custom MCP server.
4. Ask OpenHands to use GitNexus before broad manual search.
5. Walk through a VS Code example that compares plain search with GitNexus.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `README.md` | Overview and setup. |
| `.openhands/` | Optional OpenHands hook example. |
| `examples/` | Worked examples, including VS Code / Code OSS. |

Local notes, personal environment files, cloned repositories, and scratch
outputs belong in ignored paths such as `.local/`, `.env`, and
`example-projects/`.

## Prerequisites

- Node.js `22.12.x` or newer
- `npm` / `npx`
- `git`
- OpenHands Agent Canvas backed by OpenHands `1.31.0` or newer
- an LLM configured in Agent Canvas

Optional tools:

- `rg` / ripgrep for the plain-text search comparison

## Quick Start

Use an existing Agent Canvas instance. This repository does not install or
launch Agent Canvas; it assumes you already have OpenHands running with an LLM
configured.

This example uses [microsoft/vscode](https://github.com/microsoft/vscode) as
the benchmark repository. VS Code / Code OSS is a large TypeScript and Electron
codebase with command routing, extension activation, localization, workbench
services, tests, and shared platform utilities, which makes it a useful target
for graph-backed repo intelligence.

Clone VS Code / Code OSS, or point `VSCODE_REPO_DIR` at an existing checkout:

```bash
export VSCODE_REPO_DIR=../example-projects/vscode-benchmark-repo
export GITNEXUS_REPO_ALIAS=vscode-benchmark-repo

mkdir -p ../example-projects
git clone --depth 1 https://github.com/microsoft/vscode.git \
  "$VSCODE_REPO_DIR"
```

Index the repository with GitNexus:

```bash
npx -y gitnexus@latest analyze "$VSCODE_REPO_DIR" \
  --name "$GITNEXUS_REPO_ALIAS" \
  --skip-embeddings \
  --skills
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

At that point, start prompting OpenHands to use GitNexus MCP before broad manual
search. The VS Code example below gives concrete prompts and expected results.

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

## Worked Example: VS Code

See [examples/vscode.md](examples/vscode.md) for the full setup and query
walkthrough.

The example shows how to:

- index a local VS Code / Code OSS checkout as `vscode-benchmark-repo`
- configure GitNexus as an OpenHands MCP server
- compare plain text search with a GitNexus graph-backed query
- inspect `CommandService.executeCommand` with symbol context
- run blast-radius analysis on `localize`

The plain-text side of the comparison is just ripgrep:

```bash
rg -n -i --fixed-strings \
  "extension activation command registration execute command" \
  "$VSCODE_REPO_DIR"
```

The GitNexus side asks for a ranked repo-intelligence result:

```bash
npx -y gitnexus@latest query -r "$GITNEXUS_REPO_ALIAS" \
  "extension activation command registration execute command"
```

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
