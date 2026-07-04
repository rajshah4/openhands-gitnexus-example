# Example: OpenHands + GitNexus On VS Code

This page shows how this repository was used with a large local codebase. The
example target is [microsoft/vscode](https://github.com/microsoft/vscode), the
VS Code / Code OSS repository, indexed with GitNexus and queried from OpenHands
Agent Canvas through MCP.

VS Code is a large TypeScript and Electron codebase with command routing,
extension activation, localization, workbench services, tests, and shared
platform utilities. That makes it a useful benchmark for whether repo
intelligence can find structure instead of only matching text.

The point is not to prove that every query needs a graph. The point is to show
where a code graph helps an agent start from structure instead of guessing from
plain text matches.

## What We Set Up

The local run used:

- OpenHands Agent Canvas backed by OpenHands Agent Server `1.31.0`
- GitNexus as a custom stdio MCP server
- a local VS Code / Code OSS checkout
- GitNexus repo alias: `vscode-benchmark-repo`

The indexed VS Code checkout produced this scale in our local run:

```text
files: 11,454
nodes: 249,982
edges: 966,616
communities: 11,767
processes: 300
```

Those counts are useful in a video because they make the practical problem
clear: this is not a toy repo where an agent can safely browse a few files and
hope it landed in the right subsystem.

## Reproduce The Setup

Set these values in your terminal:

```bash
export VSCODE_REPO_DIR=../example-projects/vscode-benchmark-repo
export GITNEXUS_REPO_ALIAS=vscode-benchmark-repo
```

Use an existing VS Code / Code OSS checkout, or clone one into that path:

```bash
mkdir -p ../example-projects
git clone --depth 1 https://github.com/microsoft/vscode.git \
  "$VSCODE_REPO_DIR"
```

Index it with GitNexus:

```bash
npx -y gitnexus@latest analyze "$VSCODE_REPO_DIR" \
  --name "$GITNEXUS_REPO_ALIAS" \
  --skip-embeddings \
  --skills
```

Open your existing Agent Canvas instance. It should be backed by OpenHands
`1.31.0` or newer for the GitNexus MCP `kind` argument path.

For local Agent Canvas source checkouts whose default Agent Server pin is older,
start the stack with:

```bash
OH_AGENT_SERVER_VERSION=1.31.0 npm run dev
```

Then add GitNexus as a custom stdio MCP server in Agent Canvas:

```text
Name: gitnexus
Command: npx
Arguments:
-y
gitnexus@latest
mcp
```

If the Agent Canvas UI has a test action for MCP servers, run it and save the
server. A healthy setup should expose GitNexus tools such as:

```text
list_repos, query, context, impact, trace
```

## Query 1: Find A Starting Point

Ask OpenHands:

```text
Use GitNexus MCP on repo vscode-benchmark-repo. Query for:
"extension activation command registration execute command"

Return the top ranked symbol or file, then explain why it is a good starting
point for a coding agent.
```

Useful result from our run:

```text
CommandService.executeCommand
src/vs/workbench/services/commands/common/commandService.ts
```

Why it matters:

Plain search asks which files contain the words. GitNexus can return a ranked
code target that already matches the repository structure. OpenHands can then
open the right file first instead of spending the early turn sifting through
loose token hits.

To compare plain text search with GitNexus from this repo, run the plain search:

```bash
rg -n -i --fixed-strings \
  "extension activation command registration execute command" \
  "$VSCODE_REPO_DIR"
```

Then run the GitNexus query:

```bash
npx -y gitnexus@latest query -r "$GITNEXUS_REPO_ALIAS" \
  "extension activation command registration execute command"
```

The same pattern works for another local repository if you index that repository
with its own GitNexus alias.

In our local run, plain search had no exact phrase matches and fell back to
loose token hits. GitNexus returned the command-service entry point above.

## Query 2: Inspect Symbol Context

Ask OpenHands:

```text
Use GitNexus MCP on vscode-benchmark-repo. Get context for executeCommand, kind
Method, file_path
src/vs/workbench/services/commands/common/commandService.ts. Summarize the
outgoing calls, implemented interface, accessed fields, and any uncertainty or
boundary notes.
```

Useful result from our run:

```text
Symbol:
CommandService.executeCommand
src/vs/workbench/services/commands/common/commandService.ts
lines 51-89

Calls:
_activateStar
_tryExecuteCommand
ICommandRegistry.getCommand
raceCancellablePromises

Implements:
ICommandService.executeCommand

Accesses:
_extensionHostIsReady
_extensionService
_logService

Boundary:
executeCommand is an interface with 4 implementations, so callers that bind
through the interface may not all trace to this concrete symbol.
```

Why it matters:

This turns a search hit into an agent-ready map. Before editing, OpenHands can
see the nearby calls, fields, interface relationship, and static-analysis
boundary.

## Query 3: Check Blast Radius

Ask OpenHands:

```text
Use GitNexus MCP on vscode-benchmark-repo. Run impact for Function localize in
src/vs/nls.ts. Use upstream direction, maxDepth 2, summaryOnly true. Explain the
risk result and what an agent should do differently before editing this symbol.
```

Useful result from our run:

```text
Target: localize
File: src/vs/nls.ts
Risk: CRITICAL
Impacted count: 7,963
Direct impacts: 4,328
Depth 2 impacts: 3,635
Processes affected: 7
Modules affected: 20
```

Why it matters:

The agent learns that a tiny-looking helper is a shared dependency with a large
blast radius. That changes the plan: avoid broad API changes, preserve
compatibility, inspect call sites, and run wider validation.

## Query 4: Find Structurally Central Symbols

Ask OpenHands:

```text
Use GitNexus MCP on vscode-benchmark-repo. Run a graph query to find the top 10
symbols with the most incoming CALLS edges. Show symbol name, file path, and
caller count. Then explain why this is different from text search.
```

Representative result:

```text
localize   src/vs/nls.ts                       8,391 callers
add        src/vs/base/common/lifecycle.ts     6,317 callers
_register  src/vs/base/common/lifecycle.ts     5,730 callers
```

Why it matters:

This highlights structural centrality. The result is not just "this string is
common"; it is "many symbols call this symbol."

## Query 5: Trace A Relationship

Ask OpenHands:

```text
Use GitNexus MCP on vscode-benchmark-repo. Trace from run to _runCommand in
src/vs/workbench/contrib/commands/common/commands.contribution.ts with maxDepth
4. Show the path, edge type, confidence, and why this is a graph answer rather
than a search answer.
```

Representative result:

```text
run --CALLS 0.85--> _runCommand
```

Why it matters:

Text search can show both symbol names. A graph result can show whether the
symbols are related and what kind of edge connects them.
