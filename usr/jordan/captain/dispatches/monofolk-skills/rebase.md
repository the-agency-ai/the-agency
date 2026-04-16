---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git log:*), Bash(git rev-list:*), Bash(git branch:*), Bash(git worktree:*), Read
description: Rebase current branch onto a target (default: master) — purely local, never pushes
---

# Rebase

Rebase the current branch onto a target branch, with safety checks. Purely local — this command never pushes to any remote.

## Arguments

- $ARGUMENTS: Optional target branch (default: `master`). Examples: `master`, `origin/master`, `origin/develop`.

## Instructions

### Step 0: Parse arguments

If `$ARGUMENTS` is empty, use `master` as the target.

### Step 1: Safety checks

1. **Clean working tree** — `git diff --quiet HEAD` and `git diff --cached --quiet`. If dirty, abort: "You have uncommitted changes. Commit or stash them first."
2. **Branch not checked out elsewhere** — `git worktree list`. If the current branch is checked out in another worktree, warn: "Branch `<branch>` is also checked out in `<path>`. Rebasing may cause issues."

### Step 2: Fetch (only if target is a remote ref)

If the target starts with `origin/`, run `git fetch origin` to get latest refs. Otherwise skip — the target is local.

### Step 3: Show divergence

Run `git rev-list --left-right --count <target>...HEAD` to show how many commits ahead/behind.

Report: "Current branch is X commit(s) ahead and Y commit(s) behind `<target>`."

If already up to date (0 behind), say so and ask if the user still wants to proceed.

### Step 4: Rebase

Run `git rebase <target>`.

### Step 5: Handle result

**If rebase succeeded:**

Report: "Rebased onto `<target>`. Now X commit(s) ahead."

**If rebase hit conflicts:**

1. Run `git status` to show conflicted files.
2. Tell the user: "Rebase paused due to conflicts in the files above."
3. Ask what to do:
   1. "I'll resolve the conflicts" — help the user resolve them
   2. "Abort the rebase" — run `git rebase --abort`
