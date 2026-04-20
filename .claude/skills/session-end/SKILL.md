---
name: session-end
description: Clean session teardown — commit all work, write a resumption-framed handoff, stop monitors, report readiness. Leaves a clean working tree. No asking.
agency-skill-version: 2
when_to_use: "End of a working session, switching to a different workstream or repo, or any point where the session will not be resumed in continuation. Anti-triggers: do NOT use mid-sprint when you plan to keep working after /compact (use /compact-prepare — it writes a continuation-framed handoff). Do NOT use for captain fleet-wide shutdown (there is no such skill — each worktree session ends independently)."
argument-hint: "[trigger-reason]"
paths: []
required_reading:
  - claude/REFERENCE-HANDOFF-SPEC.md
  - claude/REFERENCE-SKILL-CONVENTIONS.md
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session End

## Why this exists

The next session starts from the handoff. A session that ends with a dirty tree, unsent dispatches, or a stale handoff leaves the next agent reverse-engineering what was in flight. This skill forces the three end-of-session preconditions and shells to `claude/tools/session-pause --framing resumption` for the mechanics — commit, archive, stop monitors, emit new handoff path.

**PAUSE-for-end** surface. Paired with `/session-resume` on the other side.

## Required reading

- `claude/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter, `mode: resumption` enum value.
- `claude/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern.

## Usage

```
/session-end
/session-end "end-of-day"
/session-end "switching-context"
```

`[trigger-reason]` (optional): short tag for telemetry + handoff frontmatter. Defaults to `session-end`.

## Preconditions

1. You're ending the session (or switching context). For mid-sprint refresh, use `/compact-prepare`.
2. Uncommitted work is ready to commit as-is. The skill does not stash.

**Idempotent:** safe to run multiple times. Archives + re-writes each run.

## Flow / Steps

### Step 1: Run session-pause primitive

```bash
./claude/tools/session-pause --framing resumption --trigger "${REASON:-session-end}"
```

`--framing resumption` tells the tool: stop monitors (registry-driven SIGTERM), fire SessionEnd hooks naturally on process exit, archive prior handoff, emit new path. If framework code is dirty, the tool force-commits the handoff alone first (`handoff_commit_sha` set), then aborts on the framework-code gate. Handoff is always persisted.

Parse the emitted key=value output. Key fields: `handoff_path`, `archived_previous_handoff`, `commit_sha`, `handoff_commit_sha`, `status`.

On `status=aborted`, surface `error_reason`. If `handoff_commit_sha` is non-none the handoff is safe — run `/quality-gate` + `/iteration-complete` on the framework code and re-run `/session-end`.

### Step 2: Author resumption-framed handoff

Write the handoff file at `handoff_path`. Frontmatter:

- `type: session`
- `agent: <org>/<principal>/<agent>`
- `date: <UTC>`
- `trigger: session-end`
- `branch: <current>`
- **`mode: resumption`** — REQUIRED. Tells `/session-resume` this is a fresh-session pickup.
- **`next-action:`** — the concrete first step of the next session. Not a backlog.

Body: phase/iteration status, what was done, what's next, decisions/context the next session needs, open blockers. Frame for **resumption** — a future session will read this after a break.

### Step 3: Verify handoff + report

```bash
./claude/tools/handoff read
```

Report: branch, last commit, `handoff_path`, "Handoff: written ✓", then:

> **Safe to `/compact` and/or `/exit`.**

## Failure modes

- **session-pause aborts on framework-code dirt**: tool already force-committed the handoff. Run `/quality-gate` + `/iteration-complete`, then re-run `/session-end`.
- **Lock contention (exit 2)**: another PAUSE/PICKUP is running. Wait, retry.
- **Handoff write permission error** (Step 2): session should not end without a handoff. Fix filesystem permission, retry.

## What this does NOT do

- **Does not invoke `/exit` or `/compact`.** It prepares; the user exits.
- **Does not stash.** Resolve WIP first.
- **Does not run the quality gate.** Framework code should have gone through QG at iteration boundaries.
- **Does not push.** Push is `/sync` or `/release`.

## Status

`active` (v2 refactored in session-lifecycle-refactor Phase 3 Iteration 3.3 — body collapsed from ~145 lines to ~60, now shells to `session-pause`). Paired with `/session-resume`, `/compact-prepare`.

## Related

- `/session-resume` — fresh-session PICKUP (opposite bookend).
- `/compact-prepare` — mid-session PAUSE (continuation framing).
- `/compact-resume` — post-compact PICKUP.
- `claude/tools/session-pause` — primitive this skill shells to.
- `claude/tools/handoff` — handoff read/write tool.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
