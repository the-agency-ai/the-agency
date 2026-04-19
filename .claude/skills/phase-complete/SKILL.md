---
name: phase-complete
description: Run the full deep quality gate after completing an implementation phase — review, fix, test, report, squash-commit. Principal approval REQUIRED before commit (phase boundary is NOT auto-approved). Auto-emits phase-complete dispatch to captain for PR landing.
agency-skill-version: 2
when_to_use: After completing a full phase of work — all iterations in the phase closed. For iteration boundaries within a phase use /iteration-complete. For final plan delivery use /plan-complete.
argument-hint: "<phase>: <description>"
paths:
  - .claude/worktrees/**
required_reading:
  - claude/REFERENCE-QUALITY-GATE.md
  - claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md
---

<!--
  allowed-tools intentionally omitted — inherits Bash(*). See sibling
  iteration-complete for full rationale (flag #62/#63; devex dispatch #171;
  the-agency#298 refactor caveat). Broad tool surface makes subcommand-level
  narrowing brittle.
-->

# phase-complete

Run this after completing each implementation phase (the collection of iterations that delivered a logical unit of work). Runs the full deep quality gate, presents results for principal approval (Sprint Review), commits the squash-rollup of iterations on approval, and emits a dispatch to captain for PR landing.

## Why this exists

Phases are larger boundary events than iterations — a full sub-deliverable (parser + lexer + AST; or data model + migration + seed; etc.). The QG at this boundary is deeper than iteration-complete's (full phase scope, not just since-last-iteration). Principal approval is REQUIRED — phases are the Sprint-Review moment where the principal decides whether the body of work is good enough to carry forward. Without a dedicated skill, phases drift into ad-hoc "I think we're done" claims; `/phase-complete` enforces the gate + approval + squash + dispatch in sequence.

Squash discipline matters at phase boundaries: iterations are individually meaningful during development but collapse to a single phase-commit in the durable record so master history stays readable. Iterations remain in reflog / tags if anyone needs to replay them.

## Required reading

Read the files listed in `required_reading:` frontmatter. `REFERENCE-QUALITY-GATE.md` is the deep QG protocol. `REFERENCE-RECEIPT-INFRASTRUCTURE.md` covers the five-hash receipt chain signed at Step 4.

## Usage

```
/phase-complete <phase>: <description>
```

Example: `/phase-complete 1: types and parser`

- `<phase>`: numeric phase identifier (e.g., `1`)
- `<description>`: one-line summary of what the phase delivered

If invoked with empty args, ask what was completed before proceeding.

## Preconditions

- On a worktree branch (not master).
- Changed files present OR prior iteration commits within this phase (both acceptable — Step 2 squash handles the multi-iteration case).
- Plan file identifiable (phase info, iteration history, phase-start tag preferred).
- Principal available for Sprint Review (Step 5 blocks on their approval; do not phase-complete when principal is offline unless you're OK waiting).
- 1B1 transcript file path known (or willing to start one mid-skill — QG's Hash D uses the transcript hash for phase/plan boundaries; auto-approval only applies at iteration boundary).

## Flow / Steps

### Step 1: Preflight

1. If args empty, ask what was completed.
2. `git status` + `git diff --stat HEAD`. Combined with prior-phase iteration commits, there should be something to gate. Empty = stop.
3. Identify the plan file.

### Step 2: Squash iterations (if applicable)

If this phase had multiple iterations committed separately:

```
git reset --soft <commit-before-first-iteration-in-this-phase>
```

Then re-stage all changes. They're now uncommitted, ready for a single phase commit in Step 6.

If only one commit or no prior iteration commits, skip this step.

### Step 3: Determine phase-start base ref

The deep QG diff is computed against the phase-start tag/commit. Resolution order:

1. Read plan file for `tag: v<phase>.0` or similar in phase header (e.g., Phase 1 starts at `v40.1`).
2. `git tag --list 'v*' --sort=-v:refname | head` — use the tag marking this phase's start.
3. Fallback: `git merge-base main HEAD`. Note in handoff if fallback was used.

Capture as `$BASE_REF`.

### Step 4: Run the deep quality gate

```
/quality-gate phase-complete <phase>: <description> --base <BASE_REF>
```

Full QG protocol — parallel review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → sign receipt (five-hash chain at `claude/workstreams/{W}/qgr/`).

Scope: **full phase's work** (all changes since `$BASE_REF`). Deeper than iteration-level.

**Phase-complete requires principal 1B1** — pass the 1B1 transcript path to `/quality-gate` so Step 10 records Hash D as the transcript hash (NOT auto-approved like iteration-complete).

Wait for QGR presented + receipt signed before proceeding.

### Step 5: Sprint Review — wait for approval

Present the QGR + proposed commit message to the principal. This IS the Sprint Review.

**Do not commit without explicit principal approval.**

If principal requests changes:
- Make the changes
- Re-run the relevant QG step(s)
- Re-present

Loop until approval.

### Step 6: Commit with approval

Once approved, `git status` to capture any QG-phase-added files (bug-exposing tests, coverage tests). Use `/git-safe-commit` via Skill tool, staging all relevant files. Pass the full structured commit message from the QGR's "Proposed Commit" section. Message leads with `Phase <N>: <description>` per framework convention.

### Step 7: Update plan file

Under "Quality Gate Reports":

- Phase status change (e.g., "Phase 1: complete")
- What QG found + fixed
- Plan changes
- Append full QGR

### Step 8: Update handoff

Update worktree handoff:

- Phase completion status
- What was committed (phase summary)
- What's next (next phase, or `/plan-complete` if last phase)
- Key decisions / trade-offs / open items

### Step 9: Emit phase-complete dispatch to captain

Structured dispatch for captain's auto-ship daemon.

Capture:
- `PHASE_SLUG`
- `BRANCH`
- `COMMIT_HASH` (Step 6 commit)
- `SUMMARY`
- `RECEIPT_PATH`

Emit:

```
bash $CLAUDE_PROJECT_DIR/claude/tools/dispatch create \
  --to {repo}/{principal}/captain \
  --type phase-complete \
  --subject "Phase {PHASE_SLUG} complete on {BRANCH}" \
  --body "<yaml body>"
```

Body:

```yaml
event: phase-complete
phase: {PHASE_SLUG}
branch: {BRANCH}
commit_hash: {COMMIT_HASH}
summary: {SUMMARY}
qgr_receipt: {RECEIPT_PATH}
emitted_at: {ISO-8601 timestamp}
```

Cascade isolation: `AGENCY_SKILL_BYPASS_CASCADE=1` in environment.

## Failure modes

- **Nothing to gate** (Step 1): skill stops cleanly.
- **Squash conflicts** (Step 2): rare (reset --soft doesn't conflict), but if the pre-phase state is unclear, skill halts — principal investigates.
- **QG fails** (Step 4): fix-and-retry per QG protocol.
- **Principal rejects at Sprint Review** (Step 5): make changes, re-run relevant QG steps, re-present. No time limit on this loop.
- **Commit fails after approval** (Step 6): pre-commit hook (lint-staged, oxfmt). Fix the blocking issue, re-run from Step 6 (QG stays valid).
- **Dispatch emission fails** (Step 9): warn, exit 0. Commit is the authoritative record.

## What this does NOT do

- **Does not auto-approve** — principal 1B1 + explicit approval required. Iteration boundaries auto-approve; phase boundaries do not.
- **Does not push or open a PR** — that's captain's job via `/pr-captain-land` after consuming the Step 9 dispatch (or direct via `/pr-submit`).
- **Does not squash across phases** — squash is within-phase only. Prior phases stay as distinct commits.
- **Does not bump manifest versions** — versioning happens at PR-landing time (captain's flow).

## Status

`active` (v2, body retrofit from Arguments/Steps pattern to 9-section structure 2026-04-19).

## Related

- `/quality-gate` — deep QG protocol invoked in Step 4
- `/iteration-complete` — sibling skill for iteration boundaries (auto-approved, lighter QG)
- `/plan-complete` — sibling skill for plan delivery (final deep QG + A&D)
- `/pr-submit` — agent's hand-off to captain; runs after phase-complete when ready to land
- `/pr-captain-land` — captain's counterpart; consumes Step 9's dispatch
- `claude/tools/receipt-sign` — signs the five-hash receipt at phase boundary
- `claude/workstreams/captain/small-batch-cadence-*.md` — auto-ship daemon design
- the-agency#296 — PR lifecycle ownership
- the-agency#298 — skill refactor recommendation
- the-agency#315 — V1→V2 migration (this skill's retrofit lives in Tier 1)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
