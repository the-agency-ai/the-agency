---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-list:*), Bash(git branch:*), Bash(git worktree:*), Bash(git -C:*), Bash(git reset:*), Bash(git merge:*), Bash(git merge-base:*), Bash(git tag:*), Read
description: Fetch, rebase master onto origin, merge worktree work into master, and sync all worktrees — purely local, never pushes
---

# Sync All

Fetch from origin, rebase master, merge unique worktree work into master, and bring all worktrees in sync. This is the daily rhythm command.

**This command NEVER pushes to any remote (origin/GitHub). It is purely local.** If a push is needed, the user will run `/sync` or `git push` explicitly.

## Instructions

### Step 1: Safety checks

All three must pass:

1. **Must be on master** — `git rev-parse --abbrev-ref HEAD`. If not on master, abort: "Run /sync-all from the master branch."
2. **Must be main checkout, not a worktree** — `git rev-parse --git-dir` must equal `.git` (not `.git/worktrees/<name>` or similar). If in a worktree, abort: "Run /sync-all from the main repo checkout (`/Users/jordan_of/code/monofolk/`), not a worktree."
3. **Clean working tree** — `git diff --quiet HEAD` and `git diff --cached --quiet`. If either fails, abort: "Master has uncommitted changes. Commit or stash them first." Untracked files are OK.

### Step 2: Fetch

Run `git fetch origin`.

### Step 2.5: Divergence detection and post-merge sync

**This step prevents the squash-PR divergence problem.** When a squash PR is merged on GitHub, origin/master gets a new commit that has no parentage link to local master's merge history. This causes permanent divergence. This step detects it and fixes it automatically.

Run `git rev-list --left-right --count origin/master...HEAD` to get two numbers: `<origin-only> <master-only>`.

**If both sides are > 0 (diverged):** A squash PR was merged on origin but local master still has the old granular history. Fix it now:

1. Report: "Master has diverged from origin — a squash PR was merged. Running post-merge sync..."
2. Tag current master for recovery: `git tag sync/pre-reset-{YYYYMMDD-HHMMSS}`
3. Reset master to origin: `git reset --hard origin/master`
4. For each worktree (from `git worktree list`, excluding the main checkout):
   a. Get the worktree path and branch name
   b. If dirty (`git -C <path> diff --quiet HEAD` fails) → **skip**, report as "needs-attention: dirty working tree"
   c. Count unique commits not on origin: `git rev-list --count origin/master..<branch>`
   d. If 0 unique commits → report "already in sync", skip
   e. Check for merge commits: `git log --merges origin/master..<branch> --oneline`
   f. If merge commits found → warn: "Branch has merge commits — rebase will linearize history"
   g. Rebase: `git -C <path> rebase --onto master origin/master <branch>`
   h. If conflict → `git -C <path> rebase --abort`, report as "needs-attention: rebase conflict", skip
   i. Check for remote tracking branch: `git -C <path> rev-parse --abbrev-ref <branch>@{upstream} 2>/dev/null`
   j. If has remote → note: "force-push required after rebase"
5. Report results table:

```
Post-merge sync complete:

  Worktree           Branch              Unique  Status
  ─────────────────────────────────────────────────────
  .worktrees/folio   folio               3       ✓ rebased
  .worktrees/airm    proto/airm          0       ✓ in sync
  .worktrees/staff   proto/staff         0       ✓ in sync
  .worktrees/catalog proto/catalog       5       ✗ dirty — needs attention

  Recovery tag: sync/pre-reset-20260326-1830
```

6. Prune old sync tags: keep the 5 most recent `sync/pre-reset-*` tags, delete older ones
7. **Skip Step 3** — master was just reset to origin, no rebase needed
8. Proceed to Step 4 (enumerate worktrees) with the post-sync state

**If origin-only = 0 (not diverged):** Fall through to Step 3 normally.

### Step 3: Rebase master onto origin/master

1. Show divergence: `git rev-list --left-right --count origin/master...HEAD`
2. Report ahead/behind counts.
3. If 0 behind, report "master is up to date with origin" and skip rebase.
4. If behind, run `git rebase origin/master`.
5. If conflicts occur, stop and report — do NOT auto-resolve. Show conflicted files and ask the user.

### Step 4: Enumerate worktrees

Run `git worktree list`. For each worktree that is NOT the main repo:

1. Get the worktree path and branch name.
2. Check if the worktree is clean: `git -C <path> diff --quiet HEAD` (modified files) and `git -C <path> diff --cached --quiet` (staged files). Untracked files are OK.
3. Check if already at master: compare `git -C <path> rev-parse HEAD` with `git rev-parse master`. If same SHA, already synced — skip.
4. Check if master is an ancestor of `<branch>`: `git merge-base --is-ancestor master <branch>`.
5. If master IS an ancestor (exit 0): the branch has genuine unique commits ahead. Count them with `git rev-list --count master..<branch>`.
6. If master is NOT an ancestor (exit 1): the branch has **diverged**. This can mean stale SHAs from a prior rebase OR genuinely new work that isn't on master. **Do not assume — always ask the user in Step 5.**

Report a summary table before any merges or syncs:

```
Worktree                  Branch              Status   Unique    Action
────────────────────────────────────────────────────────────────────────
.worktrees/proto-tooling  proto/proto-tooling dirty    —         skip
.claude/worktrees/mycroft worktree-mycroft    clean    0         reset
.worktrees/folio          folio               clean    12        merge then reset
.worktrees/web-audit      tools/web-audit     clean    diverged  ask user
```

### Step 5: Merge worktree work into master

**For worktrees with unique commits ahead of master (master is ancestor):**

1. Show the commits: `git log --oneline master..<branch>`
2. Ask the user: "Branch `<name>` has N unique commits. Merge into master?"
3. If approved: `git merge <branch> -m "Merge branch '<branch>'"`
4. If conflicts occur: stop, report, ask the user to resolve. Do not auto-resolve.
5. If declined: note it in the report and skip the merge. The branch will keep its unique commits.

**For diverged worktrees (master is NOT ancestor):**

Diverged branches can contain genuinely new work that isn't on master. A prior `/sync-all` may have reset the branch, but the branch may have gained new commits since then. **Never assume a diverged branch has no unique work.**

1. Show what the branch has: `git log --oneline <branch> --not master | head -10`
2. Show what master has that the branch doesn't: `git log --oneline master --not <branch> | head -5`
3. Ask the user: "Branch `<name>` has diverged from master. It has N commits not on master, and master has M commits not on it. Options:"
   - **Merge into master then reset** — preserves the branch's work on master, then syncs
   - **Reset to master** — discards the branch's diverged commits (only if the work is already on master or not needed)
   - **Skip** — leave it alone
4. Execute the user's choice.

This ensures no work is silently lost by an automatic reset.

### Step 6: Sync each worktree to master

For each worktree, apply the appropriate strategy:

**If dirty:** Warn and skip. Report: "Skipped `<name>` — dirty working tree. Clean it up and re-run."

**If already at master SHA:** Report "already synced" and skip.

**If 0 unique commits and already handled in Step 5 (merged or user chose reset):**
Reset to master:

```
git -C <path> reset --hard master
```

**CRITICAL: Only reset a branch if its work is confirmed to be on master (merged in Step 5) or the user explicitly approved the reset for a diverged branch in Step 5. Never auto-reset.**

- If the user declined a merge or skipped a diverged branch in Step 5, do NOT touch it
- When in doubt, ask — never silently reset

If a rebase has conflicts, abort the rebase (`git -C <path> rebase --abort`), report the conflict, and continue to the next worktree.

### Step 7: Report

```
Sync complete:

  master:        <commit> (X ahead of origin)
  folio:         <commit> ✓ merged 12 commits, synced
  proto-tooling: <commit> ✗ skipped (dirty)
  mycroft:       <commit> ✓ synced (no unique work)
  web-audit:     <commit> ✓ merged 3 commits, synced

Conflicts: none (or list which worktrees had conflicts)
```

If any worktrees were skipped or had conflicts, remind the user to handle them manually.

### Step 8: Update captain handoff

After the sync report, update `usr/jordan/captain/handoff.md` with a lightweight status update:

- Update the "Active Worktree Status" table with current state (what was merged, what was synced, what was skipped)
- Update the "Last sync" timestamp
- Note any new work that landed on master
- If a post-merge sync ran in Step 2.5, note which worktrees were rebased and any that need attention

This keeps the captain handoff current without a full rewrite.
