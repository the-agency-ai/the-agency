---
name: captain-sync-all
description: Captain-only. Fetch, merge origin into master, merge unique worktree work into master, and sync all worktrees. The daily rhythm command. NEVER pushes to remote. NEVER rebases. NEVER resets to origin. Formerly `/sync-all` — v2 rename to captain-actor-verb.
agency-skill-version: 2
when_to_use: |
  Captain on master in main checkout, NEVER from a worktree. Invoke after ANY of these triggers:
    - PR merge (called automatically as Step 5 of /pr-captain-post-merge)
    - Agent /iteration-complete, /phase-complete, /plan-complete in any worktree
    - Agent /seed, /define, /design, /plan completion in any worktree
    - Start of a captain session, to catch overnight drift
  Not auto-invoked — captain types it. See CLAUDE-CAPTAIN.md "Standing Duty — Worktree Integration Rhythm".
argument-hint: "(no args)"
paths: []
required_reading:
  - agency/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - agency/REFERENCE-WORKTREE-DISCIPLINE.md
  - agency/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools omitted — inherits Bash(*). Composes git-captain +
  git-safe + dispatch + worktree-sync across every worktree. Too broad
  to restrict at subcommand level (flag #62/#63 caveat).
-->

# captain-sync-all

Captain's daily master-sync rhythm command. Reconciles master with origin, merges any unique worktree work into master (with confirmation), and syncs every worktree to the updated master. **Never pushes.** Push is a separate concern (merged PRs land on master server-side).

**Name pattern:** `captain-` actor prefix (captain-only) + `sync-all` (compound noun-verb, the action). Grouped with `captain-release`, `captain-log`, `captain-review` in the captain family.

## When to invoke — the trigger list

Captain runs `/captain-sync-all` after **any** of these events:

| Trigger | Emitted by | Scope |
|---|---|---|
| PR merge | GitHub | Automatic — `/pr-captain-post-merge` invokes this as its Step 5 |
| `/iteration-complete` | worktree agent | Integrate committed iteration work |
| `/phase-complete` | worktree agent | Integrate principal-approved phase commit |
| `/plan-complete` | worktree agent | Integrate plan-level milestone |
| `/seed` completion | worktree agent | Share seed artifact with fleet |
| `/define` completion | worktree agent | Share PVR with fleet |
| `/design` completion | worktree agent | Share A&D with fleet |
| `/plan` completion | worktree agent | Share plan with fleet |
| Session start | captain | Catch overnight drift before other work |

Two critical distinctions, mirrored in CLAUDE-CAPTAIN.md "Standing Duty":

1. **Dirty files ≠ no committed work.** A worktree can be dirty (WIP) AND have commits ahead of master. The WIP stays; the commits integrate. Do not skip a worktree just because it's dirty.
2. **Parked worktrees are intentional.** Worktrees with tracked structural debt (e.g., Great-Rename path debt on 5 branches under Bucket G #402) MUST NOT be merged — conflicts are known and handled by the dedicated workstream's tooling, not by this skill.

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
./agency/tools/git-captain fetch
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
3. Merge: `./agency/tools/git-captain merge-from-origin` (produces merge commit).
4. If conflicts: halt, show files, ask principal to resolve.

**If behind only:** `./agency/tools/git-captain merge-from-origin` fast-forwards.

**Never `git reset --hard origin/master`. Never `git rebase origin/master`.**

### Step 4: Enumerate worktrees

For each worktree, determine: branch name, clean/dirty status, commits ahead of master.

### Step 5: Merge worktree work (with confirmation)

For each worktree with commits ahead of master:

- Show the commits.
- Ask principal for confirmation.
- If yes: `git merge <branch> --no-ff`.

### Step 5b: Dispatch master-updated

If any worktree work merged into master in Step 5, dispatch `master-updated` to all agents with worktrees:

```
./agency/tools/dispatch create --type master-updated --to <repo>/<principal>/<agent> --subject "Master updated — new work merged"
```

Note: `master-updated` is the canonical dispatch type. Legacy docs may say `main-updated`; the dispatch tool aliases that to `master-updated` for backward compatibility.

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

## Captain-only — three-layer defense

1. `paths: []` — no file-path auto-activation; universally discoverable for the captain but scoped out of agent worktree contexts.
2. Name contains `captain-` — scope visible at a glance in skill listings.
3. Step 1 precondition — must be on master in main checkout; refuses otherwise.

(Historically `disable-model-invocation: true` was a fourth layer. That flag was removed 2026-04-20 because the captain session IS the principal's session — DMI was blocking the captain from invoking captain-* skills. See `REFERENCE-SKILL-CONVENTIONS.md` §1.)

## Status

`active` (v2, refactored from legacy `sync-all` 2026-04-19).

## Related

- `/pr-captain-post-merge` — invokes this as Step 5 after a merge
- `/sync` — agent-side push skill (different scope entirely)
- `/worktree-sync` — single-worktree sync (agent-side; this skill calls it across all worktrees)
- `agency/tools/git-captain` — safe captain-side git operations
- `agency/REFERENCE-GIT-MERGE-NOT-REBASE.md` — the merge discipline
- `agency/REFERENCE-WORKTREE-DISCIPLINE.md` — worktree model

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
