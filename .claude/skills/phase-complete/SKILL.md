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

### Step 3: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing `$ARGUMENTS` as the skill argument. Ensure `$ARGUMENTS` starts with `phase-complete` followed by the phase number (e.g., "phase-complete 1: types and parser"). This tells `/quality-gate` what boundary type and phase to use for the QGR receipt filename.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → write QGR receipt file.

The QG is scoped to the **full phase's work** (all changes since divergence from master, or since the last phase commit). This is a deep review — broader scope than the iteration-level gate.

Wait for the QGR to be presented and the receipt file written before proceeding.

### Step 4: Sprint Review — Wait for approval

Present the QGR and proposed commit message to the user. This is a Sprint Review — the principal reviews the body of work.

**Do not commit without explicit principal approval.**

If the principal requests changes, make them and re-run the relevant QG steps.

### Step 5: Commit with approval

Once approved, re-run `git status` to capture any new files written during the QG fix cycle (bug-exposing tests, coverage tests). Use `/git-commit` via the Skill tool, staging all relevant files. Pass it the full structured commit message from the QGR's "Proposed Commit" section.

### Step 6: Update the plan

After committing, update the plan file in `docs/plans/` to reflect:

- What was done in this phase (phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- **Append the full QGR** under a "Quality Gate Reports" section. Each phase gets its own subsection.

### Step 7: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Phase completion status
- What was committed (summary of the phase's work)
- What's next (next phase, or plan-complete if this was the last phase)
- Key decisions, trade-offs, or context from this phase
- Any open items or known issues carried forward

### Note: Multi-iteration phases

If this phase had multiple iterations that were each committed separately, the phase-complete commit should squash the iteration commits into a single phase commit. Step 2 handles this — use `git reset --soft` to combine them before running the gate.
