---
name: iteration-complete
description: Run the quality gate after completing an iteration — review, fix, test, report, auto-commit. No principal approval needed (iteration boundary is auto-approved). Auto-emits a structured dispatch to captain so the small-batch-cadence daemon can pick up for PR landing.
agency-skill-version: 2
when_to_use: After completing an iteration of work inside a phase. For phase boundaries use /phase-complete. For final plan delivery use /plan-complete. For pre-PR gating of accumulated work use /pr-prep.
argument-hint: "<phase.iter>: <description> [--base <ref>]"
paths:
  - .claude/worktrees/**
required_reading:
  - claude/REFERENCE-QUALITY-GATE.md
  - claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md
---

<!--
  allowed-tools intentionally omitted — inherits Bash(*) from
  .claude/settings.json. Subcommand-level restriction silently blocked
  fleet agents (flag #62/#63; devex dispatch #171). This skill composes
  dispatch, diff-hash, receipt-sign, git-safe, git-safe-commit, and
  Skill invocations — too broad to enumerate at subcommand level without
  regression risk. Inherit Bash(*).
-->

# iteration-complete

Run this after completing each iteration of work. Invokes `/quality-gate` for the review+fix cycle, auto-commits on green (no principal approval at iteration boundaries), and emits a structured dispatch to captain so the small-batch-cadence daemon can pick up for PR landing.

## Why this exists

Iteration boundaries are the smallest formal commit-and-review unit in the-agency's valueflow work stream. Without a dedicated skill, agents skip the quality gate, forget the receipt-sign step, or let the commit drift from the plan file. `iteration-complete` bundles all five responsibilities (QG run → QGR receipt → auto-commit → plan update → handoff update + dispatch to captain) so iteration-end is single-invocation and auditable.

Auto-commit (no principal approval) is specifically for iteration boundaries — they're small, bounded units where the QG + receipt is sufficient attestation. Phase and plan boundaries use sister skills with principal approval gates.

## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter. `REFERENCE-QUALITY-GATE.md` is the protocol the invoked `/quality-gate` skill runs. `REFERENCE-RECEIPT-INFRASTRUCTURE.md` explains the five-hash chain that signs the iteration's QGR receipt.

## Usage

```
/iteration-complete <phase.iter>: <description> [--base <ref>]
```

Examples:
- `/iteration-complete 1.2: parser edge cases`
- `/iteration-complete 1.3: error handling --base abc1234`

- `<phase.iter>`: numeric identifier (phase.iteration), e.g., `1.2`
- `<description>`: one-line summary
- `--base <ref>` (optional): override baseline for QG diff-hash; resolved automatically if omitted

If invoked with empty arguments, ask what was completed before proceeding.

## Preconditions

- Changed files present (`git status` non-empty).
- On a worktree branch (not master — this skill is worktree-only).
- Prior iteration's commit identifiable (or explicit `--base` passed). First iteration in a phase uses the phase-start commit.
- A plan file should exist under `docs/plans/` or `claude/workstreams/*/`. If absent, skill proceeds with a "no plan file" note in the commit; handoff captures the omission.

## Flow / Steps

### Step 1: Preflight

1. If args empty, ask what was completed.
2. `git status` + `git diff --stat HEAD`. If empty, report "Nothing to gate" and stop.
3. Identify plan file.

### Step 2: Determine prior-iteration base ref

QG's Hash A / Hash E diff is computed against the prior iteration commit (or phase-start commit for first iteration). Resolution order:

1. Read plan file for iteration history / status table; use the last iteration's commit SHA.
2. Grep git log for the prior-iteration commit: `git log --oneline --grep="Phase <P>\\."`. If this is X.1, use phase-start tag/commit.
3. Fallback: `HEAD~1`. Note fallback usage in handoff.

Capture as `$BASE_REF`.

### Step 3: Run the quality gate

```
/quality-gate iteration-complete <phase.iter>: <description> --base <BASE_REF>
```

Leading `iteration-complete <phase.iter>` tells QG the boundary type (used in receipt filename). `--base` tells QG the baseline for Hash A/E via `diff-hash --base`.

Full QG protocol runs: parallel review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → sign receipt (five-hash chain at `claude/workstreams/{W}/qgr/`). Iteration-complete is auto-approved — Hash D = Hash C.

Wait for receipt signed before proceeding.

### Step 4: Commit (auto)

No approval. Commit automatically after clean QGR.

Use `/git-safe-commit` with the full structured commit message from the QGR's "Proposed Commit" section.

### Step 5: Update plan file

Append to the plan under "Quality Gate Reports":

- What was done
- What QG found + fixed
- Plan changes (scope, reordering, new findings)
- Iteration status-table row

Append the full QGR (all tables + summary). The plan is the living record.

### Step 6: Update handoff

Update the worktree handoff file (`usr/*/*/handoff.md` or `usr/*/captain/handoff.md`):

- Current phase + iteration status
- What just committed (summary, not full QGR)
- What's next
- Context for fresh-session continuation

### Step 7: Emit iteration-complete dispatch to captain

Structured dispatch for captain's auto-ship daemon. Must run AFTER the commit (Step 4) so `commit_hash` is current.

Capture:
- `ITERATION_SLUG` (e.g., "1.2")
- `PHASE_NUM`
- `BRANCH` = `git branch --show-current`
- `COMMIT_HASH` = the Step 4 commit
- `SUMMARY` = first line of commit message
- `RECEIPT_PATH` = QGR receipt path from Step 3

Emit:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch create \
  --to {repo}/{principal}/captain \
  --type iteration-complete \
  --subject "Iteration {ITERATION_SLUG} complete on {BRANCH}" \
  --body "<yaml body — see below>"
```

Body:

```yaml
event: iteration-complete
iteration: {ITERATION_SLUG}
phase: {PHASE_NUM}
branch: {BRANCH}
commit_hash: {COMMIT_HASH}
summary: {SUMMARY}
qgr_receipt: {RECEIPT_PATH}
emitted_at: {ISO-8601 timestamp}
```

Cascade isolation: export `AGENCY_SKILL_BYPASS_CASCADE=1` at skill start and unset at end if running multiple commits within the skill.

## Failure modes

- **No changes to gate** (Step 1): skill stops cleanly with "Nothing to gate" message. Not an error.
- **QG fails** (Step 3): fix-and-retry per QG protocol — the gate itself handles findings, no special iteration-complete handling needed.
- **Commit fails** (Step 4): usually a pre-commit hook (lint-staged, oxfmt). Fix the blocking issue; re-run from Step 4 (QG already passed; no need to re-run Step 3).
- **Plan file missing** (Step 5): skill notes "no plan file" and continues. Handoff records the gap.
- **Dispatch emission fails** (Step 7): skill warns but exits 0 — the commit itself is the authoritative record; dispatch is notification. Captain catches the omission via other mechanisms (handoff read, manual check).

## What this does NOT do

- **Does not land on master** — iteration-complete is a worktree-side boundary. Phase boundary + pr-submit + captain's pr-captain-land land on master.
- **Does not require principal approval** — iteration boundaries are auto-approved; the QG + receipt is sufficient attestation.
- **Does not run deep QG** — the QG here is iteration-scoped (diff against prior iteration). Phase and plan boundaries run deeper variants.
- **Does not squash prior iteration commits** — those stay individually visible in history; squash happens (if at all) at phase boundary.

## Status

`active` (v2, body retrofit from Arguments/Steps pattern to 9-section structure 2026-04-19).

## Related

- `/quality-gate` — the core QG protocol this skill invokes in Step 3
- `/phase-complete` — sibling skill for phase boundaries (deep QG + principal approval)
- `/plan-complete` — sibling skill for plan delivery (final deep QG + A&D)
- `/pr-prep` — pre-PR gating for accumulated work
- `/pr-submit` — agent's hand-off to captain for PR landing (runs AFTER iteration-complete when ready to ship)
- `claude/tools/receipt-sign` — signs the five-hash receipt
- `claude/tools/dispatch` — emits the Step 7 notification
- `claude/workstreams/captain/small-batch-cadence-*.md` — design for the auto-ship daemon that consumes Step 7's dispatch
- the-agency#298 — skill refactor recommendation
- the-agency#315 — V1→V2 migration

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
