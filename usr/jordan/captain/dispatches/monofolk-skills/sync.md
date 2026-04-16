---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git push:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git log:*), Bash(git rev-list:*), Bash(git branch:*), Bash(git worktree:*), Read
description: Rebase current branch onto target and push to origin — the explicit push command
---

# Sync

Rebase the current branch onto a target and push to origin with `--force-with-lease`. This is the **only** command that pushes to a remote. It requires explicit confirmation.

## Arguments

- $ARGUMENTS: Optional target branch (default: `origin/master`). Examples: `origin/master`, `main`.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty, use `origin/master` as the target.

### Step 1: Safety checks

1. **Never on master** — `git rev-parse --abbrev-ref HEAD`. If the current branch is `master`, abort: "Cannot /sync master. Changes reach remote master through PRs on GitHub, not direct push."
2. **Clean working tree** — `git diff --quiet HEAD` and `git diff --cached --quiet`. If dirty, abort: "You have uncommitted changes. Commit or stash them first."
3. **Branch not checked out elsewhere** — `git worktree list`. If the current branch is checked out in another worktree, warn.

### Step 2: Fetch

Run `git fetch origin`.

### Step 3: Show what will be pushed

Run `git rev-list --left-right --count <target>...HEAD`.

Report:

```
Branch: <branch>
Target: <target>
Commits to push: X
Behind target: Y
```

If behind, note that a rebase will happen first.

### Step 4: Confirm

Tell the user: "This will rebase `<branch>` onto `<target>` and force-push to `origin/<branch>`. Proceed?"

**Wait for explicit "yes" before continuing.** Do not proceed on ambiguous responses.

### Step 5: Rebase

Run `git rebase <target>`.

If conflicts occur, show status and ask the user how to proceed (same as `/rebase`).

### Step 6: Push

Run `git push origin <branch> --force-with-lease`.

If push fails (e.g., remote has new commits), report the error and suggest re-running `/sync`.

### Step 7: Report

```
Synced:
  Branch: <branch>
  Rebased onto: <target>
  Pushed to: origin/<branch>
  Commits ahead: X
```
