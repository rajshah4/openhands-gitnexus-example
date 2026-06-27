# Scenario: Large-Repository Intelligence

This scenario shows why OpenHands benefits from GitNexus on a large,
unfamiliar codebase.

The canonical target used during local development was a VS Code / Code OSS
checkout. The repo itself is not committed here. Point `VSCODE_REPO_DIR` in
`.env` at your local checkout before running the comparison UI.

## Example Question

Use this query:

```text
extension activation command registration execute command
```

What to compare:

- plain repo search is fast but falls back to loose token hits
- GitNexus returns a ranked structural starting point
- OpenHands can use that starting point to inspect concrete files
- follow-up `context` and `impact` calls turn a search result into an edit plan

## Interpretation

Plain text search asks:

```text
Which files contain these words?
```

GitNexus asks a more useful agent question:

```text
Which symbols and relationships are most likely relevant?
```

The OpenHands value is that this repo intelligence lands inside the same
conversation where the agent can read files, explain the architecture, propose a
change, run tests, and produce reviewable output.

## Recommended Follow-Ups

After the initial query, ask GitNexus for:

- symbol context around the top result
- downstream impact for the relevant method or class
- related files or modules to inspect before editing

See [example-queries.md](example-queries.md) for the five-query set used for
this scenario.

The goal is not to exercise every GitNexus feature. The goal is to give
OpenHands a better starting point than a generic grep loop.
