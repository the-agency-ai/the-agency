---
description: Mid-session context refresh — commit, write handoff, then compact
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session Compact

Mid-session context refresh. Commits all work, writes a handoff to preserve session state, then directs the user to compact. **Leave a clean working tree. No asking — just do it.**

Use this when context is getting heavy but you want to keep working. The handoff ensures context survives compaction. After `/compact`, the agent re-orients from the compacted summary which includes the fresh handoff.

## Arguments

- `$ARGUMENTS`: Optional reason (e.g., "context heavy", "mid-sprint refresh"). Defaults to "session-compact".

## Instructions

### Step 1: Send pending dispatches

Check for any unsent dispatches. If there are pending dispatches, send them now.

### Step 2: Get clean

Run `git status --porcelain`. If the tree is already clean, skip to Step 3.

If there are uncommitted changes (modified, staged, or untracked files):

1. Stage all relevant files
2. Commit via `/git-safe-commit` with a descriptive message covering what's being committed
3. Verify clean: `git status --porcelain` should return empty

**Do not ask.** Do not warn and leave dirty. Commit everything and get clean.

**Idempotent:** Running `/session-compact` multiple times is safe. If already clean, it skips the commit. If a handoff already exists, it archives and writes a fresh one.

### Step 3: Archive and get handoff path

```
./agency/tools/handoff write --trigger session-compact
```

The tool archives the current handoff and reports the path for the new one.

### Step 4: Write handoff content

Write the handoff file at the path reported by the tool. Include:
- Current phase/iteration status
- What was done this session (so far)
- What's in progress right now
- What's next (immediate — this is a mid-session checkpoint, not end-of-day)
- Key decisions or context that must survive compaction
- Open items or blockers

Frame the handoff for **continuation**, not resumption. The agent will keep working after compact, not start fresh.

### Step 5: Verify handoff

```
./agency/tools/handoff read
```

Confirm the handoff was written correctly.

### Step 6: Report and direct

Report to the user:
- **Branch:** `git branch --show-current`
- **Last commit:** `git log --oneline -1`
- **Dirty files:** 0 (must be 0 — Step 2 ensures this)
- **Handoff:** written ✓

Then the directive:

> **Run `/compact` now.**

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
