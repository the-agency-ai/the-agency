---
name: session-resume
description: Full session startup for worktree agents — shells to session-pickup --from fresh (sync master + preflight), reports state (handoff mode, dispatch drift, monitor health), relaunches dead monitors, hands back next-action.
agency-skill-version: 2
when_to_use: "Agent starts a new session in a worktree, picks up work after a long pause, or wants a full mid-session resync. Anti-triggers: do NOT use for mid-session post-compact (use /compact-resume — trimmed pickup, no sync); do NOT use for end-of-session teardown (use /session-end); do NOT use from the main checkout on master — captain uses /captain-sync-all."
argument-hint: "(no args)"
paths: []
required_reading:
  - claude/REFERENCE-HANDOFF-SPEC.md
  - claude/REFERENCE-ISCP-PROTOCOL.md
  - claude/REFERENCE-WORKTREE-DISCIPLINE.md
  - claude/REFERENCE-SKILL-CONVENTIONS.md
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session Resume

## Why this exists

Worktree sessions don't start on a clean slate — master has moved, dispatches have accumulated, the handoff holds carry-over context, monitors need to be live. Without a disciplined startup, agents miss overnight dispatches, work on stale master, forget the last session's `next-action`, or run without the ISCP monitor so new dispatches arrive silently.

This skill shells to `claude/tools/session-pickup --from fresh` for the mechanics (sync, preflight, state report) and acts on the output — re-launches dead monitors, surfaces drifted dispatches, hands the agent a clean re-orient point.

**PICKUP-for-fresh** surface. Paired with `/session-end` on the other side. Contrast `/compact-resume` (post-compact, trimmed — no sync, no full preflight).

## Required reading

- `claude/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter, `mode: resumption` enum value.
- `claude/REFERENCE-ISCP-PROTOCOL.md` — dispatch lifecycle + drift semantics.
- `claude/REFERENCE-WORKTREE-DISCIPLINE.md` — why worktree sync matters.
- `claude/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern.

## Usage

```
/session-resume
```

No arguments. Self-contained. Works from any branch; on master, the sync step silently no-ops (but the rest still runs — it's the mid-session resync path too).

## Preconditions

1. Agency tooling installed (`claude/tools/session-pickup`, `session-preflight`, `worktree-sync`, `dispatch`, `handoff`).
2. Worktree readable, agent identity resolves correctly.
3. A prior session wrote a handoff (usually via `/session-end`). First-session-in-worktree is tolerated — pickup reports `aborted` or an empty `next_action` in that case.

## Flow / Steps

### Step 1: Run session-pickup primitive

```bash
./claude/tools/session-pickup --from fresh
```

`--from fresh` runs `worktree-sync --auto` and `session-preflight` in addition to the common PICKUP steps (read handoff, check tree, count dispatch drift, probe monitor health). Preflight failure → `status=blocked`.

Parse key=value output. Key fields: `handoff_mode`, `pause_commit_sha`, `next_action`, `tree_state`, `dispatches_unread`, `dispatches_drift_since_pause`, `monitor_health_{dispatch,ci,issue}`, `status`, `error_reason`.

### Step 2: Handle status

- **`status=ok`** — proceed to Step 3.
- **`status=blocked`** — surface `error_reason` (dirty tree? preflight fail?). Fix, re-invoke.
- **`status=aborted`** — fatal early bail (missing handoff, lock contention, bad identity). Surface error, stop.

### Step 3: Re-launch dead monitors

For each `monitor_health_* = dead`, invoke the corresponding skill (NOT `monitor-register` directly):

- `monitor_health_dispatch = dead` → invoke `/monitor-dispatches`.
- `monitor_health_ci = dead` → invoke `/monitor-ci`.
- `monitor_health_issue = dead` → invoke `/changelog-watch` (or issue-monitor owner in your fleet).

`unknown` types aren't registered — probably weren't running. Leave alone unless the agent wants them.

### Step 4: Surface dispatch drift + unread

If `dispatches_unread > 0`, list via `./claude/tools/dispatch list --status unread`. An unread dispatch is a blocked person — read before starting new work (standing priority). `dispatches_drift_since_pause` is the subset that arrived after the prior PAUSE commit — usually what to focus on first.

### Step 5: Report and hand off

Report to the user:

- **Branch:** via `./claude/tools/git-safe branch --show-current`
- **Last commit:** via `./claude/tools/git-safe log --oneline -1`
- **Sync result:** what worktree-sync did (or "on master — sync skipped")
- **Handoff mode:** `handoff_mode` (should be `resumption` for fresh; `continuation` is tolerable; `legacy` means pre-refactor migration tolerated)
- **Monitors:** summary count of ok / dead (relaunched) / unknown
- **Dispatches:** total unread + drift since PAUSE
- **Next action:** verbatim from `next_action`

Agent resumes from `next_action`.

## Failure modes

- **`status=blocked` — preflight failed**: checklist tells you what's missing (monitor not started, dispatch unprocessed, sync stale). Fix each failure, re-run.
- **`status=blocked` — tree dirty**: worktree-sync may have produced conflicts. Inspect `git status`, resolve, commit or stash, re-run.
- **`status=aborted` — handoff missing**: first-session-in-worktree is tolerated — proceed with no carry-over context and write a fresh handoff at end-of-session.
- **Lock contention (exit 2)**: another PAUSE/PICKUP running — wait, retry.
- **Monitor re-launch fails**: the monitor skill reports. Skip; agent can retry manually. Not a block on resuming.

## What this does NOT do

- **Does not commit or push.** Pure startup; zero mutation of git history.
- **Does not resolve merge conflicts.** Sync step surfaces them; agent resolves.
- **Does not run the quality gate.** That's per-iteration (`/iteration-complete`), not per-session.
- **Does not start work.** It produces the ready state; `next_action` comes from the handoff, not this skill.
- **Does not run from the main checkout.** Captain uses `/captain-sync-all` + handoff read — different authority scope.

## Status

`active` (v2 refactored in session-lifecycle-refactor Phase 3 Iteration 3.4 — body collapsed from ~125 lines to ~90, now shells to `session-pickup`). Paired with `/session-end`, `/compact-resume`.

## Related

- `/session-end` — PAUSE counterpart at session close.
- `/compact-resume` — post-compact PICKUP (same process, trimmed).
- `/captain-sync-all` — captain-side fleet startup on master.
- `/monitor-dispatches`, `/monitor-ci`, `/changelog-watch` — re-launch paths for dead monitors.
- `claude/tools/session-pickup` — primitive this skill shells to.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
