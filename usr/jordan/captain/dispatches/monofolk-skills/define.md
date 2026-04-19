---
allowed-tools: Read, Write, Edit, Glob, Bash(date *), Bash(git branch *)
description: Drive toward a complete PVR (Product Vision & Requirements) using the 1B1 protocol with a completeness checklist
---

# /define

Drive a structured discussion toward a complete **Product Vision & Requirements (PVR)** document. Uses `/discuss` as the protocol and brings the agenda — the completeness checklist ensures nothing is missed.

## Usage

```
/define                           — start from scratch, ask what we're defining
/define "Project Name"            — start with a named project
/define --from <seed-file>        — extract initial items from a seed document
/define --continue <pvr-file>     — resume definition using an existing PVR's gaps
```

## Behavior

When invoked:

1. **Establish context.** If a project name or seed file is provided, read it. If not, ask: "What are we defining?" Get a one-sentence answer before proceeding.

2. **Scan for existing work.** Check for an existing PVR in:
   - `agency/workstreams/{workstream}/` (shared, post-implementation)
   - `usr/{principal}/{agent}/` (instance, pre-implementation)
     If found, load it and identify gaps against the checklist.

3. **Build the discussion agenda.** Map the completeness checklist to discussion items. If resuming from an existing PVR, only include items that are empty or marked as open questions.

4. **Start the discussion.** Invoke `/discuss` with the agenda items. The `/discuss` protocol handles the 1B1 cycle, transcript capture, and resolution tracking.

5. **After each item resolves,** update the PVR document progressively. Do NOT batch writes to the end. The PVR is a living document — write to it as decisions are made.

6. **On completion,** present the PVR completeness scorecard and ask: "Ready to move to /design, or are there items to revisit?"

## Completeness Checklist

These are the items that a complete PVR must cover. Each becomes a discussion item:

| #   | Topic                           | What to resolve                                        |
| --- | ------------------------------- | ------------------------------------------------------ |
| 1   | **Problem Statement**           | What problem are we solving? Why does it matter?       |
| 2   | **Target Users**                | Who is this for? Primary and secondary audiences.      |
| 3   | **Use Cases**                   | What do users do with it? Key workflows and scenarios. |
| 4   | **Functional Requirements**     | What must it do? Capabilities, features, behaviors.    |
| 5   | **Non-Functional Requirements** | Performance, scalability, reliability, accessibility.  |
| 6   | **Constraints**                 | Technical, business, regulatory, timeline, budget.     |
| 7   | **Success Criteria**            | How do we know it works? Measurable outcomes.          |
| 8   | **Non-Goals**                   | What are we explicitly NOT doing? Scope boundaries.    |
| 9   | **Open Questions**              | What don't we know yet? What needs research?           |

## PVR Document Structure

The PVR is written progressively as items resolve. Structure:

```markdown
# {Project} — Product Vision & Requirements

**Status:** Draft | In Review | Approved
**Date:** YYYY-MM-DD
**Principal:** {name}
**Agent:** {name}

## Problem Statement

{Resolved in Item 1}

## Target Users

{Resolved in Item 2}

## Use Cases

{Resolved in Item 3}

## Functional Requirements

{Resolved in Item 4}

## Non-Functional Requirements

{Resolved in Item 5}

## Constraints

{Resolved in Item 6}

## Success Criteria

{Resolved in Item 7}

## Non-Goals

{Resolved in Item 8}

## Open Questions

{Resolved in Item 9 — items that need research or deferred decisions}
```

## Rules

- **Use `/discuss` as the protocol.** Don't reinvent the 1B1 cycle. Invoke `/discuss` with the agenda.
- **Write the PVR progressively.** After each item resolves, update the document immediately.
- **Write transcripts progressively.** The `/discuss` protocol handles this via `/transcript`.
- **Don't skip items.** Every checklist item gets discussed, even if the answer is "not applicable" — document why.
- **Seeds inform, they don't dictate.** If a seed document has requirements, present them as proposals for discussion, not as settled decisions.
- **The principal decides.** Present options, make recommendations, but the principal has the final word on every item.

## Artifacts Produced

| Artifact   | Location                                                       | Written                    |
| ---------- | -------------------------------------------------------------- | -------------------------- |
| PVR        | `usr/{principal}/{agent}/{project}-pvr-YYYYMMDD.md` (pre-impl) | Progressively              |
| Transcript | `usr/{principal}/{agent}/transcripts/`                         | Progressively via /discuss |

When implementation launches, the PVR moves to `agency/workstreams/{workstream}/`.
