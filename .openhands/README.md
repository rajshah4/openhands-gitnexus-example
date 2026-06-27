# OpenHands Hook Example

This directory shows how an OpenHands workspace can attach a
`user_prompt_submit` hook and inject extra context before the agent starts
acting.

The included hook is intentionally minimal:

- OpenHands receives the user prompt.
- The hook runs before the agent turn starts.
- A real integration could call GitNexus for repo, symbol, or blast-radius
  context.
- OpenHands injects that context into the turn through `additionalContext`.

The script logs the event payload to `.openhands/gitnexus-hook-events.log` and
injects a short static context note. That keeps the hook easy to inspect while
showing where GitNexus CLI calls could be added.
