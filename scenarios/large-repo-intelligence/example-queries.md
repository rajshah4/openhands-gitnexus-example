# Example Queries

These queries were selected because they exercise different GitNexus strengths
on a large repository: ranked search, symbol centrality, impact analysis, trace
relationships, and symbol context.

The examples assume a local VS Code / Code OSS checkout indexed in GitNexus as:

```text
vscode-benchmark-repo
```

## 1. Find A Starting Point From An Architecture Question

Use this when you want OpenHands to find the right subsystem before it starts
opening files.

```text
Use GitNexus MCP on repo vscode-benchmark-repo. Query for:
"extension activation command registration execute command"

Return the top ranked symbol or file, then explain why it is a good starting
point for a coding agent.
```

Expected useful result:

```text
CommandService.executeCommand
src/vs/workbench/services/commands/common/commandService.ts
```

Why it is useful:

Plain text search can return loose token hits. GitNexus returns a ranked code
target that the agent can inspect first.

## 2. Find Highly Reused Symbols

Use this when you want a graph-level view of risky shared code.

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

Why it is useful:

This tells the agent which symbols are structurally central, not merely which
strings appear often.

## 3. Estimate Blast Radius Before Editing

Use this before changing a shared symbol.

```text
Use GitNexus MCP on vscode-benchmark-repo. Run impact for Function localize in
src/vs/nls.ts. Use upstream direction, maxDepth 2, summaryOnly true. Explain the
risk result and what an agent should do differently before editing this symbol.
```

Representative result:

```text
Target: localize
File: src/vs/nls.ts
Risk: CRITICAL
Impacted count: 7,963
Direct impacts: 4,328
Indirect impacts: 3,635
```

Why it is useful:

The agent learns that a small-looking helper has thousands of dependents and
should avoid broad or compatibility-breaking edits.

## 4. Trace A Real Relationship

Use this when the question is whether one symbol actually reaches another.

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

Why it is useful:

Text search can show both names. GitNexus can show a typed relationship between
the symbols.

## 5. Inspect A Symbol Neighborhood

Use this after GitNexus identifies a likely entry point.

```text
Use GitNexus MCP on vscode-benchmark-repo. Get context for executeCommand, kind
Method, file_path
src/vs/workbench/services/commands/common/commandService.ts. Summarize the
outgoing calls, implemented interface, accessed fields, and any uncertainty or
boundary notes.
```

Representative result:

```text
CommandService.executeCommand

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
```

Why it is useful:

OpenHands gets the symbol's local graph context before changing code.

## Optional: Show A Static-Analysis Boundary

Use this if you want to show that graph tools should be honest when static
analysis cannot prove a path.

```text
Use GitNexus MCP on vscode-benchmark-repo. Trace from run in
src/vs/workbench/contrib/commands/common/commands.contribution.ts to
executeCommand in
src/vs/workbench/services/commands/common/commandService.ts. If no path is
found, explain what static-analysis boundary the result is showing and what the
agent should inspect next.
```

Expected useful result:

```text
Status: no_path
Likely boundary: interface dispatch, dependency injection, or dynamic dispatch.
```
