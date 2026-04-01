---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/worktree-sync *)
description: Sync worktree with master — merge, copy settings, run sandbox-sync, report changes
---

# Worktree Sync

Sync your worktree branch with master. Merges master, copies settings.json from the main checkout, runs sandbox-sync, and reports what changed.

## Arguments

- `$ARGUMENTS`: Optional. No arguments needed for normal use.

## Instructions

### Step 1: Run the tool

```
bash $CLAUDE_PROJECT_DIR/claude/tools/worktree-sync
```

If your working tree is dirty, commit or stash first — the tool will refuse.

### Step 2: Interpret the report

The tool reports:
- Files changed by the merge (in `claude/` and `.claude/`)
- Whether settings.json was updated
- New dispatches found
- Whether CLAUDE.md was updated

### Step 3: Act on changes

- **If CLAUDE.md was updated:** Re-read CLAUDE.md now. Methodology or project instructions changed.
- **If dispatches found:** Read them with `/dispatch read <file>`.
- **If settings.json updated:** New hooks or permissions are active.

### Note

This skill is for **worktree agents only**. On master, use `/sync-all` instead.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
