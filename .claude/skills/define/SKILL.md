---
description: Drive toward a complete Product Vision & Requirements (PVR) using 1B1 protocol with completeness checklist.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Define — PVR Completeness

Drive toward complete Product Vision & Requirements (PVR) using the 1B1 protocol with a completeness checklist.

## Usage

- `/define` — start fresh, auto-detect project
- `/define "Project Name"` — start fresh for named project
- `/define --from <seed-file>` — extract initial requirements from a seed document
- `/define --continue <pvr-file>` — resume work on an existing PVR

## Behavior

### Step 1: Establish context

If `--from` specified, read the seed file. If `--continue`, read the existing PVR. Otherwise, ask what the project is about.

### Step 2: Scan for existing work

Glob `agency/workstreams/*/pvr-*.md` for existing PVR files. If found, offer to continue from the most recent one.

### Step 3: Build discussion agenda

Map the completeness checklist to discussion items. Skip items already covered in an existing PVR.

### Step 4: Start discussion

Invoke `/discuss` via the Skill tool, passing the agenda items. The 1B1 protocol handles the resolution cycle for each item.

### Step 5: Update PVR progressively

After each item resolves, update the PVR file. Don't batch writes to the end.

PVR location: `agency/workstreams/{workstream}/pvr-{workstream}-{slug}-{YYYYMMDD}.md`.

### Step 6: Present completeness scorecard

After all items are discussed, show the checklist with status:

```
PVR Completeness:

1. Problem Statement       ✓ Complete
2. Target Users            ✓ Complete
3. Use Cases               ✓ Complete
4. Functional Requirements ✓ Complete
5. Non-Functional Reqs     ~ Partial (performance TBD)
6. Constraints             ✓ Complete
7. Success Criteria        ✓ Complete
8. Non-Goals               ✓ Complete
9. Open Questions          2 remaining

Score: 8/9 complete
```

## Completeness Checklist

1. **Problem Statement** — What problem does this solve? For whom? Why now?
2. **Target Users** — Who uses this? What are their characteristics?
3. **Use Cases** — Primary workflows. What does the user do?
4. **Functional Requirements** — What must the system do?
5. **Non-Functional Requirements** — Performance, scalability, reliability, accessibility
6. **Constraints** — Technical, business, regulatory, timeline
7. **Success Criteria** — How do we know it worked? Measurable outcomes.
8. **Non-Goals** — What we explicitly won't do (prevents scope creep)
9. **Open Questions** — Unresolved items requiring research or decisions
