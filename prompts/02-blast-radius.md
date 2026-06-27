You are running inside OpenHands Agent Canvas.

Scenario: we want to add a "Repo Intelligence" panel to Agent Canvas that shows
which MCP-backed repo context sources are available for the current conversation.

Use available repo-intelligence tools, including GitNexus MCP if configured, to
answer:

1. Which frontend routes/components are likely affected?
2. Which backend or settings payloads might be touched?
3. Which existing tests are most relevant?
4. What are the implementation risks?
5. What is the smallest credible first PR?

Deliver a practical implementation brief:

- Affected files
- Proposed change sequence
- Tests to add or run
- Risks
- How the GitNexus result changed the implementation plan

If GitNexus MCP is unavailable, inspect the repo directly and continue.
