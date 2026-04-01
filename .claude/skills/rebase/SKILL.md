---
allowed-tools: Bash(git rebase:*), Bash(git fetch:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git stash:*), Read, Glob, Grep
description: Rebase current branch onto a target branch with safety checks. Purely local — never pushes.
---

# Rebase

Rebase the current branch onto a target branch (default: master) with safety checks. Purely local — never pushes.

## Arguments

- $ARGUMENTS: Optional target branch (default: `master`). Examples: `master`, `origin/master`, `origin/develop`.

## Steps

### Step 1: Safety checks

1. Verify working tree is clean: `git status --porcelain`. If dirty, ask the user to commit or stash.
2. Get current branch: `git rev-parse --abbrev-ref HEAD`. If detached HEAD, abort.
3. If on master, abort: "Cannot rebase master onto itself. Switch to a feature branch first."

### Step 2: Fetch (if remote target)

If the target starts with `origin/`, run `git fetch origin` first.

### Step 3: Show divergence

Run `git log --oneline HEAD..{target}` and `git log --oneline {target}..HEAD` to show:
- How many commits the target has that we don't
- How many commits we have that the target doesn't

### Step 4: Rebase

Run `git rebase {target}`.

If conflicts occur:
- Show the conflicting files
- Ask the user to resolve, then `git rebase --continue`
- Or offer `git rebase --abort` to cancel

### Step 5: Report

```
Rebase complete:
  Branch: {current} rebased onto {target}
  Commits replayed: N
```
