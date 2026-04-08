---
allowed-tools: Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git merge:*), Bash(git merge-base:*), Bash(git rev-list:*), Bash(git tag:*), Bash(git branch:*), Bash(gh pr:*), Read, Glob, Skill
description: Run after a PR is merged on GitHub. Verifies merge, merges origin into master, invokes /sync-all.
---

# Post-Merge

Run after a PR is merged on GitHub. Verifies the merge, merges origin into master, then invokes `/sync-all`. **Never resets master to origin.** See `claude/docs/GIT-MERGE-NOT-REBASE.md`.

## Arguments

- $ARGUMENTS: PR number (e.g., "48"). If empty, query most recently merged PR via `gh pr list --state merged --limit 1`.

## Trigger

When the user says "merged", "done" (after a PR), or indicates a PR has landed.

## Steps

### Step 1: Safety checks

1. Must be on master.
2. Must be in the main checkout (not a worktree).
3. Must have a clean working tree.

### Step 2: Verify PR merged

Run `gh pr view {number} --json state,mergedAt,mergeCommit`. Confirm state is "MERGED".

### Step 3: Fetch origin

Run `git fetch origin`.

### Step 4: Merge origin/master

Check divergence: `git rev-list --left-right --count origin/master...HEAD`

If diverged (both sides > 0 — expected after squash PR merge):
1. Verify merge-base exists: `git merge-base origin/master HEAD`. If fails, ABORT.
2. Tag for recovery: `git tag sync/pre-merge-$(date +%Y%m%d-%H%M%S)`
3. Merge: `git merge origin/master -m "Merge origin/master (post-PR-merge sync)"`
4. If conflicts: `git merge --abort`, report, ask user.

If behind only: `git merge origin/master`

**Never `git reset --hard origin/master`.** See `claude/docs/GIT-MERGE-NOT-REBASE.md`.

### Step 5: Invoke sync-all

Invoke `/sync-all` via the Skill tool to sync all worktrees.

### Step 6: Clean up PR branch

If the PR's head branch still exists locally:
- `git branch -d {branch}` (safe delete)
- If it refuses (unmerged), note it and move on

### Step 7: Report

```
Post-merge complete:
  PR: #{number} ({title})
  Master: reset to origin/master ({commit})
  Worktrees: synced via /sync-all
  Branch cleanup: {branch} deleted/kept
```
