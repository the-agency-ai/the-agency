---
description: Run after a PR is merged on GitHub. Verifies merge, merges origin into master, invokes /sync-all.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

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

### Step 6: Create GitHub release

**Every PR is a release.** This step is mandatory.

1. Parse the PR title for the release name (e.g., "D39-R1: ...")
2. Extract the day and release number from the branch name or title (e.g., D39-R1 → version 39.1)
3. Verify `claude/config/manifest.json` has the correct `agency_version`. The version bump should have been done BEFORE the PR was created (in `/pr-prep` or `/ship`). If it wasn't, **stop and warn** — do not push to main to fix it. Create a follow-up PR instead.
4. Create GitHub release: `gh release create v{version} --title "{PR title}" --notes "{release notes}" --target main`
   - Release notes: summarize the PR description, list key changes
5. Verify release: `gh release view v{version}`

If the version format doesn't match D#-R# (e.g., a hotfix PR), use the PR number as the version suffix (e.g., v39.pr78).

**Never push directly to main.** If the version is wrong, create a follow-up PR.

### Step 7: Clean up PR branch

If the PR's head branch still exists locally:
- `git branch -d {branch}` (safe delete)
- If it refuses (unmerged), note it and move on

### Step 8: Report

```
Post-merge complete:
  PR: #{number} ({title})
  Version: {old} → {new}
  Release: v{version} created on GitHub
  Master: merged with origin/master ({commit})
  Worktrees: synced via /sync-all
  Branch cleanup: {branch} deleted/kept
```
