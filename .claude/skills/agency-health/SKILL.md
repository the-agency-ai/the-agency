---
description: Fleet health check across three dimensions — workstream, agent, worktree. Reports severity (healthy/attention/warning/critical) and sets exit codes for CI integration. Run this when you want to know "is the fleet OK right now?" — at session start, before a release, or after any disruption.
---

# agency-health

Three-dimensional health check over the fleet.

## What it checks

### Workstream dimension
- Workstream directory presence
- `CLAUDE-{WORKSTREAM}.md` scoping file
- Seed backlog size
- QGR recency
- General activity (last-modified across the workstream directory)

### Agent dimension
- Agent registration in `.claude/agents/`
- Expected worktree presence
- Unread dispatch count
- Handoff freshness
- Attribution integrity (recent commits not attributed to Test User)

### Worktree dimension
- Dirty working tree (modified/staged counts)
- MERGE_HEAD / REBASE_HEAD residue (critical if present)
- Divergence from main branch
- Stash pile size
- `.agency-agent` identity file presence
- `.claude/settings.json` sync with main checkout

## Severity levels

- **healthy** — no issues
- **attention** — informational, worth noticing
- **warning** — should be addressed
- **critical** — requires immediate attention

Exit codes: `0 = all healthy (or attention only)`, `1 = warnings`, `2 = critical`.

## When to use

- **Session start** — confirm the fleet is in a known state before you start work
- **Before cutting a release** — catch stale/dirty/broken worktrees before they become PR problems
- **After a major disruption** — e.g., after a merge conflict storm or a failed update
- **Periodically** — catches slow-burn issues like stale handoffs, unprocessed dispatches, rotting seeds
- **On the cron** — machine-readable output via `--json` means this can feed dashboards or alerts

## Invocations

```bash
./agency/tools/agency-health                     # full fleet report
./agency/tools/agency-health all                 # same
./agency/tools/agency-health worktree            # only worktree dimension
./agency/tools/agency-health agent devex         # only devex agent
./agency/tools/agency-health workstream iscp     # only iscp workstream
./agency/tools/agency-health --json all          # JSON for downstream consumers
./agency/tools/agency-health --help              # full help
```

## Example output (human mode)

```
the-agency fleet health  (2026-04-09 12:39)
─────────────────────────────────────────────────────────
WORKSTREAMS
  ● agency       healthy    active, artifacts present
  ● iscp         healthy    active, artifacts present
  ● mdpal        attention  12 seeds, no activity 14d

AGENTS
  ● captain      healthy    registered, handoff fresh
  ⚠ devex        warning    3 Test User commits in last 20
    BATS pollution — run test_helper.bash audit
  ● iscp         healthy    registered, handoff fresh

WORKTREES
  ● (main)       healthy    clean on main
  ● devex        attention  2 modified, 5 behind main
  ⚠ iscp         warning    12 modified, 95 behind main, settings drift

─────────────────────────────────────────────────────────
OVERALL: 2 warnings, 0 critical
```

## Not in v1

- **`--repair` mode** — auto-fix known issues. Deferred to v2. For now, the tool reports; the operator fixes.
- **Cross-workstream dependency checks** — e.g., "workstream iscp depends on workstream agency, and agency is unhealthy." Deferred to v2.
- **Historical trending** — how has fleet health changed over time? Would require persistent storage. Deferred.

## Related

- Flag #51 — the original audit tool request that seeded this
- Flag #64 — diagnostic tooling workstream
- Companion tool: `agency verify` (structural validation — this is behavioral/state validation)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
