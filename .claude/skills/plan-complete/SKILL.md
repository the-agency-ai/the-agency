---
description: Complete a plan — final deep QG, finalize artifacts, produce Reference doc
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Plan Complete

Run this when all phases in a plan are done. This finalizes the living artifacts and produces the Reference document.

At this point, master already contains the squashed phase commits (landed via `/phase-complete` at each phase boundary). No additional squash needed.

## Arguments

- $ARGUMENTS: Plan name or path (e.g., "deployment infrastructure" or "docs/plans/20260322-deployment-infrastructure.md"). If empty, find the most recently modified plan in `docs/plans/`.

## Instructions

### Step 1: Preconditions

1. If `$ARGUMENTS` is empty, find the most recently modified plan in `docs/plans/`.
2. Run `git diff --stat HEAD` and `git status`. If no changed files, note "clean tree — QG will review the full project scope."
3. Identify the plan file and read it to understand the full scope.

### Step 2: Run the quality gate

Invoke `/quality-gate` via the Skill tool, passing `plan-complete: $ARGUMENTS` as the skill argument. The `plan-complete` prefix tells `/quality-gate` what boundary type to use for the QGR receipt filename.

This runs the full QG protocol: parallel agent review → consolidate → bug-exposing tests → fix → coverage tests → confirm clean → present QGR → write QGR receipt file.

The QG scope should be the **entire project codebase**, not just recent changes — this is the final gate before the plan is declared complete.

Wait for the QGR to be presented and the receipt file written before proceeding.

### Step 3: Principal approval

Present the QGR to the principal. **Do not proceed without explicit approval.** This is a plan boundary — the principal must sign off.

### Step 4: Finalize the Plan

1. Read the plan file
2. Update all phase statuses to "Complete"
3. Ensure all QGRs are present
4. Add a "Plan Completion" section:
   - Summary of all phases delivered
   - Total test count across all phases
   - Total issues found and fixed across all QGRs
   - Any open items or follow-up work identified

### Step 5: Finalize the A&D

1. Locate the A&D document (search `agency/workstreams/*/` and `docs/plans/`)
2. Review: does it reflect reality, not aspirations?
3. Update any design decisions that changed during implementation
4. Mark any decisions that were deferred or abandoned

### Step 6: Finalize the PVR

1. Locate the PVR document (search `agency/workstreams/*/`)
2. Review: are all requirements addressed?
3. Note any requirements that were descoped or deferred
4. Update success criteria with actual results

### Step 7: Produce the Reference Document

Generate a final "this is how it works" document:

1. Create `docs/<project-name>/reference.md` (or appropriate location)
2. Structure:
   - Overview (from PVR goal)
   - Architecture (from A&D)
   - Key design decisions (from A&D, with rationale)
   - How to use (from Plan, distilled to operational knowledge)
   - Known limitations and future work
3. Present the draft to the principal for review

### Step 8: Commit

Use `/git-safe-commit` via the Skill tool. The message must follow the `Phase X.Y:` format. **Principal must approve the commit message.**

### Step 9: Update handoff

Locate the handoff file for this project (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Plan completion status
- Reference document location
- Any follow-up work identified
- Handoff to captain for PR creation

Print:

> Plan complete. Master contains all phase commits. The captain session on master manages PR creation and pushes to origin.
>
> Artifacts finalized:
>
> - Plan: [path]
> - A&D: [path]
> - PVR: [path]
> - Reference: [path]
