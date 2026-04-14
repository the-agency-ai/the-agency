---
description: Run the quality gate after completing an iteration — review, fix, test, report, auto-commit
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Iteration Complete

Run this after completing each iteration. Invokes `/quality-gate` for the review+fix cycle, then auto-commits — no principal approval needed.

## Arguments

- $ARGUMENTS: Description of what was completed. Must include boundary type and phase-iteration (e.g., "iteration-complete 1.2: parser edge cases"). If empty or missing phase-iteration, ask the user before proceeding.

## Steps

### Step 1: Preconditions

1. If `$ARGUMENTS` is empty, ask the user what was completed before proceeding.
2. Run `git diff --stat HEAD` and `git status`. If no changed files, tell the user "Nothing to gate — no changes since last commit" and stop.
3. Identify the plan file in `docs/plans/` that this work belongs to. If none exists, note "no plan file" — the commit message will omit the Plan: line.

### Step 2: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing `$ARGUMENTS` as the skill argument. Ensure `$ARGUMENTS` starts with `iteration-complete` followed by the phase-iteration (e.g., "iteration-complete 1.2: parser edge cases"). This tells `/quality-gate` what boundary type and phase-iteration to use for the QGR receipt filename.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → write QGR receipt file.

Wait for the QGR to be presented and the receipt file written before proceeding.

### Step 3: Commit automatically

At iteration boundaries, no approval is needed. Commit automatically after a clean QGR.

Use `/git-commit` via the Skill tool. Pass it the full structured commit message from the QGR's "Proposed Commit" section. The message must follow the format from the injected `quality-gate.md` reference.

### Step 4: Update the plan

After committing, update the plan file in `docs/plans/` to reflect:

- What was done in this commit (iteration/phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- Iteration-level status table for multi-iteration phases
- **Append the full QGR** (all three tables + summary) under a "Quality Gate Reports" section. Each iteration gets its own subsection. This is required — the plan is the living record.

### Step 5: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Current phase and iteration status
- What was just committed (summary, not full QGR)
- What's next (next iteration or phase-complete)
- Any decisions made or context that would help a fresh session continue

### Note

This command handles iteration boundaries only. At phase boundaries, use `/phase-complete` instead — it runs a deep QG, requires principal approval, and lands on master.

After completing this iteration, move to the next iteration. When all iterations in a phase are done, run `/phase-complete`.
