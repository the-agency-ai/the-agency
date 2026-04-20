---
title: "D41-R21 — git-captain branch-delete --force (closes #110)"
slug: d41-r21-git-captain-branch-delete-force-closes-110
path: docs/plans/20260415-d41-r21-git-captain-branch-delete-force-closes-110.md
date: 2026-04-15
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
tags: [Infra]
---

# D41-R21 — git-captain branch-delete --force (closes #110)

## Context

Issue #110 (monofolk/jordan/captain): `git-captain branch-delete` uses safe `git branch -d` only and rejects branches with unmerged commits. After a PR is merged on GitHub, the local PR branch contains commits that aren't reachable from main's history (RGR receipts, dispatch artifacts), so safe-delete refuses with "Branch has unmerged changes." Captain hits this on every release cleanup.

I personally hit this 30 minutes ago in this session trying to delete `jordandm-d41-r19`. Real bug.

## Approach

Add `--force` flag to `cmd_branch_delete`. With the flag, use `git branch -D` (force delete). Without, behavior is unchanged (safe `-d`). Update help text. Add BATS coverage including a regression-anchor test that simulates the post-merge scenario.

Also update `/post-merge` skill (Step 7) to document the new flag for the canonical post-merge cleanup case.

## File-level changes

### 1. `claude/tools/git-captain` — `cmd_branch_delete` (lines 296–319)

Parse `--force` / `-f` flag. With flag: `git branch -D`. Without: existing `git branch -d` behavior. Same protections (cannot delete main, cannot delete current branch) apply in both modes.

### 2. `claude/tools/git-captain` — usage block (line 62)

Update to: `branch-delete <name> [--force]   Safe-delete a branch (-d). With --force, force-delete (-D) — for post-merge cleanup of branches with unreachable commits.`

### 3. `tests/tools/git-captain.bats` — extend branch-delete suite

Add cases:
- `branch-delete --force` succeeds on a branch with unmerged commits
- `branch-delete --force` still refuses to delete `main`
- `branch-delete --force` still refuses to delete current branch
- `branch-delete -f` (short form) works
- Help text mentions `--force`

### 4. `.claude/skills/post-merge/SKILL.md` — Step 7

Update the "Clean up PR branch" step to use `git-captain branch-delete --force {branch}` since that's the canonical scenario the flag was added for.

### 5. `claude/config/manifest.json`

Bump `agency_version: 41.20 → 41.21`.

## Out of scope

- Other git-captain branch-name regex tightening (separate devex queue item)
- Refactoring branch-protection main/master detection
- Auto-deletion in pr-merge (it's already deleting the *remote* branch via gh; local cleanup stays in /post-merge)

## Critical files

- `/Users/jdm/code/the-agency/claude/tools/git-captain` (lines 62, 296–319)
- `/Users/jdm/code/the-agency/tests/tools/git-captain.bats` (extend branch-delete section ~line 310)
- `/Users/jdm/code/the-agency/.claude/skills/post-merge/SKILL.md` (Step 7)
- `/Users/jdm/code/the-agency/claude/config/manifest.json`

## Verification

1. `bats tests/tools/git-captain.bats` — all green (existing 6 + new 5)
2. Manual: `./claude/tools/git-captain branch-delete jordandm-d41-r19` (current orphan branch on main checkout) → fails as expected
3. Manual: `./claude/tools/git-captain branch-delete jordandm-d41-r19 --force` → succeeds, branch deleted
4. RGR signed via receipt-sign, pr-create verifies hash

## Flow

1. Branch `jordandm-d41-r21`
2. Apply changes
3. Run BATS — all green
4. Sign RGR + commit + push
5. `/release` opens PR
6. Principal approval → `/pr-merge --principal-approved`
7. `/post-merge` cuts v41.21 (the new release-tag-check workflow will validate)
8. Close #110 with the release link
