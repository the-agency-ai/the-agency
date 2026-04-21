---
name: captain-release
description: Captain-only. Quality-check, commit, push, create PR, and cut a release in one flow. The "code is ready" command for captain-owned branches. Every PR is a release. Formerly `/release` — v2 rename to captain-actor-verb.
agency-skill-version: 2
when_to_use: Captain has staged coordination work on a captain-* branch and wants to land it as a PR + release. NEVER from master. NEVER from a worktree agent branch (agents use /pr-submit → /pr-captain-land). NEVER auto-invoked.
argument-hint: "[--no-push] [--no-pr] <commit description>"
paths: []
required_reading:
  - agency/REFERENCE-QUALITY-GATE.md
  - agency/REFERENCE-CODE-REVIEW-LIFECYCLE.md
  - agency/REFERENCE-GIT-MERGE-NOT-REBASE.md
---

<!--
  allowed-tools omitted — inherits Bash(*). This skill composes many
  tools (commit-precheck, git-safe-commit, git-push, pr-create, Edit,
  Read for manifest.json) plus Skill invocations (/pr-prep, /git-safe-commit).
  Inherit Bash(*) rather than enumerate at subcommand level (flag #62/#63
  / devex dispatch #171).
-->

# captain-release

Captain's one-flow release command for captain-owned branches (captain-*). Runs quality-check → commit → push → create PR → version-bump → summary. Every PR is a release.

**Name pattern:** `captain-` actor prefix (captain-only), `release` verb. Grouped with `captain-log`, `captain-review` in the captain family.

## Why this exists

When captain has staged coordination work (a framework fix, a refactor, a doc update) on a captain-* branch, that work needs to land as a PR with proper QG + release tagging + version bump. Without one cohesive command, each step gets skipped or done out of order. `captain-release` bundles the full flow.

Agents use a different path: `/pr-submit` → captain's `/pr-captain-land`. That's the agent-owned-work flow. `captain-release` is for captain-owned work (framework fixes, REFERENCE doc updates, captain-* coord artifacts).

## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter.

## Usage

```
/captain-release <commit description>
/captain-release --no-push <description>
/captain-release --no-pr <description>
```

## Preconditions

- Captain NOT on master. Running on master aborts — never push directly to master; always PR.
- Working tree has staged or uncommitted changes relevant to this release.
- A QGR receipt exists for the current state (via prior `/pr-prep` or `/quality-gate`).

## Flow / Steps

### Step 1: Pre-flight

1. Check current branch. If master, **abort**.
2. Show `git status` + `git diff --stat HEAD`.
3. If no changes, inform user and stop.
4. **Check for pending post-merge (C#372 Fix B).** Run `./agency/tools/post-merge-state check`. If exit 1, STOP — a prior PR is in pending-post-merge state (merged but release not yet cut). Run `/pr-captain-post-merge <pending-PR>` first, then re-invoke this skill. A release cannot start while the last release is incomplete. Exit 0 → continue.

### Step 2: Quality gate

Run `./agency/tools/commit-precheck`. Verify formatting, linting, tests pass. If fails, stop and report.

### Step 3: Commit

Invoke `/git-safe-commit` with the commit description from `<arguments>`. Produces a commit on the captain-* branch.

### Step 4: Push (unless `--no-push`)

1. Show commits that will be pushed.
2. Ask for confirmation.
3. `./agency/tools/git-push --force-with-lease <branch>`.

### Step 5: PR (unless `--no-pr` and push happened)

1. Check if PR exists: `gh pr view <branch>`.
2. If exists: report URL.
3. If not: `./agency/tools/pr-create --title "..." --body "..."`.

**Never raw `gh pr create`.** The pr-create tool validates a QGR receipt before allowing PR creation.

### Step 6: Version bump

1. Parse PR title for release version (D#-R# → version #.# OR `agency_version` increment).
2. Update `agency/config/manifest.json`: bump appropriate version field + `updated_at`.
3. Commit the bump via `/git-safe-commit --no-work-item`.
4. Push: `./agency/tools/git-push <branch>`.

### Step 7: Summary

```
Release complete:
  Committed: <commit-hash> <message>
  Version: <old> → <new>
  Pushed: origin/<branch>
  PR: <url> (or skipped)
  Post-merge: run /pr-captain-post-merge after PR merges on GitHub
```

## Failure modes

- **On master**: abort (never push directly to master).
- **commit-precheck fails**: stop, report which check failed; captain fixes + retries.
- **push rejected**: probably branch protection or force-with-lease race; captain investigates.
- **pr-create rejected (no QGR)**: run `/pr-prep` to produce a receipt, retry.
- **version bump already done on branch**: skill detects (manifest diff), skips Step 6 bump.

## What this does NOT do

- **Does not merge the PR** — that's `/pr-captain-merge`.
- **Does not run post-merge** — that's `/pr-captain-post-merge` after GitHub merges the PR.
- **Does not push master** — master is pushed only via merged PRs.
- **Does not land agent-owned work** — for that, agent uses `/pr-submit` → captain uses `/pr-captain-land`.

## Captain-only — four-layer defense

1. `disable-model-invocation: true` — Claude can't auto-invoke.
2. `paths: []` — no auto-activation.
3. Name contains `captain-` — scope visible in listing.
4. Step 1 precondition — captain must be on a captain-* branch, not master or agent branch.

## Status

`active` (v2, refactored from legacy `release` 2026-04-19).

## Related

- `/pr-captain-merge` — merge step after PR is reviewed
- `/pr-captain-post-merge` — release step after merge
- `/pr-captain-land` — alternative flow when landing agent-owned work
- `/pr-prep` — QG before this skill runs
- `/git-safe-commit` — underlying commit tool
- `agency/tools/pr-create` — underlying PR creation tool
- `agency/tools/commit-precheck` — QG precheck
- the-agency#296 — PR lifecycle ownership
- the-agency#315 — V1→V2 migration

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
