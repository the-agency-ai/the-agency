---
description: Review PVR, A&D, and Plan before starting a new phase — highlight findings, discuss decisions
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Pre-Phase Review

Review the living artifacts (PVR, Architecture & Design, Plan) before starting a new phase. Surface anything that needs attention and get clearance to proceed.

## Arguments

- $ARGUMENTS: Optional next phase description (e.g., "Phase 3: First Cloud Deploy"). If empty, infer from the plan file's next incomplete phase.

## Instructions

### Step 1: Locate living artifacts

Search for the three artifact types:

1. **PVR** — Glob `agency/workstreams/*/**/*-pvr-*.md` and `usr/*/**/*-pvr-*.md` for Product Vision & Requirements files.
2. **A&D** — Glob `agency/workstreams/*/**/*-architecture-*.md`, `agency/workstreams/*/**/*-ad-*.md`, and `docs/plans/*-architecture-*.md` for Architecture & Design files.
3. **Plan** — Glob `docs/plans/*.md` and pick the most recently modified plan file.

If any artifact is missing, note it ("PVR not found — skipping PVR review") but continue with whatever exists. If none are found, tell the user and stop.

### Step 2: Parallel review agents

Launch **three agents in parallel**, one per artifact:

**PVR reviewer:**

- Read the PVR file.
- Is it still accurate given what has been built so far?
- Are requirements met, changed, or newly discovered?
- Are success criteria still valid and measurable?
- Flag anything that no longer reflects reality.

**A&D reviewer:**

- Read the A&D file.
- Are design decisions still sound given what was learned during implementation?
- Are there decisions that should be revisited based on new information?
- Are there new patterns, conventions, or architectural choices made during implementation that should be documented here?
- Flag any drift between the document and the actual codebase.

**Plan reviewer:**

- Read the Plan file.
- Are remaining phases still correctly scoped given what was learned?
- Should anything be reordered, split, or merged?
- Are there new risks, dependencies, or blockers?
- Does the phase boundary still make sense, or has scope shifted?

Each agent should return a structured list of findings, each categorized as:

- **Clean** — no changes needed
- **Highlight** — informational, no action required but worth noting
- **Decision needed** — requires the principal's input before proceeding

### Step 3: Consolidate findings

Merge results from all three agents. Group by category:

1. **No changes needed** — list any artifacts that are fully up to date
2. **Highlights (informational)** — things worth noting but not blocking
3. **Decisions needed** — items requiring the principal's input, each with:
   - What the issue is
   - What the options are
   - Trade-offs for each option
   - A recommendation

### Step 4: Present to the principal

Always show the full consolidated report, even if everything is clean.

If no issues were found:

> PVR, A&D, and Plan reviewed. No changes needed. Ready to proceed to [next phase].

If there are highlights but no decisions:

> Show the highlights, then: "No decisions needed. Ready to proceed to [next phase]."

If decisions are needed:

> Show everything, then present each decision with numbered options so the principal can reply by number.

### Step 5: Apply decisions

If the principal makes decisions that require artifact updates:

1. Update the relevant files based on their decisions.
2. Confirm what was changed in each file.
3. Do NOT commit — leave changes unstaged for the principal to review.

### Step 6: Update handoff

After decisions are applied, locate the handoff file (glob `usr/*/*/handoff.md` or `usr/*/captain/handoff.md`). Update with:

- Pre-phase review findings and decisions made
- Updated phase scope (if any changes were made)
- Current state of PVR, A&D, and Plan
- What the next phase will tackle

### Step 7: Get clearance

Ask: "Ready to proceed to [next phase]?"

Wait for explicit confirmation before the phase begins.
