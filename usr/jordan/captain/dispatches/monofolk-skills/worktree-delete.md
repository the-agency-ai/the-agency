---
allowed-tools: Bash(git worktree:*), Bash(git branch:*), Bash(git status:*), Bash(git rev-parse:*), Read, Glob
description: Remove a git worktree and optionally delete its branch
---

# Delete Worktree

Remove a git worktree from `.worktrees/` and optionally clean up its branch.

## Arguments

- $ARGUMENTS: The worktree name to delete (e.g., `fix-auth-bug`)

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty:

1. Run `git worktree list` and show worktrees under `.worktrees/`.
2. Ask: "Which worktree do you want to delete?"

### Step 1: Validate

1. Verify `.worktrees/<name>/` exists as a git worktree.
2. Check for uncommitted changes: `git status --porcelain` in the worktree directory.
3. If dirty, warn the user: "This worktree has uncommitted changes. Deleting will discard them." Ask to confirm.

### Step 2: Determine the branch

Run `git rev-parse --abbrev-ref HEAD` in the worktree to get the branch name.

### Step 3: Remove the worktree

1. `git worktree remove .worktrees/<name>` (add `--force` only if the user confirmed deletion of a dirty worktree)
2. `git worktree prune`

### Step 4: Offer branch cleanup

Ask the user:

> Delete branch `<branch>` as well?
>
> 1. Yes — safe delete (`git branch -d`, will refuse if unmerged)
> 2. Yes — force delete (`git branch -D`, even if unmerged)
> 3. No — keep the branch

Execute the chosen option.

### Step 5: Report

```
Worktree deleted:
  Path:   .worktrees/<name>/ (removed)
  Branch: <branch> (deleted/kept)
```
