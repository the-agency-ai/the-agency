---
description: Fetch, merge origin into master, merge worktree work into master, sync all worktrees. NEVER pushes.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Sync All — Local Master Sync

Fetch, merge origin into master, merge unique worktree work into master, and sync all worktrees. This is the daily rhythm command. **NEVER pushes to remote. NEVER rebases. NEVER resets to origin.**

## Steps

### Step 1: Safety checks

1. Must be on master: `git rev-parse --abbrev-ref HEAD` must return `master` (or `main`).
2. Must be in the main checkout (not a worktree).
3. Must have a clean working tree.

### Step 2: Fetch origin

Run `git fetch origin`.

### Step 3: Divergence detection

Check if master has diverged from origin/master:
- `git log --oneline origin/master..master` — local-only commits
- `git log --oneline master..origin/master` — remote-only commits

If diverged (squash PR scenario):
1. **Guard: verify merge-base exists.** Run `git merge-base origin/master HEAD`. If this fails (exit code 1 — no common ancestor), ABORT: "ERROR: No common ancestor. Run `git merge --allow-unrelated-histories origin/master` manually."
2. Tag for recovery: `git tag sync/pre-merge-$(date +%Y%m%d-%H%M%S)`
3. Merge: `git merge origin/master -m "Merge origin/master (post-squash-PR sync)"`
4. If conflicts: `git merge --abort`, report, ask user. Do NOT auto-resolve.
5. No worktree rebase needed — worktrees pick up changes via `git merge master`.

If behind only: `git merge origin/master`

**Never `git reset --hard origin/master`. Never `git rebase origin/master`.** See `claude/docs/GIT-MERGE-NOT-REBASE.md`.

### Step 4: Enumerate worktrees

Run `git worktree list`. For each worktree:
- Get branch name
- Check if clean or dirty
- Count commits ahead of master

### Step 5: Merge worktree work

For each worktree with commits ahead of master:
- Show the commits
- Ask the user if they should be merged
- If yes: `git merge {branch} --no-ff`

### Step 5b: Dispatch main-updated

If any worktree work was merged in Step 5, dispatch `main-updated` to all agents that have worktrees:

For each worktree agent that was synced:
```
./claude/tools/dispatch create --type main-updated --to {repo}/{principal}/{agent} --subject "Main updated — new work merged"
```

This notifies agents that main has new content. They'll see it on their next `iscp-check`.

### Step 6: Sync worktrees to master

For each worktree:
- `git -C {worktree-path} merge master` to pick up new work

### Step 7: Report

Present a status table:

```
Sync complete:

Worktree          Branch              Status    Merged    Synced
──────────────────────────────────────────────────────────────────
fix-auth          fix-auth            clean     3 commits yes
proto-tooling     proto/tooling       dirty     skipped   yes
```

### Step 8: Update handoff

Locate the captain handoff file (glob `usr/*/captain/handoff.md`). Update with sync status (lightweight update — just what happened, not a full rewrite).
