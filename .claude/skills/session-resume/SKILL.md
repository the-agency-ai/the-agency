---
description: Resume a worktree session — sync master, read handoff, check dispatches, report state
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Session Resume

Full session startup for worktree agents. Syncs with master, reads your handoff, checks for dispatches, and reports session state.

On SessionStart, Steps 1-2 run automatically via hooks (worktree-sync + session-handoff). Step 3 (dispatch check) requires manual invocation. Use this skill for full mid-session sync including dispatches.

## Arguments

- `$ARGUMENTS`: Optional. No arguments needed.

## Instructions

### Step 1: Sync with master

```
bash ./claude/tools/worktree-sync --auto
```

This stashes dirty work if needed, merges master, copies settings, runs sandbox-sync, and unstashes. If on master, it silently skips.

### Step 2: Read the handoff

```
bash ./claude/tools/handoff read
```

Display the handoff contents. This is your context for what was happening before this session.

### Step 3: Check for dispatches

```
bash ./claude/tools/dispatch check
```

Surface any unread dispatches. If found, list them with `dispatch list` and read with `dispatch read <id>`.

### Step 4: Report session state

Report to the user:
- **Branch:** `git branch --show-current`
- **Last commit:** `git log --oneline -1`
- **Dirty files:** `git status --porcelain | wc -l` (0 = clean)
- **Sync result:** what changed from Step 1
- **Handoff summary:** key points from Step 2
- **Dispatches:** any unread from Step 3

### Note

On master, Step 1 silently skips — the rest still runs. This skill works on any branch.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
