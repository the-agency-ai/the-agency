---
description: Run the full quality gate after completing an implementation phase — review, fix, test, report, commit
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Phase Complete — Quality Gate + Sprint Review

Run this after completing each implementation phase. Invokes `/quality-gate` for the review+fix cycle, then presents results for principal approval before committing. Do not proceed to the next phase until the gate passes and the user approves.

## Arguments

- $ARGUMENTS: Description of what was completed. Must include boundary type and phase (e.g., "phase-complete 1: types and parser"). If empty or missing phase number, ask the user before proceeding.

## Steps

### Step 1: Preconditions

1. If `$ARGUMENTS` is empty, ask the user what was completed before proceeding.
2. Run `git diff --stat HEAD` and `git status`. If no changed files, tell the user "Nothing to gate — no changes since last commit" and stop.
3. Identify the plan file in `docs/plans/` that this work belongs to. If none exists, note "no plan file" — the commit message will omit the Plan: line.

### Step 2: Squash iterations (if applicable)

If this phase had multiple iterations committed separately, squash them into a single phase commit before running the gate. Use `git reset --soft` to the commit before the first iteration, then re-stage all changes.

If only one commit or no prior iteration commits, skip this step.

### Step 3: Determine the phase-start base ref

The QG's Hash A/Hash E diff is computed against the **phase-start tag** (or commit). Determine as follows, in order:

1. **Read the plan file** in `docs/plans/` (or `agency/workstreams/*/`) for a phase-start tag — most plans record `tag: v<phase>.0` or similar on the phase header (e.g., Phase 1 starts at `v40.1`).
2. **Check for a git tag** matching the phase: `git tag --list 'v*' --sort=-v:refname | head` — use the tag that marks the start of this phase.
3. **Fallback:** `git merge-base main HEAD` — the divergence point from master. Note in the handoff if fallback was used.

Capture the tag/SHA as `$BASE_REF`.

### Step 4: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing arguments that include both the boundary description AND the base ref:

```
phase-complete 1: types and parser --base <BASE_REF>
```

For example: `phase-complete 1: types and parser --base v40.1`.

The leading `phase-complete <phase>` tells `/quality-gate` the boundary type (used in the receipt filename). The `--base <ref>` tells `/quality-gate` what baseline to use for Hash A / Hash E via `diff-hash --base`.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → sign receipt via `receipt-sign` (five-hash chain, written to `agency/workstreams/{W}/qgr/`).

The QG is scoped to the **full phase's work** (all changes since divergence from master, or since the last phase commit). This is a deep review — broader scope than the iteration-level gate.

Phase-complete requires principal 1B1 — capture the 1B1 transcript path so `/quality-gate` Step 10 can record Hash D as the transcript hash (not auto-approved).

Wait for the QGR to be presented and the receipt signed before proceeding.

### Step 5: Sprint Review — Wait for approval

Present the QGR and proposed commit message to the user. This is a Sprint Review — the principal reviews the body of work.

**Do not commit without explicit principal approval.**

If the principal requests changes, make them and re-run the relevant QG steps.

### Step 6: Commit with approval

Once approved, re-run `git status` to capture any new files written during the QG fix cycle (bug-exposing tests, coverage tests). Use `/git-safe-commit` via the Skill tool, staging all relevant files. Pass it the full structured commit message from the QGR's "Proposed Commit" section.

### Step 7: Update the plan

After committing, update the plan file in `docs/plans/` to reflect:

- What was done in this phase (phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- **Append the full QGR** under a "Quality Gate Reports" section. Each phase gets its own subsection.

### Step 8: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Phase completion status
- What was committed (summary of the phase's work)
- What's next (next phase, or plan-complete if this was the last phase)
- Key decisions, trade-offs, or context from this phase
- Any open items or known issues carried forward

### Note: Multi-iteration phases

If this phase had multiple iterations that were each committed separately, the phase-complete commit should squash the iteration commits into a single phase commit. Step 2 handles this — use `git reset --soft` to combine them before running the gate.
