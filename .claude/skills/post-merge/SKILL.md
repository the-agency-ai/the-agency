---
allowed-tools: Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git reset:*), Bash(git tag:*), Bash(git branch:*), Bash(gh pr:*), Read, Glob, Skill
description: Run after a PR is merged on GitHub. Verifies merge, resets master, invokes /sync-all.
---

# Post-Merge

Run after a PR is merged on GitHub. Verifies the merge, resets master to origin, then invokes `/sync-all`.

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

### Step 4: Reset master

If master has local-only commits (ahead of origin/master):
1. Tag before resetting: `git tag sync/pre-reset-$(date +%Y%m%d-%H%M%S)`
2. `git reset --hard origin/master`

If master is behind: just `git rebase origin/master`.

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
