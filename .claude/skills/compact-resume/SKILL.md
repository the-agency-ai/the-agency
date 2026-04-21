---
name: compact-resume
description: Post-compact pickup — read continuation handoff, verify state (tree clean, monitors alive, dispatch drift), resume next-action.
agency-skill-version: 2
when_to_use: "Immediately after /compact completes. You were working, you ran /compact-prepare, you ran /compact, and now you need to re-orient before resuming the task."
paths: []
required_reading:
  - agency/REFERENCE/REFERENCE-HANDOFF-SPEC.md
  - agency/REFERENCE/REFERENCE-SKILL-CONVENTIONS.md
argument-hint: "(no args)"
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Compact Resume

## Why this exists

`/compact` collapses the conversation to a summary. The summary is lossy — subtle context (decisions in flight, half-finished reasoning, tool-call state) may not survive the compression. The `/compact-prepare` + `/compact-resume` pair holds the line:

- `/compact-prepare` writes a continuation-framed handoff with the authoritative `next-action`.
- `/compact` runs.
- `/compact-resume` reads that handoff back, checks nothing drifted during compaction, and hands the agent a clean re-orient point.

This is the **PICKUP-for-compact** surface. It shells to `agency/tools/session-pickup --from compact`. Paired with `/compact-prepare` on the other side.

## Required reading

- `agency/REFERENCE/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter shape, `mode: continuation` enum value.
- `agency/REFERENCE/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern (skill shells to bash tool per agency#348).

## Usage

```
/compact-resume
```

No arguments. The skill is self-contained — it reads the current handoff, verifies state, reports, and hands control back to the agent to resume the `next-action`.

## Preconditions

1. You just ran `/compact`. The handoff file exists from the immediately-prior `/compact-prepare`.
2. The working tree should be clean — if it's dirty, the skill reports `tree_state=dirty` and blocks. Compact doesn't modify the working tree, so dirty means something else happened in the background.
3. `agency/tools/session-pickup` is installed (framework tool; landed in session-lifecycle-refactor Phase 2).

## Flow / Steps

### Step 1: Run session-pickup primitive

```bash
./agency/tools/session-pickup --from compact
```

`--from compact` is the right mode post-compact — skips `worktree-sync` (master cannot have moved during in-process compaction) and skips full preflight (this is the same process, not a fresh session).

Parse the emitted key=value output. Fields to surface to the user:

- `handoff_mode` — should be `continuation` (paired with `/compact-prepare`). If it's `resumption` or `legacy`, the handoff wasn't from `/compact-prepare` — still usable but flag for the user.
- `pause_commit_sha` — the commit the PAUSE wrote. Drift math anchors here.
- `next_action` — the single next step. Truncated at 200 chars; the handoff body has the full version.
- `tree_state` — `clean` is required for `status=ok`. `dirty` → `status=blocked`.
- `dispatches_unread`, `dispatches_drift_since_pause` — how many dispatches need attention; how many arrived since the PAUSE commit.
- `monitor_health_dispatch`, `monitor_health_ci`, `monitor_health_issue` — `ok` / `dead` / `unknown` per monitor type.
- `status` — `ok` / `blocked` / `aborted`.

### Step 2: Handle status

- **`status=ok`** — clean resume path. Proceed to Step 3.
- **`status=blocked`** — the report is emitted; surface `error_reason` to the user. Typical cause: dirty tree (run `git status --porcelain` to see what). Fix the state, re-invoke `/compact-resume`.
- **`status=aborted`** — fatal early-bail. Typical causes: missing handoff (run `/compact-prepare` first), lock contention (another PAUSE/PICKUP running), bad identity. Surface `error_reason` and stop.

### Step 3: Re-launch dead monitors

For each `monitor_health_* = dead`, re-launch the corresponding monitor. The canonical way is via the monitor skills, NOT by calling `monitor-register` directly:

- `monitor_health_dispatch = dead` → invoke `/monitor-dispatches` (re-registers and starts streaming).
- `monitor_health_ci = dead` → invoke `/monitor-ci`.
- `monitor_health_issue = dead` → invoke `/changelog-watch` (or whichever skill owns the issue monitor type in your fleet).

For `unknown`, the monitor type isn't registered — probably wasn't running before compact. Leave it alone unless the agent wants it now.

### Step 4: Surface dispatch drift

If `dispatches_drift_since_pause > 0`, list the drifted dispatches:

```bash
./agency/tools/dispatch list --status unread
```

These are dispatches that arrived between the PAUSE commit and now. Read any that look relevant before resuming the task (an unread dispatch is a blocked person — the standing priority applies).

### Step 5: Report and hand off

Report to the user in a tight summary:

- **Branch:** via `./agency/tools/git-safe branch --show-current`
- **Last commit:** via `./agency/tools/git-safe log --oneline -1`
- **Handoff mode:** `handoff_mode` from Step 1
- **Monitors:** count of `ok` / `dead` / `unknown` across the three types
- **Dispatches:** `dispatches_unread` total, `dispatches_drift_since_pause` since PAUSE
- **Next action:** verbatim from `next_action` output

Then resume. The `next-action` from the handoff IS the task — pick it up and go.

## Failure modes

- **`status=aborted` — handoff missing**: run `/compact-prepare` first, then `/compact`, then retry.
- **`status=blocked` — tree dirty**: something mutated the tree in the background (unlikely during `/compact` itself, but possible if a hook fired). Inspect `git status`, commit or stash, retry.
- **Lock contention (exit 2)**: another PAUSE/PICKUP is running on the same handoff — wait 5s, retry. If stale, the error_reason has the cleanup hint.
- **Monitor re-launch fails**: the monitor skill reports the error. Skip; the agent can re-invoke the monitor skill manually later. Not a hard block on resuming.

## What this does NOT do

- **Does not run full session preflight.** That's `/session-resume`'s job (fresh session after `/exit`). This skill is for the same process, post-compact only.
- **Does not sync master.** Master cannot have moved during in-process compact; sync would be wasted work.
- **Does not write a new handoff.** The handoff from `/compact-prepare` IS the authoritative one; this skill reads it.
- **Does not resume the task for you.** It surfaces `next_action` and hands control back. You execute the next step.

## Status

`active` (v2, shipped session-lifecycle-refactor Phase 3 Iteration 3.2). Paired with `/compact-prepare`, `/session-end`, `/session-resume`.

## Related

- `/compact-prepare` — PAUSE companion (pre-compact).
- `/session-resume` — fresh-session PICKUP (post-`/exit`).
- `/session-end` — end-of-session PAUSE (resumption framing).
- `agency/tools/session-pickup` — primitive this skill shells to.
- `agency/tools/handoff` — handoff read/write tool.
- `/monitor-dispatches`, `/monitor-ci`, `/changelog-watch` — re-launch paths for dead monitors.
- `/dispatch` — list/read drifted dispatches surfaced in Step 4.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
