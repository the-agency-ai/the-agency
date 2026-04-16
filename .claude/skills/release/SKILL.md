---
description: Quality-check, commit, push, create PR, and cut a release in one flow.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Release

Quality-check, commit, push, create PR, and cut a release in one flow. The "code is ready" command. **Every PR is a release.**

## Arguments

- $ARGUMENTS: May contain `--no-push` (skip push) or `--no-pr` (skip PR creation). Remaining text is the commit description.

## Steps

### Step 1: Pre-flight

1. Get current branch. If on master, abort.
2. Show `git status` and `git diff --stat HEAD`.
3. If no changes, tell the user and stop.

### Step 2: Quality gate

Run `./claude/tools/commit-precheck` to verify formatting, linting, and tests pass.

If any check fails, stop and report the failures. Do not proceed.

### Step 3: Commit

Invoke `/git-safe-commit` via the Skill tool. Pass any commit description from `$ARGUMENTS`.

### Step 4: Push (unless --no-push)

If `--no-push` was NOT passed:
1. Show what will be pushed: `git log --oneline origin/{branch}..HEAD`
2. Ask for confirmation
3. `./claude/tools/git-push --force-with-lease {branch}`

### Step 5: PR (unless --no-pr)

If `--no-pr` was NOT passed and a push happened:
1. Check if a PR already exists: `gh pr view {branch}`
2. If exists: report the PR URL
3. If not: create one with `./claude/tools/pr-create --title "..." --body "..."`

**Never raw `gh pr create`.** The `pr-create` tool validates a QGR receipt exists before allowing PR creation. If no QGR is found, it blocks — run `/pr-prep` first.

### Step 6: Version bump

1. Parse the PR title for the release version (D#-R# → version #.#)
2. Update `claude/config/manifest.json`:
   - Bump `project_version` for product/adopter changes
   - Bump `agency_version` for framework changes (the-agency repo only)
   - Update `updated_at` timestamp
3. Commit the version bump
4. Push the version bump: `./claude/tools/git-push {branch}`

### Step 7: Summary

```
Release complete:
  Committed: {commit-hash} {message}
  Version: {old} → {new}
  Pushed: origin/{branch}
  PR: {url} (or skipped)
  Post-merge: run /post-merge after PR is merged to create GitHub release
```
