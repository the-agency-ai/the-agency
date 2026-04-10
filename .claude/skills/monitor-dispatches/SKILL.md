# Monitor Dispatches

Set up event-driven dispatch monitoring using Claude Code's Monitor tool. Replaces the /loop polling pattern with real-time, token-efficient background monitoring.

## When to use

- At session start, instead of setting up `/loop 5m dispatch list`
- When you want instant dispatch notification instead of 5-minute polling
- Requires Claude Code v2.1.98+

## Instructions

### Start monitoring

Use the Monitor tool to run the dispatch-monitor script in the background:

```
Monitor dispatches for me. Run ./claude/tools/dispatch-monitor --include-collab in the background. When output appears, read and respond to the dispatches.
```

The script:
- Polls every 10 seconds (configurable with `--interval N`)
- Only outputs when there ARE unread dispatches (completely silent otherwise)
- With `--include-collab`, also checks cross-repo collaboration dispatches
- Output is prefixed with `[DISPATCH]` or `[COLLAB]` for routing

### When output arrives

1. Parse the dispatch list from the Monitor output
2. Read each unread dispatch with `./claude/tools/dispatch read <id>`
3. Respond appropriately
4. Resolve with `./claude/tools/dispatch resolve <id>` if no further action needed

### Why this replaces /loop

| Aspect | /loop polling | Monitor |
|--------|--------------|---------|
| Token cost | ~2,000 per check | ~10 per event |
| Latency | 5 minutes | 10 seconds |
| Blocking | Yes | No |
| Daily cost | ~82,000 tokens | ~2,000 tokens |

### Stop monitoring

Ask Claude to stop the monitor, or it stops automatically when the session ends.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
