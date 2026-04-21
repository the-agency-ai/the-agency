---
name: compact-prepare
description: Mid-session compact prep — force-commit the handoff, flush coord work, write continuation-framed handoff, direct to /compact.
agency-skill-version: 2
when_to_use: "Context window is filling and you want to keep working after /compact. Runs the PAUSE primitive in continuation framing, writes a handoff the post-compact session will pick up."
paths: []
required_reading:
  - agency/REFERENCE/REFERENCE-HANDOFF-SPEC.md
  - agency/REFERENCE/REFERENCE-SKILL-CONVENTIONS.md
argument-hint: "[reason]"
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Compact Prepare

## Why this exists

Claude Code's `/compact` summarizes the conversation to free context, but a summary is lossy. The guarantee "I'll remember what I was doing after compact" holds only if a disciplined handoff is written BEFORE compact. This skill is that discipline for mid-session compaction — you commit current coord work, write a continuation-framed handoff, then run `/compact`.

Framework: this is the **PAUSE-for-compact** surface. It shells to `agency/tools/session-pause --framing continuation`. Paired with `/compact-resume` on the other side.

## Required reading

- `agency/REFERENCE/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter shape, `mode:` enum (continuation for this skill)
- `agency/REFERENCE/REFERENCE-SKILL-CONVENTIONS.md` — primitive-composition pattern (skills shell to bash tools per agency#348)

## Usage

```
/compact-prepare
/compact-prepare "context heavy — deep investigation paused"
/compact-prepare "mid-iteration refresh before QG"
```

`[reason]` (optional): short label for telemetry + handoff frontmatter. Defaults to `compact-prepare`.

After this skill reports clean state + handoff written, **run `/compact` next.** The skill does not invoke `/compact` — you do.

## Preconditions

1. You're in a git repository with The Agency tooling installed.
2. You intend to keep working after `/compact`. If you don't, use `/session-end` instead.
3. Any uncommitted WIP is ready to commit as-is. The skill does not stash.

**Idempotent:** safe to run multiple times. Archives and re-writes each time.

## Flow / Steps

### Step 1: Run session-pause primitive

```bash
./agency/tools/session-pause --framing continuation --trigger "${REASON:-compact-prepare}"
```

The primitive (v1.2.0+) force-commits the handoff in its own commit if the tree has non-coord framework files dirty — so the handoff is durable even when the overall PAUSE aborts on framework-code gate. Parse the emitted key=value output:

- `schema_version`, `tool_version` — output contract versions.
- `handoff_path` — path to the new empty handoff you must author in Step 2.
- `archived_previous_handoff` — archive path of the prior handoff (or `none`).
- `commit_sha` — coord checkpoint commit (or `none` if tree was clean).
- `handoff_commit_sha` — force-commit SHA when the tool force-committed the handoff alone (abort path); `none` on the happy path.
- `framing=continuation` — confirms the tool read the flag correctly.
- `status` — `ok` or `aborted`.

If `status=aborted` AND `handoff_commit_sha` is non-none, the handoff was persisted but framework code is dirty — surface `error_reason` (which includes the handoff SHA) and stop. Run `/quality-gate` + `/iteration-complete` on the framework code, then re-run `/compact-prepare`.

If `status=aborted` AND `handoff_commit_sha=none`, the PAUSE aborted before any commit — surface `error_reason` and stop. Do NOT author a handoff on an aborted PAUSE.

### Step 2: Author continuation-framed handoff

Write the handoff file at `handoff_path`. Use the standard handoff template with:

- `type: session`
- `agent: <org>/<principal>/<agent>` (from agent-identity)
- `date: <UTC timestamp>`
- `trigger: compact-prepare`
- `branch: <current branch>`
- **`mode: continuation`** — REQUIRED. Tells `/compact-resume` this is mid-session.
- **`next-action:`** — the SINGLE most important thing to do immediately after `/compact`. Not a backlog; the very next step.
- Optional: `pause_commit_sha: <commit_sha from Step 2>` — lets `/compact-resume` compute dispatch drift deterministically.

Body:
- **Current phase/iteration status** (what you were doing).
- **What was done this session so far.**
- **What's in progress right now.**
- **What's next** (immediate — same as `next-action`, elaborated).
- **Key decisions or context that must survive compaction.**
- **Open items or blockers.**

Frame for **continuation**, not resumption. The agent keeps working after compact — doesn't start fresh.

### Step 3: Verify handoff

```bash
./agency/tools/handoff read
```

Confirm the handoff was written correctly and `next-action` is clear.

### Step 4: Report and direct

Report to the user:

- **Branch:** via `./agency/tools/git-safe branch --show-current`
- **Last commit:** via `./agency/tools/git-safe log --oneline -1`
- **Dirty files:** 0 (session-pause ensures this, or aborted above)
- **Handoff path:** from session-pause output
- **Archived:** prior handoff archive path from session-pause output

Then the directive:

> **Run `/compact` now.**

## Failure modes

- **session-pause aborts on framework-code dirt**: the tool has already force-committed the handoff (see `handoff_commit_sha`) — the handoff is safe. Run `/quality-gate` + `/iteration-complete` on the framework code, then re-run `/compact-prepare`.
- **Lock contention (exit 2)**: another PAUSE/PICKUP is running for the same handoff. Wait, then retry. If the lock is stale (held by a dead process), the error_reason includes a cleanup hint.
- **Multiple runs in a single session**: safe. Each run archives + re-writes.
- **Run without intending to compact**: also safe. The skill never invokes `/compact` itself.

## What this does NOT do

- **Does not invoke `/compact`.** It prepares; the user runs compact. Intentional — the skill must never surprise-compact.
- **Does not stash.** If there's WIP you don't want in a commit, resolve it manually first.
- **Does not run the quality gate.** Framework-code dirt aborts via `session-pause`; run QG before re-trying.
- **Does not push.** All commits stay local. Push is `/sync` or `/release`.

## Status

`active` (v2, shipped session-lifecycle-refactor Phase 3 Iteration 3.1). Paired with `/compact-resume`, `/session-end`, `/session-resume`.

## Related

- `/compact-resume` — PICKUP companion (post-compact).
- `/session-end` — end-of-session PAUSE (resumption framing).
- `/session-resume` — fresh-session PICKUP.
- `agency/tools/session-pause` — primitive this skill shells to.
- `agency/tools/handoff` — handoff read/write tool.
- `the-agency#355` — upstream tracker for handoff force-commit landing in the primitive (when that lands, Step 1 is retired per Plan HG-7).

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
