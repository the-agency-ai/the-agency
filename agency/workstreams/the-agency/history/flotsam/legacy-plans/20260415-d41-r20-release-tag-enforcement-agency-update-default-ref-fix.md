---
title: "D41-R20 — release-tag enforcement + `agency update` default-ref fix"
slug: d41-r20-release-tag-enforcement-agency-update-default-ref-fix
path: docs/plans/20260415-d41-r20-release-tag-enforcement-agency-update-default-ref-fix.md
date: 2026-04-15
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
tags: [Infra]
---

# D41-R20 — release-tag enforcement + `agency update` default-ref fix

## Context

Issue #113 (monofolk/jordan/captain) surfaced two interlocking framework bugs today, caught during monofolk's post-R19 sync:

1. **`agency update --from-github` defaults to latest release tag**, not `main`. When a fix lands on `main` before a tag is cut (as happened with R19 today), adopters silently get stale code and "already current" messages.
2. **Post-merge release-tag creation is advisory, not mechanically enforced.** R19 merged, but I had to manually run `gh release create v41.19` after the fact. Earlier in Day 41, PR #98 (R4+R6+R7 devex bundle) merged and *never* got a tag — a historical gap only discovered today. Principal directive: *"We always need a release tag."*

Both were mitigated immediately today (v41.19 cut, v41.11 retroactively cut). R20 makes the fixes durable.

## Approach

Two changes:

**Part A — `agency update --from-github` default → `main`.** Matches `git pull`, `npm update`, `brew update`, etc. Keep opt-in for latest-tag behavior via `--from-github @latest` sentinel. Add informational "N commits ahead" output when the update includes un-tagged work.

**Part B — Mechanical release-tag enforcement on push-to-main.** New GitHub Actions workflow that runs on merge commits to main, reads `agency/config/manifest.json → agency_version`, and fails if `gh release view v{version}` doesn't succeed. Red CI is visible pressure on captain to cut the tag immediately. Complements (does not replace) the /post-merge skill.

## File-level changes

### 1. `agency/tools/lib/_agency-update`

- **Line 71** (flag parsing): change default `FROM_GITHUB="latest"` → `FROM_GITHUB="main"`.
- **Lines 159–168** (ref resolution): replace the `gh release view` branch. New behavior:
  - If `FROM_GITHUB == "main"` (default or explicit) → use `main`.
  - If `FROM_GITHUB == "@latest"` → use the existing "latest release via `gh release view`" logic (opt-in).
  - Any other value → literal ref (tag, branch, commit) as today.
- **Help text** (lines 44–48): update to describe new default + `@latest` opt-in.
- **Output block** (lines 218–234): after the From/To lines, if `from_commit` and `to_commit` both resolvable, run `git -C "$clone_dir" rev-list --count ${from_commit}..${to_commit} 2>/dev/null` and print `Commits: N ahead` (skip if zero or error).

### 2. `.github/workflows/release-tag-check.yml` (new)

```yaml
name: Release Tag Check
on:
  push:
    branches: [main]
jobs:
  release-tag-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Is merge commit?
        id: ismerge
        run: |
          parent_count=$(git rev-list --parents -n 1 HEAD | awk '{print NF-1}')
          echo "parents=$parent_count" >> "$GITHUB_OUTPUT"

      - name: Read manifest version
        id: ver
        if: steps.ismerge.outputs.parents == '2'
        run: |
          v=$(jq -r .agency_version agency/config/manifest.json)
          echo "version=$v" >> "$GITHUB_OUTPUT"

      - name: Assert release exists
        if: steps.ismerge.outputs.parents == '2'
        env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
        run: |
          v="${{ steps.ver.outputs.version }}"
          if ! gh release view "v${v}" --repo "${GITHUB_REPOSITORY}" >/dev/null 2>&1; then
            echo "::error::Merge commit landed without release tag v${v}. Run /post-merge now."
            exit 1
          fi
          echo "Release v${v} present for merge commit $(git rev-parse --short HEAD)"
```

Skips direct housekeeping coord-commits (single parent). Only enforces on merge commits (two-parent, i.e. `--merge` PR merges).

### 3. `.claude/skills/post-merge/SKILL.md`

Strengthen Step 6:
- After `gh release create`, add an explicit verification step: `gh release view v{version}` — fail the skill if it returns non-zero.
- Cross-reference the new GitHub Actions enforcement so captain understands the CI guardrail.

### 4. `tests/tools/agency-update.bats`

Add cases (extend existing fixture pattern):
- `--from-github` (no ref) defaults to `main` (assert fetch target).
- `--from-github @latest` resolves to latest release tag (mock `gh release view` or assert behavior via tool output that queries releases).
- `--from-github v41.11` (literal tag) works as today.
- Output includes `Commits: N ahead` line when fetched ref is ahead of current commit (seed fixture with two commits).

Test helper additions: a stub for `gh release view` if needed; otherwise inject `FROM_GITHUB=@latest` and assert the code path takes the `gh` branch.

### 5. `agency/config/manifest.json`

Bump `agency_version: 41.19 → 41.20`, stamp `updated_at`.

## Out of scope

- Retroactive tagging for any other historical gap (manually checked — only v41.11 was missing; cut today).
- Refactoring how `agency` CLI dispatches to `_agency-update` (unchanged).
- Hookify-level enforcement before push (pushes to main go through `git-push` which is blocked by branch protection; workflow is the right layer).
- The "every PR is a release" doc text is already present in `CLAUDE-CAPTAIN.md` (D41-R19) — just reinforced by the new workflow.

## Critical files

- `/Users/jdm/code/the-agency/agency/tools/lib/_agency-update` (lines 71, 44–48, 159–168, 218–234)
- `/Users/jdm/code/the-agency/.github/workflows/release-tag-check.yml` (new)
- `/Users/jdm/code/the-agency/.claude/skills/post-merge/SKILL.md` (Step 6)
- `/Users/jdm/code/the-agency/tests/tools/agency-update.bats` (extend)
- `/Users/jdm/code/the-agency/agency/config/manifest.json`

## Existing helpers to reuse

- `_agency-update` already has `gh release view` integration — just reroute under `@latest` opt-in.
- `jq` is available in GH Actions runners (used in smoke-ubuntu).
- BATS fixture pattern in `agency-update.bats` lines 38–65.

## Verification

1. `bats tests/tools/agency-update.bats` all green.
2. Manual: `./agency/tools/agency update --from-github --help` documents the new default + `@latest` opt-in.
3. Manual: `./agency/tools/agency update --from-github` resolves to `main` (not latest tag).
4. Manual: `./agency/tools/agency update --from-github @latest` resolves to latest release tag.
5. Manual: regression — `./agency/tools/agency update --from-github v41.11` pulls that specific tag.
6. CI: the new workflow passes on a merge commit with correct release tag; fails red if release is missing.
7. QG: full MAR (4 reviewers + scorer), RGR signed, pr-create verifies receipt hash.

## Flow

1. Create branch `jordandm-d41-r20`
2. Apply changes to `_agency-update`, workflow, post-merge SKILL, tests, manifest
3. Run BATS
4. `/pr-prep` (MAR + fix + RGR)
5. `/release` (PR + manifest bump validated by pr-create)
6. Principal approval → `/pr-merge`
7. `/post-merge` — this is the canary: if I forget the release, the new workflow will go red on main and catch me
8. Close #113 on merge
