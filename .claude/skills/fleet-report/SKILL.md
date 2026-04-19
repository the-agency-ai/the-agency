---
name: fleet-report
description: One-shot principal briefing — aggregates agency-health + open PRs + unread dispatches/flags + stale handoffs into a single situational report. Use at session start, pre-release, post-merge, or whenever the principal asks "what's going on?"
agency-skill-version: 2
when_to_use: "Principal asks for fleet status, session-start briefing, pre-release scan, post-merge confirmation, or 'what's going on?' check-ins. NEVER use this to TAKE action — fleet-report reports only. Follow-up actions are the principal's call."
argument-hint: "[--brief | --json]"
paths: []
disable-model-invocation: false
# allowed-tools omitted — inherits Bash(*) from .claude/settings.json. Subcommand-level
# restriction would silently block fleet agents on permission prompts (flag #62/#63,
# devex dispatch #171). Every tool this skill invokes is already in the safe-tools
# family (git-safe, git-captain, dispatch, flag, collaboration, agency-health).
required_reading:
  - agency/REFERENCE-ISCP-PROTOCOL.md
  - agency/REFERENCE-WORKTREE-DISCIPLINE.md
  - agency/REFERENCE-HANDOFF-SPEC.md
  - agency/REFERENCE-CODE-REVIEW-LIFECYCLE.md
---

<!--
  Flag #62/#63: allowed-tools intentionally omitted. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns silently
  blocks agents on permission prompts the agent cannot see — see dispatch #171
  for the devex incident that surfaced this trap.
-->

# fleet-report

Principal-facing fleet briefing. Answers: **"what is the state of the fleet right now?"**

## Why this exists

Principals returning to a fleet session (end-of-day, next morning, after an interruption) need one-shot situational awareness: is anything on fire, what's in flight, what's blocked. Without it, every session starts with 5–10 minutes of manual polling — `git status` per worktree, `gh pr list`, `dispatch list`, `flag list`, scan-all-handoffs. Fleet-report consolidates those six data sources into a single human-readable report (or `--brief` paragraph / `--json` blob) with a captain-inferred NEXT ACTIONS list at the bottom.

This is **situational reporting**, not action. The skill takes no actions. The principal reads the report and decides.

## Usage

```
/fleet-report          # full human-readable report
/fleet-report --brief  # single-paragraph summary
/fleet-report --json   # machine-readable output
```

**When to invoke:**

- Session start (principal returning from break / end-of-day)
- Before cutting a release (scan what's in flight)
- After a significant merge or dispatch broadcast (confirm fleet absorbed it)
- Principal asks "what's going on?" — run this instead of ad-hoc polling

## Required reading

Before composing the report, read the framework reference docs listed in `required_reading:` frontmatter. These define the protocols the aggregated data represents — ISCP dispatches (how to interpret unread counts), worktree discipline (what "stale" means for a worktree), handoff spec (when a handoff counts as stale), and PR lifecycle (what "stale PR" means in our model).

## Preconditions

- Running from captain (or an agent with read access to the full repo + cross-repo collab dir). Fleet-report aggregates across all worktrees / agents / workstreams.
- `gh` CLI authenticated (needed for PR list + recent merges).
- `agency-health` tool available in `agency/tools/` (required).
- Cross-repo collaboration dir exists if `collaboration` step should fire; otherwise step silently no-ops.

None of these are checked by the skill — they are environmental assumptions. Failures surface as individual step errors (see Failure modes).

## Flow

### Step 1 — Health

```
./agency/tools/agency-health --json all
```

Capture the JSON; extract overall warnings/critical counts + per-dimension details. Preserve for Step 6.

### Step 2 — PRs

```
gh pr list --state open --json number,title,author,createdAt,updatedAt,isDraft --limit 30
gh pr list --state merged --limit 5 --json number,title,mergedAt
```

Flag PRs whose `updatedAt` > 72h ago as "stale". Note draft vs ready status.

### Step 3 — Dispatches + flags

```
./agency/tools/dispatch list --all --status unread
./agency/tools/flag list
./agency/tools/collaboration check
```

Aggregate: total unread dispatches, per-agent breakdown, total unread flags, per-agent breakdown, cross-repo unread count per repo.

### Step 4 — Stale handoffs

For each agent (glob `usr/*/*/captain-handoff.md` + `usr/*/*/<agent>-handoff.md`), read the `date:` field in YAML frontmatter. Flag any older than 48 hours as "stale".

### Step 5 — Recent activity per worktree

For each worktree reported by `agency-health`:

```
./agency/tools/git-safe log --oneline -5
```

Capture last commit hash + message per worktree. Note commits-ahead-of-main count from Step 1's health JSON.

### Step 6 — Compose report

Human mode (default):

```
FLEET REPORT — YYYY-MM-DD HH:MM

HEALTH (from agency-health)
  Workstreams: N healthy, M attention, K warning, P critical
  Agents:      N healthy, …
  Worktrees:   N healthy, …
  Overall:     K warnings, P critical  [exit N]

PRs IN FLIGHT
  #NNN  [draft] <title>   opened 3d ago, updated 4h ago
  #NNN           <title>   opened 1d ago, updated 2d ago  [stale]

RECENT MERGES
  #NNN  <title>   merged 2h ago → v45.N
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
  <partner-repo>: N unread collab dispatches

─────────
NEXT ACTIONS (captain inference)
  1. <agent> handoff stale — consider a status check
  2. #NNN stale for 2d — needs attention
  3. …
```

`--brief` mode produces a single paragraph with the same data condensed:

```
Fleet is <healthy|attention|warning|critical>. N PRs open (M stale).
K unread dispatches across L agents. <stale handoffs>. <recent merges>.
Top action: <inferred>.
```

`--json` mode produces structured output for downstream consumers (status line, dashboards, alerts):

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

### Step 7 — Present

Return the composed report to the invoker. No side effects, no commits, no dispatches.

## Failure modes

| Step | Failure | Recovery |
|---|---|---|
| 1 | `agency-health` returns exit 2 (critical) | Include the critical findings in the report verbatim; do not filter. Principal needs to see it. |
| 1 | `agency-health` tool missing | Report "HEALTH: agency-health tool not available" and continue. |
| 2 | `gh` unauthenticated or network down | Report "PRs: unable to fetch (gh error: <message>)" and continue. Do not abort. |
| 3 | `dispatch` tool hangs or returns error | Report "DISPATCHES: unable to query" and continue. |
| 3 | `collaboration check` returns no configured repos | Omit CROSS-REPO section. |
| 4 | No handoff files found | Report "HANDOFFS: no agents with handoff files" — this is a cold-start state, not an error. |
| 5 | Worktree directory missing (git-worktree-list lies) | Skip that worktree, note in the report. |
| 6 | Compose step itself errors (shouldn't — it's string assembly) | Emit partial report with an error banner at the top. |

Global principle: **fleet-report never aborts mid-flight**. A data source going dark produces a gap in the report, not a failure. The principal needs the report even when parts are missing.

## What this does NOT do

- **Does not take actions.** No commits, pushes, dispatches, flag-clears, PR actions.
- **Does not auto-refresh.** Run it when you want a snapshot; it produces a point-in-time report.
- **Does not filter by severity.** Every data point surfaces; the principal decides what to prioritize. A related companion — `/fleet-triage` — could filter for critical-only in the future (not in v1).
- **Does not hallucinate NEXT ACTIONS.** The captain inference at the bottom is derived strictly from observed data — if no PRs are stale, no stale-PR action. "NEXT ACTIONS: none" is a valid output.
- **Does not persist history.** Each invocation is stateless. Trending ("dispatch backlog growing 10% week over week") is v2 work.

## Status

**pilot** — first v2 skill authored under the v2 authoring methodology (REFERENCE-SKILL-AUTHORING.md, upstream PR #309). Shipped 2026-04-19 during D45-R3 session as the principal-directed fleet-briefing capability. Dogfooding in progress; will promote to `active` once used in 3+ sessions without needing changes.

## Related

- `agency-health` — the underlying structural check (skill + tool)
- `dispatch`, `flag`, `collaboration` — ISCP + cross-repo surfaces
- Seed: make `/fleet-report` the default output of `/session-resume` Step 4
- Upstream spec: PR #309 (`REFERENCE-SKILL-AUTHORING.md`)
- Flag #51 — the original fleet-audit request that seeded `agency-health` (foundation for this)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
