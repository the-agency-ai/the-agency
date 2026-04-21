---
name: captain-review
description: Captain-only. Review all draft PRs (or a specified PR / project) and generate per-workstream dispatch files routing findings to worktree agents. Formerly `/captain-review` v1 — v2 migration preserves semantics.
agency-skill-version: 2
when_to_use: "Captain on master wants to triage the open draft-PR queue — either fleet-wide (`--all` or empty), narrowed to a single PR number, or narrowed to all PRs for one workstream — and push each PR's findings to the owning worktree as a dispatch file. Anti-triggers: do NOT use at iteration/phase boundaries (use /iteration-complete or /phase-complete — those run the full QG with red→green fix cycle); do NOT use for ad-hoc single-agent PR review (use /pr-review); do NOT use to respond to existing review threads (use /pr-respond); do NOT use from a worktree — captain/master only."
argument-hint: "[<pr-number> | <project-name> | --all]"
paths: []
required_reading:
  - claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md
  - claude/REFERENCE-ISCP-PROTOCOL.md
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Captain Review

Captain-only multi-PR review pass. For each draft PR in scope, invoke `/code-review` and materialize the findings as a dispatch file under the owning workstream so the worktree agent picks up the review as part of its normal dispatch flow.

## Why this exists

Draft PRs accumulate. A worktree agent cannot self-review their own open work with the captain's fleet-wide lens, and posting review comments directly on each PR floods worktree agents with low-signal noise when the same findings could be routed as a single coherent dispatch.

This skill:

- Surveys the draft-PR queue (fleet-wide, per-project, or per-PR).
- Runs `/code-review` on each — the 7-agent confidence-scored local review, not GitHub PR comments.
- Lands findings as a per-workstream dispatch file so the recipient worktree processes them through its ordinary ISCP inbox.
- Commits the dispatch files as coordination artifacts (no QG — they are not application code).

The boundary is deliberate: this is a captain-side triage pass, not a gate. Boundary gates with the fix cycle live in `/iteration-complete`, `/phase-complete`, and `/pr-prep`.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

- `claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md` — distinguishes the review tools, PR lifecycle, review/dispatch file conventions.
- `claude/REFERENCE-ISCP-PROTOCOL.md` — dispatch format, filenames, addressing; this skill emits dispatches.

## Usage

```
/captain-review                    # fleet-wide (all open draft PRs)
/captain-review --all              # same as above, explicit
/captain-review 123                # single PR by number
/captain-review mdpal              # all draft PRs on the mdpal project
```

- `$ARGUMENTS` (optional): one of
  - a PR number — review that single PR,
  - a project/workstream name — review all draft PRs on that workstream,
  - `--all` or empty — review every open draft PR.

## Preconditions

1. You are the captain on the main checkout (master). This skill refuses from a worktree — `disable-model-invocation: true` + `paths: []` enforce captain-invoked-only; the captain must verify before running.
2. `gh` is authenticated against the repo's origin.
3. Working tree is clean or contains only coordination-artifact edits — this skill writes dispatch files and commits them, so incidental code changes would be swept into the coord commit.
4. `/code-review` is available (Batch 4 v2 skill).

## Flow / Steps

### Step 1: Identify PRs to review

Resolve `$ARGUMENTS`:

- If a PR number: review that specific PR.
- If a project/workstream name: `gh pr list --state open --draft` filtered to PRs whose branch prefix matches the project.
- If `--all` or empty: `gh pr list --state open --draft` — every open draft PR.

If the scope resolves to zero PRs, stop and report "no draft PRs in scope" — do not emit empty dispatch files.

### Step 2: Review each PR

For each PR in scope, invoke `/code-review` via the Skill tool with the PR number. `/code-review` handles the 7-agent confidence-scored local review; this skill does not re-implement it.

### Step 3: Generate dispatch files

For each workstream that produced findings, create a dispatch file at:

```
claude/workstreams/{workstream}/code-reviews/{workstream}-dispatch-{YYYYMMDD-HHMM}.md
```

Contents:

- PR reference (number, title, branch).
- Findings grouped by file.
- Suggested fixes.
- Priority ordering (from the `/code-review` confidence score).

The workstream is derived from the PR branch name (segment before `/`).

### Step 4: Present dispatch report

Show a summary table of all reviews performed this pass:

```
Captain Review Complete:

Project          PR    Findings   Dispatch
─────────────────────────────────────────────
mdpal            #12   8 issues   claude/workstreams/mdpal/code-reviews/mdpal-dispatch-20260401-1430.md
mock-and-mark    #15   3 issues   claude/workstreams/mock-and-mark/code-reviews/mock-and-mark-dispatch-20260401-1430.md
```

### Step 5: Commit review and dispatch files

Stage and commit the review and dispatch files as coordination artifacts via `/git-safe-commit --force` (or `/coord-commit` if the caller prefers the wrapper). These are coordination artifacts — not application code — so the commit does not route through the full QG.

## Failure modes

- **No draft PRs in scope** (Step 1): stop and report. Do not write an empty dispatch.
- **`/code-review` fails on a PR** (Step 2): record the failure in the summary and continue with the remaining PRs. A single-PR failure does not abort the pass — other worktrees still benefit from their dispatches.
- **`gh` not authenticated / network error**: surface the error verbatim; this skill has no offline mode.
- **Dispatch path collides with an existing file for the same minute**: the timestamp is minute-precision; re-running within the same minute for the same workstream would overwrite. Wait 60s or append a disambiguator manually.
- **Commit fails in Step 5** (pre-commit hook): fix the underlying issue and re-commit. Never `--no-verify`. The dispatch files exist on disk regardless; do not delete them to make the commit clean.

## What this does NOT do

- **Does not post comments on GitHub.** Findings route via dispatch, not PR comments. For human-approved PR comments, use `/pr-review`.
- **Does not make code changes.** The worktree agent reading the dispatch decides how to act.
- **Does not run the quality gate.** Boundary gates are `/iteration-complete`, `/phase-complete`, and `/pr-prep`.
- **Does not merge, close, or re-request review on any PR.** It is a triage pass, not a lifecycle action.
- **Does not push.** Push is a separate discipline via `/sync` or `/release`.

## Status

`active` (v2 migrated from v1 in monofolk v1→v2 Batch 8+9 captain cluster). Surface preserved from v1; behavior identical. Composes `/code-review` + dispatch file emission + coord commit.

## Related

- `/code-review` — the per-PR review this skill invokes in a loop.
- `/pr-review` — ad-hoc single-PR review with human-approved comments posted to GitHub.
- `/pr-respond` — respond to existing review threads on a PR.
- `/dispatch` — dispatch lifecycle; the recipient worktree processes what this skill writes.
- `/captain-sync-all` — fleet-wide sync that often precedes or follows a review pass.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
