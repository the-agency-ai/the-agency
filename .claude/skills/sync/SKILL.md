---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git push:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Read
description: Rebase current branch onto target and push to origin with --force-with-lease. The ONLY command that pushes.
---

# Sync — Push to Origin

Rebase current branch onto target and push to origin with `--force-with-lease`. This is the **only** command that pushes to a remote. Requires explicit confirmation.

## Arguments

- $ARGUMENTS: Optional target branch (default: `origin/master`).

## Steps

### Step 1: Safety checks

1. Get current branch. If on master, **abort**: "Never push directly to master. Use a PR."
2. Verify clean working tree.
3. Verify not checked out in another worktree.

### Step 2: Fetch

Run `git fetch origin`.

### Step 3: Show what will be pushed

Run `git log --oneline origin/{current-branch}..HEAD` (if remote tracking exists) or `git log --oneline {target}..HEAD`.

Show the commits that will be pushed.

### Step 4: Confirm

Ask the user:
> Push {N} commits to origin/{branch} with --force-with-lease?

**Do not push without explicit confirmation.**

### Step 5: Rebase

Run `git rebase {target}`. Handle conflicts (show, ask user to resolve or abort).

### Step 6: Push

Run `git push origin {branch} --force-with-lease`.

### Step 7: Report

```
Sync complete:
  Branch: {branch}
  Pushed: N commits to origin/{branch}
  Base: {target}
```
