---
allowed-tools: Read, Write, Edit, Glob, Bash(date *), Bash(git branch *)
description: Drive toward a complete A&D (Architecture & Design) using the 1B1 protocol with a completeness checklist
---

# /design

Drive a structured discussion toward a complete **Architecture & Design (A&D)** document. Uses `/discuss` as the protocol and brings the agenda — the completeness checklist ensures nothing is missed.

Typically follows `/define` — the PVR informs the architecture. But definition and design evolve side by side. It's fine to run `/design` mid-definition if architecture questions arise.

## Usage

```
/design                           — start from scratch, ask what we're designing
/design "Project Name"            — start with a named project
/design --from <pvr-file>         — derive agenda from an existing PVR
/design --continue <ad-file>      — resume design using an existing A&D's gaps
```

## Behavior

When invoked:

1. **Establish context.** If a project name or PVR is provided, read it. If not, ask: "What are we designing?" If a PVR exists, load it — requirements inform architecture.

2. **Scan for existing work.** Check for an existing A&D in:
   - `claude/workstreams/{workstream}/` (shared, post-implementation)
   - `usr/{principal}/{agent}/` (instance, pre-implementation)
     If found, load it and identify gaps against the checklist.

3. **Build the discussion agenda.** Map the completeness checklist to discussion items. If a PVR exists, connect each design item to the requirements it addresses. If resuming from an existing A&D, only include items that are empty or marked as open.

4. **Start the discussion.** Invoke `/discuss` with the agenda items. The `/discuss` protocol handles the 1B1 cycle, transcript capture, and resolution tracking.

5. **After each item resolves,** update the A&D document progressively. Also update the PVR if design decisions reveal requirement changes — the two evolve together.

6. **On completion,** present the A&D completeness scorecard and ask: "Ready to move to planning, or are there items to revisit?"

## Completeness Checklist

These are the items that a complete A&D must cover. Each becomes a discussion item:

| #   | Topic                        | What to resolve                                                                    |
| --- | ---------------------------- | ---------------------------------------------------------------------------------- |
| 1   | **Architecture Overview**    | High-level structure, components, boundaries. How the pieces fit together.         |
| 2   | **Data Model**               | Entities, relationships, storage. Schema design, data flow.                        |
| 3   | **Interfaces**               | APIs, protocols, contracts. How components communicate.                            |
| 4   | **Dependencies**             | External services, libraries, frameworks. What we rely on.                         |
| 5   | **Technology Choices**       | Languages, frameworks, infrastructure. With rationale for each choice.             |
| 6   | **Trade-offs**               | What we chose and what we gave up. Document the why — not just the what.           |
| 7   | **Failure Modes**            | What can go wrong and how we handle it. Error paths, degraded operation, recovery. |
| 8   | **Security Considerations**  | Auth, data protection, attack surface. Trust boundaries.                           |
| 9   | **Deployment & Operations**  | How it runs. Environments, monitoring, scaling, rollback.                          |
| 10  | **Open Technical Questions** | What needs prototyping, benchmarking, or research before implementation?           |

## A&D Document Structure

The A&D is written progressively as items resolve. Structure:

```markdown
# {Project} — Architecture & Design

**Status:** Draft | In Review | Approved
**Date:** YYYY-MM-DD
**Principal:** {name}
**Agent:** {name}
**PVR:** {link to PVR if exists}

## Architecture Overview

{Resolved in Item 1}

## Data Model

{Resolved in Item 2}

## Interfaces

{Resolved in Item 3}

## Dependencies

{Resolved in Item 4}

## Technology Choices

{Resolved in Item 5}

## Trade-offs

{Resolved in Item 6}

## Failure Modes

{Resolved in Item 7}

## Security Considerations

{Resolved in Item 8}

## Deployment & Operations

{Resolved in Item 9}

## Open Technical Questions

{Resolved in Item 10 — items that need prototyping or research}
```

## Rules

- **Use `/discuss` as the protocol.** Don't reinvent the 1B1 cycle. Invoke `/discuss` with the agenda.
- **Write the A&D progressively.** After each item resolves, update the document immediately.
- **Update the PVR when design reveals requirement changes.** The two documents evolve together.
- **Write transcripts progressively.** The `/discuss` protocol handles this via `/transcript`.
- **Don't skip items.** Every checklist item gets discussed, even if the answer is "not applicable" — document why.
- **Show your reasoning.** For technology choices and trade-offs, explain the alternatives considered and why they were rejected. The "why not" is as important as the "why."
- **The principal decides.** Present options with pros/cons and a recommendation, but the principal has the final word.

## Artifacts Produced

| Artifact    | Location                                                      | Written                    |
| ----------- | ------------------------------------------------------------- | -------------------------- |
| A&D         | `usr/{principal}/{agent}/{project}-ad-YYYYMMDD.md` (pre-impl) | Progressively              |
| PVR updates | Same location as existing PVR                                 | As needed                  |
| Transcript  | `usr/{principal}/{agent}/transcripts/`                        | Progressively via /discuss |

When implementation launches, the A&D moves to `claude/workstreams/{workstream}/`.
