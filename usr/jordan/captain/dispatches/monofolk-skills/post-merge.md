---
allowed-tools: Bash(git fetch:*), Bash(git checkout:*), Bash(git reset:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git diff:*), Bash(git status:*), Bash(git worktree:*), Bash(git -C:*), Bash(git branch:*), Bash(git tag:*), Bash(gh pr view:*), Read, Skill
description: Post-merge sync — verify PR merged, fetch, reset master, then delegate worktree sync to /sync-all
---

# Post-Merge Sync

Run this after a PR is merged on GitHub. Verifies the merge, resets master to origin, then invokes `/sync-all` to handle worktree synchronization.

**Trigger:** When the user says "merged", "done" (after a PR), or any indication a PR has landed.

## Arguments

- $ARGUMENTS: PR number (e.g., "48"). If empty, query the most recently merged PR via `gh pr list --state merged --limit 1 --json number,title`.

## Instructions

### Step 1: Safety checks

All must pass:

1. **Must be on master** — `git rev-parse --abbrev-ref HEAD`. If not, `git checkout master`. If fails, abort.
2. **Must be main checkout** — `git rev-parse --git-dir` must equal `.git`. If not, abort: "Run from main checkout."
3. **Clean working tree** — `git diff --quiet HEAD` AND `git diff --cached --quiet`. If either fails, abort.

### Step 2: Verify the PR merged

```
gh pr view <number> --json state,mergedAt,mergeCommit,headRefName
```

If `state` is not `MERGED`, abort: "PR #N is not merged yet."

Capture `headRefName` for branch cleanup in Step 6.
Report: "PR #N merged at <mergedAt>, commit <sha>."

### Step 3: Fetch origin

```
git fetch origin
```

### Step 4: Tag and reset master

Check for unshipped local work:

```
git rev-list --left-right --count origin/master...HEAD
```

**If master has ANY local-only commits (master-only > 0):** tag before resetting:

```
git tag sync/pre-reset-{YYYYMMDD-HHMMSS}
```

Reset:

```
git reset --hard origin/master
```

Verify:

```
git rev-list --left-right --count origin/master...HEAD
```

Must be `0 0`. If not, abort.

### Step 5: Invoke `/sync-all`

Invoke `/sync-all` via the Skill tool. This handles ALL worktree synchronization:

- Divergence detection (Step 2.5)
- Worktree enumeration
- Merge, rebase, or reset as appropriate
- Dirty worktree handling
- Report

`/sync-all` owns worktree management. `/post-merge` does NOT touch worktrees directly.

### Step 6: Clean up PR branch

Get branch name from Step 2 (`headRefName`).

If exists locally (`git branch --list '<name>'`):

- Try `git branch -d <name>`
- If fails (expected after squash merge): ask user "Branch was squash-merged. Delete with -D?" Require confirmation.

### Step 7: Report

```
Post-merge sync complete:

  PR:     #N merged (<sha>) — branch: <headRefName>
  Master: <sha> = origin/master ✓
  Branch: <headRefName> deleted ✓

  /sync-all results:
  (included from Step 5 output)
```
