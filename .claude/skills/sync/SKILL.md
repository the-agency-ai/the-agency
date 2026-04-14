---
description: Merge target into current branch and push to origin. The ONLY command that pushes.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sync — Push to Origin

Merge target into current branch and push to origin. This is the **only** command that pushes to a remote. Requires explicit confirmation. **Never rebases.** See `claude/docs/GIT-MERGE-NOT-REBASE.md`.

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
> Merge {target} into {branch} and push to origin/{branch}?

**Do not push without explicit confirmation.**

### Step 5: Merge

Run `git merge {target}`. Handle conflicts (show, ask user to resolve or abort).

### Step 6: Push

Run `git push origin {branch}`.

### Step 7: Report

```
Sync complete:
  Branch: {branch}
  Pushed: N commits to origin/{branch}
  Base: {target}
```
