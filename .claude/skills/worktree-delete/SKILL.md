---
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git status:*), Bash(git rev-parse:*), Read, Glob
description: Remove a git worktree and optionally delete its branch
---

# Delete Worktree

Remove a git worktree from `.claude/worktrees/` and optionally clean up its branch.

## Arguments

- $ARGUMENTS: The worktree name to delete (e.g., `fix-auth-bug`).

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty, list worktrees and ask which to delete.

### Step 1: Validate

1. Verify `.claude/worktrees/<name>/` exists as a git worktree.
2. Check for uncommitted changes. If dirty, warn and ask to confirm.

### Step 2: Determine the branch

Get branch name from the worktree.

### Step 3: Remove the worktree

1. `git worktree remove .claude/worktrees/<name>` (add `--force` only if user confirmed dirty deletion)
2. `git worktree prune`

### Step 4: Offer branch cleanup

Ask:
> Delete branch `<branch>` as well?
> 1. Yes — safe delete (`git branch -d`)
> 2. Yes — force delete (`git branch -D`)
> 3. No — keep the branch

### Step 5: Report

```
Worktree deleted:
  Path:   .claude/worktrees/<name>/ (removed)
  Branch: <branch> (deleted/kept)
```
