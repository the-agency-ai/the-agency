---
description: Monitor GitHub Actions CI status via background streaming — replaces email notifications
---

# Monitor CI

Set up event-driven CI monitoring using Claude Code's Monitor tool. Replaces GitHub email notifications with agent-actionable events.

## When to use

- At session start (captain sessions — monitor main branch health)
- After pushing a PR branch (watch for check results)
- When you want instant CI failure notification instead of checking email

## Instructions

### Start monitoring

Use the Monitor tool to run the ci-monitor script in the background:

```
Monitor CI for me. Run ./agency/tools/ci-monitor in the background persistently.
When output appears, investigate the failure and report.
```

The script:
- Polls GitHub Actions every 60 seconds (configurable with `--interval N`)
- Only outputs when there ARE failures (completely silent when green)
- Checks main branch workflow runs and open PR check statuses
- Output is prefixed with `[CI]` for routing

### Options

```bash
./agency/tools/ci-monitor --interval 30          # Poll every 30 seconds
./agency/tools/ci-monitor --repo owner/repo      # Explicit repo (default: auto-detect)
```

### When output arrives

1. Parse the failure information from the Monitor output
2. If main branch failure: investigate immediately — this is a broken window
3. If PR check failure: check if it's your PR, investigate if so
4. Report findings to the principal

### Why this replaces email notifications

| Aspect | Email | Monitor |
|--------|-------|---------|
| Latency | Minutes to hours | 60 seconds |
| Noise | Every failure, even expected | Only actionable failures |
| Action | Manual triage | Agent can investigate automatically |
| Signal | Learned to ignore | Always fresh |

### Stop monitoring

Ask Claude to stop the monitor, or it stops automatically when the session ends.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
