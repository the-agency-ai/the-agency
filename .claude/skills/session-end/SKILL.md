---
description: End a session cleanly — write handoff, warn on dirty state, report readiness
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session End

Clean session teardown. Writes the handoff, warns about uncommitted work, and reports readiness for captain pickup.

## Arguments

- `$ARGUMENTS`: Optional trigger reason (e.g., "end-of-day", "switching-context"). Defaults to "session-end".

## Instructions

### Step 1: Check dirty state

Run `git status --porcelain`. If there are uncommitted changes:

**Warn the user:**
> You have N uncommitted files. Commit them before ending, or they'll be left as dirty state for the next session.

List the files. Ask if they want to commit first.

### Step 2: Archive and get handoff path

```
./claude/tools/handoff write --trigger session-end
```

The tool archives the current handoff and reports the path for the new one.

### Step 3: Write handoff content

Write the handoff file at the path reported by the tool. Include:
- Current phase/iteration status
- What was done this session
- What's next
- Key decisions or context for a fresh session
- Open items or blockers

### Step 4: Verify handoff

```
./claude/tools/handoff read
```

Confirm the handoff was written correctly.

### Step 5: Report readiness

Report to the user:
- **Branch:** `git branch --show-current`
- **Last commit:** `git log --oneline -1`
- **Dirty files:** count (0 = ready for captain)
- **Handoff:** written ✓

If dirty files remain, note: "Captain pickup may miss uncommitted work."

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
