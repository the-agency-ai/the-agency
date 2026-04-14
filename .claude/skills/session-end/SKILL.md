---
description: End a session cleanly — commit, write handoff, report readiness
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session End

Clean session teardown. Commits all work, sends pending dispatches, writes the handoff, and reports readiness. **Leave a clean working tree. No asking — just do it.**

## Arguments

- `$ARGUMENTS`: Optional trigger reason (e.g., "end-of-day", "switching-context"). Defaults to "session-end".

## Instructions

### Step 1: Send pending dispatches

Check for any unsent dispatches. If there are pending dispatches, send them now.

### Step 2: Get clean

Run `git status --porcelain`. If the tree is already clean, skip to Step 3.

If there are uncommitted changes (modified, staged, or untracked files):

1. Stage all relevant files
2. Commit via `/git-safe-commit` with a descriptive message covering what's being committed
3. Verify clean: `git status --porcelain` should return empty

**Do not ask.** Do not warn and leave dirty. Commit everything and get clean. The next session starts from a clean tree.

**Idempotent:** Running `/session-end` multiple times is safe. If already clean, it skips the commit. If a handoff already exists, it archives and writes a fresh one.

### Step 3: Archive and get handoff path

```
./claude/tools/handoff write --trigger session-end
```

The tool archives the current handoff and reports the path for the new one.

### Step 4: Write handoff content

Write the handoff file at the path reported by the tool. Include:
- Current phase/iteration status
- What was done this session
- What's next
- Key decisions or context for a fresh session
- Open items or blockers

### Step 5: Verify handoff

```
./claude/tools/handoff read
```

Confirm the handoff was written correctly.

### Step 6: Report readiness

Report to the user:
- **Branch:** `git branch --show-current`
- **Last commit:** `git log --oneline -1`
- **Dirty files:** 0 (must be 0 — Step 2 ensures this)
- **Handoff:** written ✓

### Step 7: Next action directive

End with a clear directive:

> **Safe to `/compact` and/or `/exit`.**

This tells the user their session state is preserved and they can:
- `/compact` — refresh context and keep working
- `/exit` — end the session
- `/compact` then `/exit` — compact first, then end

The handoff is written. Either action is safe.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
