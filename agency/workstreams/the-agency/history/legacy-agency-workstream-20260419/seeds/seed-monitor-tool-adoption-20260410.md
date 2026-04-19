---
type: seed
workstream: agency
date: 2026-04-10
subject: "Monitor Tool — event-driven replacement for dispatch polling"
---

# Monitor Tool — Adopt for TheAgency

## What It Is

Claude Code v2.1.98+ introduces the **Monitor tool** — background scripts that stream events to the agent in real-time. Event-driven, not polling-based. Massive token savings.

## How It Works

- Claude writes a small script (bash, Python, etc.)
- Spawns it as a background process
- Each stdout line streams into the conversation as it arrives
- Claude reacts between turns — non-blocking
- Dies when the session ends

## Why This Matters for Us

### Current pattern: `/loop 5m dispatch list`
- 288 checks/day × ~2,000 tokens/check = **~82,000 tokens/day**
- 5-minute latency before agent sees new dispatch
- Blocks conversation while polling

### Proposed pattern: Monitor + dispatch polling script
- Background script runs: `while true; do ./agency/tools/dispatch list --status unread 2>/dev/null | grep -v "No dispatches"; sleep 10; done`
- Only streams output when there ARE dispatches
- **~2,000 tokens/day** (per dispatch event, not per poll)
- **10-second latency** instead of 5 minutes
- Non-blocking — agent keeps working

### Token savings: 96% reduction

## Adoption Plan

1. **Dispatch monitoring** — replace `/loop 5m dispatch list` with Monitor
2. **Collaboration monitoring** — replace `/loop 10m collaboration check` with Monitor
3. **Dev server watching** — Monitor build output for errors during implementation
4. **Test watching** — Monitor test runs, react to failures in real-time
5. **Deploy tracking** — Monitor Vercel/CI deploy status

## Workshop Case Study

This is a perfect case study for the Republic Poly workshop:

> "We discovered this feature TODAY. Within minutes, we researched it, understood the implications, wrote a seed to adopt it, and planned the migration from our current polling to event-driven monitoring. That's AI Augmented Development in action — the OODA loop. Observe (new feature), Orient (how does it fit our system), Decide (adopt, replace polling), Act (seed, plan, implement)."

Shows the live, iterative, responsive nature of working this way.

## Implementation Notes

- Requires Claude Code v2.1.98+
- Monitor processes die with the session — need to restart on session start
- Can be wrapped in a skill: `/monitor-dispatches`
- Background script should be in `agency/tools/` (e.g., `dispatch-monitor`)
- Replaces both the 5m fast-path and 30m nag loops

## References

- Claude Code v2.1.98 release notes
- Claude Code Tools Reference — Monitor tool
- Alistair's X post on Monitor tool launch
