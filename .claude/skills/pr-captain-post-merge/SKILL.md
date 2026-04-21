---
name: pr-captain-post-merge
description: Captain-only. After a PR has merged on GitHub, verify the merge, merge origin/master locally, sync all worktrees, create the GitHub release (every PR is a release), and clean up the PR branch. Formerly `/post-merge` — v2 rename to noun-actor-verb.
agency-skill-version: 2
when_to_use: Captain on master in main checkout, immediately after a PR has merged on GitHub. Triggered when principal says "merged" / "done" / indicates a PR landed, or as Step 8 of /pr-captain-land. NEVER from a worktree. NEVER auto-invoked.
argument-hint: "<pr-number>"
paths: []
required_reading:
  - agency/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - agency/REFERENCE-WORKTREE-DISCIPLINE.md
  - agency/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools omitted — inherits Bash(*) from .claude/settings.json.
  Subcommand-level restriction silently blocks fleet agents (flag #62/#63
  / devex dispatch #171 / the-agency#298 caveat). This skill touches
  gh, git-captain, git-safe, gh-release, sync-all (sub-skill), and
  branch-delete — broad surface that would require maintenance at
  subcommand level. Inherit Bash(*).
-->

# pr-captain-post-merge

Captain's post-merge flow. Runs after a PR has landed on GitHub to verify the merge, reconcile master locally, propagate to worktrees, create the GitHub release, and clean up the PR branch.

**Name pattern:** `pr-` prefix groups with the PR skill family (autocomplete `/pr<tab>`), `captain-` qualifier flags captain-only scope, `post-merge` describes the action.

## Why this exists

After a PR merges on GitHub, several things must happen locally and across the fleet:

- Master must be reconciled with origin/master (the merge commit landed upstream)
- All worktrees must sync so agents pick up the merged work
- A GitHub release must be created (every PR is a release — CI enforces this via `release-tag-check` workflow)
- The PR branch should be cleaned up so it doesn't linger

Without this skill, each step is manual and skippable. The `release-tag-check` workflow in particular will turn main CI red if a merge lands without a release tag. This skill ensures every merge has a release.

**Never resets master to origin** — per `REFERENCE-GIT-MERGE-NOT-REBASE.md`, we merge, never reset.

## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter. `GIT-MERGE-NOT-REBASE.md` explains the merge discipline that this skill enforces. `WORKTREE-DISCIPLINE.md` covers the fleet propagation step.

## Usage

```
/pr-captain-post-merge <pr-number>
```

If `<pr-number>` is omitted, the skill queries `gh pr list --state merged --limit 1` for the most recently merged PR and confirms with the user before proceeding.

## Preconditions

- Captain on master (not main, though either is accepted per `REFERENCE-GIT-MERGE-NOT-REBASE.md` convention resolution).
- In the main checkout, NOT a worktree.
- Working tree clean.
- PR has actually merged on GitHub (`gh pr view <N>` returns state `MERGED`).
- `agency/config/manifest.json` version was bumped BEFORE the PR was created (via `/pr-prep` or `/release` or `/pr-captain-land`). If not, skill stops and warns — do NOT push directly to main to fix; create a follow-up PR instead.

## Flow / Steps

### Step 1: Safety checks

1. Confirm on master in main checkout.
2. Confirm clean working tree.
3. If PR number is omitted, query most recent merged PR and confirm.

### Step 2: Verify PR merged

```
gh pr view <N> --json state,mergedAt,mergeCommit
```

Confirm `state` is `MERGED`. If not, stop.

### Step 3: Fetch origin

```
./agency/tools/git-captain fetch origin
```

### Step 4: Merge origin/master

Check divergence:

```
git rev-list --left-right --count origin/master...HEAD
```

- **If diverged** (both sides > 0 — expected after squash or rebase PR):
  1. Verify merge-base exists: `git merge-base origin/master HEAD`. If fails, ABORT.
  2. Tag for recovery: `git tag sync/pre-merge-$(date +%Y%m%d-%H%M%S)`
  3. Merge: `./agency/tools/git-captain merge-from-origin` (produces merge commit per framework discipline).
  4. If conflicts: skill halts, reports, asks principal to resolve.
- **If behind only**: `./agency/tools/git-captain merge-from-origin` fast-forwards cleanly.

**Never `git reset --hard origin/master`.** Per `REFERENCE-GIT-MERGE-NOT-REBASE.md`, we never rewrite history.

### Step 5: Invoke /sync-all

```
/sync-all
```

Propagates the merge to every worktree. Worktree-side agents pick up the new content on their next `/session-resume`.

### Step 6: Create GitHub release

**Every PR is a release.** MANDATORY. Mechanically enforced by `release-tag-check` workflow (the-agency equivalent of D41-R20).

1. Parse PR title for release name (e.g., "D39-R1: ..." → version 39.1).
2. Verify `manifest.json` version matches expectations (bumped before the PR was created).
3. Create release:
   ```
   ./agency/tools/gh-release create v<version> --target master --title "<title>" --notes "<notes>"
   ```
4. **Hard-verify** release exists (fail-loud, not optional):
   ```
   gh release view v<version>
   ```
   If non-zero, the release was NOT created. Do NOT proceed to Step 7. Fix and retry.

5. **Clear pending-post-merge state (C#372 Fix B).** Once the release is hard-verified:
   ```
   ./agency/tools/post-merge-state clear <pr-number>
   ```
   This unblocks the new-work captain skills (`/pr-captain-merge`, `/captain-release`, `/pr-captain-land`) that were refusing while this merge was in pending state. Clearing is tied to `gh release view` succeeding — NOT to the skill exiting — so a partial post-merge that created the release but failed later still unblocks correctly.

If version format doesn't match `D#-R#` (e.g., hotfix PR), use `v<agency_version>.pr<N>` as fallback.

**Never push directly to main.** If version is wrong, create a follow-up PR.

### Step 7: Clean up PR branch

If the PR's head branch still exists locally:

```
./agency/tools/git-captain branch-delete <branch> --force
```

`--force` required — the local PR branch typically has commits not reachable from main's history (QGR receipts, dispatch artifacts). Safe `-d` would refuse.

If the branch doesn't exist locally (e.g., captain used `pr-merge --delete-branch` already), this step is a no-op.

### Step 8: Report

```
Post-merge complete:
  PR:             #<N> (<title>)
  Version:        <old> → <new>
  Release:        v<version> created at <url>
  Master:         synced with origin/master (<sha>)
  Worktrees:      synced via /sync-all
  Branch cleanup: <branch> deleted / kept
```

## Failure modes

- **PR not merged on GitHub:** Step 2 fails. Skill reports state and stops. Captain investigates.
- **Merge-base missing:** Step 4 aborts. Usually means force-push or squash obliterated shared history. Principal decides recovery.
- **Merge conflict in Step 4:** Skill halts after `git-captain merge-from-origin` reports conflict. Captain resolves manually, then re-runs from Step 4.
- **Release creation fails (Step 6):** CRITICAL. Skill refuses to proceed to Step 7. Captain investigates (token? network? gh-release tool error?). Releases MUST land before branch cleanup.
- **Manifest version not bumped:** Step 6 warns + stops. Create a follow-up PR to bump. Never push directly to main.
- **Branch cleanup fails:** Step 7 warn + continue (cleanup is nice-to-have; release is the gate).

## What this does NOT do

- **Does not merge the PR itself** — that's `/pr-captain-merge`.
- **Does not create the PR** — that's `/pr-captain-create` (or agent-side via `/pr-submit` → `/pr-captain-land`).
- **Does not rewrite history** — no squash, no rebase, no hard reset.
- **Does not push directly to main** — version mismatches require follow-up PR, not direct push.
- **Does not run the quality gate** — QG happened during `/pr-prep` pre-PR.

## Captain-only — four-layer defense

1. **`disable-model-invocation: true`** — Claude can't auto-invoke. Captain types it.
2. **`paths: []`** — no auto-activation from any file path.
3. **Name contains `captain-`** — visible scope in the skill listing.
4. **Runtime precondition** — Step 1 refuses if not on master in main checkout.

## Status

`active` (v2, post-refactor from legacy `post-merge` 2026-04-19).

## Related

- `/pr-captain-merge` — the merge itself, runs before this skill
- `/pr-captain-land` — the full captain-owned PR lifecycle (this skill is Step 8 of that flow)
- `/sync-all` — the fleet-sync sub-skill this calls in Step 5
- `/release` (TBD refactored to `/captain-release`) — alternate entry point that runs /pr-captain-merge + this skill in one flow
- `agency/tools/gh-release` — the release-creation tool
- `agency/tools/git-captain` — safe captain-side git operations
- `agency/REFERENCE-GIT-MERGE-NOT-REBASE.md` — the merge discipline
- the-agency#296 — PR lifecycle ownership (Phase 1 pilot context)
- the-agency#315 — V1→V2 migration (this refactor lives under Tier 1)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
