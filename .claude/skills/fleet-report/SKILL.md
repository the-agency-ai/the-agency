---
description: One-shot principal briefing — health + open PRs + unread dispatches/flags + stale handoffs. Run this when you want a quick, comprehensive fleet status for principal review. Wraps agency-health with the situational data the principal needs to start or end a session.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Fleet Report

Principal-facing briefing. Answers: **"what's the state of the fleet right now?"**

This skill is a *situational report*, not an action. It:
- Runs `agency-health` (the structural behavior/state check)
- Aggregates open PRs + recent merges via `gh`
- Aggregates unread dispatches + flags via ISCP
- Flags stale handoffs (> 48h since last write)
- Surfaces recent commits per worktree
- Presents a single consolidated report to the principal

## When to use

- **Session start** — before the principal starts work, hand them the fleet state
- **Pre-release** — quick scan of "what's in flight" before cutting a release
- **Post-merge** — after a major PR lands, confirm the fleet absorbed it
- **Captain check-in** — whenever the principal asks "what's going on?"

## Arguments

- `$1` (optional): `--json` for machine-readable output, or `--brief` for a one-paragraph summary

## Steps

### Step 1: Health

```
./claude/tools/agency-health --json all
```

Capture the JSON; extract the overall warnings/critical counts and the per-dimension details.

### Step 2: PRs

```
gh pr list --state open --json number,title,author,createdAt,updatedAt,isDraft --limit 30
gh pr list --state merged --limit 5 --json number,title,mergedAt
```

List every open PR (draft status, age since update). Flag PRs updated > 72h ago as "stale".

### Step 3: Dispatches + flags

```
./claude/tools/dispatch list --all --status unread
./claude/tools/flag list
```

Aggregate: total unread dispatches, total unread flags, and per-agent breakdowns.

Also check cross-repo collaboration:

```
./claude/tools/collaboration check
```

### Step 4: Stale handoffs

For each agent (glob `usr/*/*/captain-handoff.md` + `usr/*/*/<agent>-handoff.md`), check `date` field in frontmatter. Flag any older than 48 hours.

### Step 5: Recent activity per worktree

For each worktree (from `git worktree list`):

```
./claude/tools/git-safe log --oneline -5 {branch}
```

Capture: last commit hash + message, commits-since-main.

### Step 6: Compose report

Present as:

```
FLEET REPORT — 2026-04-19 14:23

HEALTH (from agency-health)
  Workstreams: N healthy, M attention, K warning, P critical
  Agents:      N healthy, …
  Worktrees:   N healthy, …
  Overall:     K warnings, P critical  [exit N]

PRs IN FLIGHT
  #NNN  [draft] <title>           opened 3d ago, updated 4h ago
  #NNN           <title>           opened 1d ago, updated 2d ago  [stale]

RECENT MERGES
  #NNN  <title>                    merged 2h ago → v45.N
  …

UNREAD DISPATCHES
  captain:     N unread  (oldest: 2d)
  devex:       N unread  (oldest: 5h)
  …

UNREAD FLAGS
  captain:     N (newest: "…")
  …

STALE HANDOFFS
  <agent>:     last written 3d ago  [stale]
  …

RECENT COMMITS (per worktree)
  (main):      {hash} {message}
  devex:       {hash} {message}  (2 commits ahead of main)
  …

CROSS-REPO
  monofolk:    N unread collab dispatches

─────────
NEXT ACTIONS (captain inference)
  1. <agent> handoff stale — consider a status check
  2. #NNN stale for 2d — needs attention
  3. …
```

### Step 7: Brief mode

If `--brief`, produce a single paragraph:

```
Fleet is <healthy|attention|warning|critical>. N PRs open (M stale).
K unread dispatches across L agents. <stale handoffs>. <recent merges>.
Top action: <inferred>.
```

### Step 8: JSON mode

If `--json`, structure as:

```json
{
  "timestamp": "...",
  "health": { ... (agency-health JSON) },
  "prs": { "open": [...], "recent_merged": [...] },
  "dispatches": { "total_unread": N, "by_agent": { ... } },
  "flags": { "total_unread": N, "by_agent": { ... } },
  "handoffs": { "stale": [...], "fresh": [...] },
  "worktrees": { ... },
  "cross_repo": { ... },
  "next_actions": [...]
}
```

## Not in v1

- **Predictive queues** — "based on recent pace, worktree X will need attention by Y". Deferred.
- **Trends over time** — "dispatch backlog is growing 10% week over week". Requires persistent storage.
- **Release-readiness score** — "fleet is 87% ready for v45.3". Too heuristic for v1.

## Related

- `agency-health` — the underlying structural check
- `dispatch` + `flag` — ISCP surfaces
- `gh pr list` — PR aggregation
- Companion seed: make `fleet-report` the default output of `/session-resume`'s Step 4

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
