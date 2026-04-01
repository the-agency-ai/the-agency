---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git merge:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git worktree:*), Bash(git tag:*), Bash(git reset:*), Bash(git -C:*), Read, Write, Glob, Grep, Edit
description: Fetch, rebase master, merge worktree work into master, sync all worktrees. NEVER pushes.
---

# Sync All — Local Master Sync

Fetch, rebase master, merge unique worktree work into master, and sync all worktrees. This is the daily rhythm command. **NEVER pushes to remote.**

## Steps

### Step 1: Safety checks

1. Must be on master: `git rev-parse --abbrev-ref HEAD` must return `master` (or `main`).
2. Must be in the main checkout (not a worktree).
3. Must have a clean working tree.

### Step 2: Fetch origin

Run `git fetch origin`.

### Step 3: Divergence detection

Check if master has diverged from origin/master:
- `git log --oneline origin/master..master` — local-only commits
- `git log --oneline master..origin/master` — remote-only commits

If diverged (squash PR scenario):
1. Tag before resetting: `git tag sync/pre-reset-$(date +%Y%m%d-%H%M%S)`
2. Ask the user before resetting to origin/master

If behind: `git rebase origin/master`

### Step 4: Enumerate worktrees

Run `git worktree list`. For each worktree:
- Get branch name
- Check if clean or dirty
- Count commits ahead of master

### Step 5: Merge worktree work

For each worktree with commits ahead of master:
- Show the commits
- Ask the user if they should be merged
- If yes: `git merge {branch} --no-ff`

### Step 6: Sync worktrees to master

For each worktree:
- `git -C {worktree-path} merge master` to pick up new work

### Step 7: Report

Present a status table:

```
Sync complete:

Worktree          Branch              Status    Merged    Synced
──────────────────────────────────────────────────────────────────
fix-auth          fix-auth            clean     3 commits yes
proto-tooling     proto/tooling       dirty     skipped   yes
```

### Step 8: Update handoff

Locate the captain handoff file (glob `usr/*/captain/handoff.md`). Update with sync status (lightweight update — just what happened, not a full rewrite).
