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

### Step 2: Determine the prior-iteration base ref

The QG's Hash A/Hash E diff is computed against the **prior iteration commit** (or the phase-start commit if this is the first iteration in the phase). Determine it as follows, in order:

1. **Read the plan file** in `docs/plans/` (or `claude/workstreams/*/`) for an iteration history / status table. The most recent prior iteration's commit SHA is the base. Many plans record this under "Quality Gate Reports" or a status table.
2. **Grep git log** for the prior iteration's commit: `git log --oneline --grep="Phase <P>\\." | head` — e.g., for iteration 1.3, the base is the SHA of the commit titled "Phase 1.2: ...". If this is iteration X.1 (first iteration in the phase), use the phase-start tag / commit (e.g., `v{phase}.0` or the commit titled "Phase <P-1>: ..." if no tag).
3. **Fallback:** `HEAD~1` — use only if steps 1 and 2 yield nothing, and note this in the handoff update as a fallback used.

Capture the SHA/ref as `$BASE_REF`.

### Step 3: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing arguments that include both the boundary description AND the base ref:

```
iteration-complete 1.2: parser edge cases --base <BASE_REF>
```

For example: `iteration-complete 1.2: parser edge cases --base abc1234`.

The leading `iteration-complete <phase-iter>` tells `/quality-gate` the boundary type (used in the receipt filename). The `--base <ref>` tells `/quality-gate` what baseline to use for Hash A / Hash E via `diff-hash --base`.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → sign receipt via `receipt-sign` (five-hash chain, written to `claude/receipts/`). Iteration-complete is auto-approved — Hash D = Hash C.

Wait for the QGR to be presented and the receipt signed before proceeding.

### Step 4: Commit automatically

At iteration boundaries, no approval is needed. Commit automatically after a clean QGR.

Use `/git-safe-commit` via the Skill tool. Pass it the full structured commit message from the QGR's "Proposed Commit" section. The message must follow the format from the injected `quality-gate.md` reference.

### Step 5: Update the plan

After committing, update the plan file in `docs/plans/` to reflect:

- What was done in this commit (iteration/phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- Iteration-level status table for multi-iteration phases
- **Append the full QGR** (all three tables + summary) under a "Quality Gate Reports" section. Each iteration gets its own subsection. This is required — the plan is the living record.

### Step 6: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Current phase and iteration status
- What was just committed (summary, not full QGR)
- What's next (next iteration or phase-complete)
- Any decisions made or context that would help a fresh session continue

### Note

This command handles iteration boundaries only. At phase boundaries, use `/phase-complete` instead — it runs a deep QG, requires principal approval, and lands on master.

After completing this iteration, move to the next iteration. When all iterations in a phase are done, run `/phase-complete`.
