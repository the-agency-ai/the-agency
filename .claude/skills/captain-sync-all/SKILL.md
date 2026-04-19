---
name: captain-sync-all
description: Captain-only. Fetch, merge origin into master, merge unique worktree work into master, and sync all worktrees. The daily rhythm command. NEVER pushes to remote. NEVER rebases. NEVER resets to origin. Formerly `/sync-all` — v2 rename to captain-actor-verb.
agency-skill-version: 2
when_to_use: Captain on master in main checkout, starting a captain session or after a PR has merged (to propagate to the fleet). NEVER from a worktree. NEVER auto-invoked.
argument-hint: ""
paths: []
disable-model-invocation: true
required_reading:
  - claude/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - claude/REFERENCE-WORKTREE-DISCIPLINE.md
  - claude/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools omitted — inherits Bash(*). Composes git-captain +
  git-safe + dispatch + worktree-sync across every worktree. Too broad
  to restrict at subcommand level (flag #62/#63 caveat).
-->

# captain-sync-all

Captain's daily master-sync rhythm command. Reconciles master with origin, merges any unique worktree work into master (with confirmation), and syncs every worktree to the updated master. **Never pushes.** Push is a separate concern (merged PRs land on master server-side).

**Name pattern:** `captain-` actor prefix (captain-only) + `sync-all` (compound noun-verb, the action). Grouped with `captain-release`, `captain-log`, `captain-review` in the captain family.

## Why this exists

Captain is the single coordination point for master state across the fleet. After a PR lands on GitHub or after captain-side coord commits, the local master + every worktree's local view of master must be reconciled. Without this skill, each worktree drifts independently and sync-pain accumulates.

**Never pushes.** Pushing from master is structurally banned by the framework. PR-merged commits reach origin/master via GitHub's merge; local sync pulls those down.

**Never rebases, never resets to origin.** Per `REFERENCE-GIT-MERGE-NOT-REBASE.md`, all sync uses true merge commits.

## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter.

## Usage

```
/captain-sync-all
```

No arguments. Skill is fully automatic; prompts for confirmation before merging worktree work into master.

## Preconditions

- Captain on master (or main) in main checkout. NOT a worktree.
- Working tree clean. No uncommitted changes on master.

## Flow / Steps

### Step 1: Safety checks

1. Confirm on master in main checkout.
2. Confirm clean working tree.

### Step 2: Fetch origin

```
./claude/tools/git-captain fetch
```

### Step 3: Divergence detection + reconcile

Check divergence:

```
git log --oneline origin/master..master    # local-only commits
git log --oneline master..origin/master    # remote-only commits
```

**If diverged (both sides > 0 — typical after PR merge + local coord commits):**

1. Verify merge-base exists: `git merge-base origin/master HEAD`. If fails, ABORT with recovery hint.
2. Tag for recovery: `git tag sync/pre-merge-$(date +%Y%m%d-%H%M%S)`.
3. Merge: `./claude/tools/git-captain merge-from-origin` (produces merge commit).
4. If conflicts: halt, show files, ask principal to resolve.

**If behind only:** `./claude/tools/git-captain merge-from-origin` fast-forwards.

**Never `git reset --hard origin/master`. Never `git rebase origin/master`.**

### Step 4: Enumerate worktrees

For each worktree, determine: branch name, clean/dirty status, commits ahead of master.

### Step 5: Merge worktree work (with confirmation)

For each worktree with commits ahead of master:

- Show the commits.
- Ask principal for confirmation.
- If yes: `git merge <branch> --no-ff`.

### Step 5b: Dispatch main-updated

If any worktree work merged into master in Step 5, dispatch `main-updated` to all agents with worktrees:

```
./claude/tools/dispatch create --type main-updated --to <repo>/<principal>/<agent> --subject "Main updated — new work merged"
```

Agents see this on their next `iscp-check` / `/session-resume`.

### Step 6: Sync worktrees to master

For each worktree: `git -C <worktree-path> merge master`. Picks up new master content.

### Step 7: Report

Present status table:

```
Sync complete:

Worktree          Branch              Status    Merged    Synced
-----------------------------------------------------------------
fix-auth          fix-auth            clean     3 commits yes
proto-tooling     proto/tooling       dirty     skipped   yes
```

### Step 8: Update handoff

Light update to captain handoff: "what synced, what was merged into master, any worktrees skipped."

## Failure modes

- **Not on master**: abort with clear error.
- **Dirty working tree**: abort; asks principal to commit or stash.
- **Merge-base missing**: abort (usually force-push or filter-repo incident); principal decides recovery.
- **Step 3 merge conflict**: halt; principal resolves, captain re-runs skill.
- **Worktree merge conflict in Step 5**: report, skip that worktree, continue with others. Principal resolves later.
- **Worktree sync conflict in Step 6**: report that worktree as NOT synced. Agent will resolve on their next /session-resume.

## What this does NOT do

- **Does not push.** Push happens via PR merges server-side.
- **Does not rebase.** All sync uses merge commits.
- **Does not reset to origin.** Preserves local history.
- **Does not force-sync**: conflicts halt the process; no forced resolution.
- **Does not write commits on worktree branches** (other than merge-master commits).

## Captain-only — four-layer defense

1. `disable-model-invocation: true` — Claude can't auto-invoke.
2. `paths: []` — no auto-activation.
3. Name contains `captain-`.
4. Step 1 precondition — must be on master in main checkout.

## Status

`active` (v2, refactored from legacy `sync-all` 2026-04-19).

## Related

- `/pr-captain-post-merge` — invokes this as Step 5 after a merge
- `/sync` — agent-side push skill (different scope entirely)
- `/worktree-sync` — single-worktree sync (agent-side; this skill calls it across all worktrees)
- `claude/tools/git-captain` — safe captain-side git operations
- `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md` — the merge discipline
- `claude/REFERENCE-WORKTREE-DISCIPLINE.md` — worktree model

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
