# /fleet-report

One-shot fleet briefing for principal review. Runs the full `fleet-report` skill:

- `agency-health` across workstreams, agents, worktrees
- Open PRs + recent merges via `gh`
- Unread dispatches + flags via ISCP
- Stale handoff detection (> 48h)
- Recent commits per worktree
- Cross-repo collab check

## Usage

```
/fleet-report          # full human-readable report
/fleet-report --brief  # single-paragraph summary
/fleet-report --json   # machine-readable output
```

## When to invoke

- At session start (principal returning from break / end-of-day)
- Before a release (quick scan of what's in flight)
- After a significant merge or dispatch broadcast
- Whenever the principal asks "what's going on?"

## What it does

Invokes the `fleet-report` skill. The skill aggregates six data sources into a single briefing and ends with a `NEXT ACTIONS` list that the captain infers from observed state.

The skill does NOT take actions. It reports. Acting on the report is the principal's call.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
