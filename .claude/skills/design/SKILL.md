---
allowed-tools: Read, Write, Edit, Glob, Grep, Skill
description: Drive toward a complete Architecture & Design (A&D) using 1B1 protocol with completeness checklist.
---

# Design — A&D Completeness

Drive toward complete Architecture & Design (A&D) using the 1B1 protocol with a completeness checklist. Typically follows `/define` — the PVR informs architecture.

## Usage

- `/design` — start fresh, auto-detect project
- `/design "Project Name"` — start fresh for named project
- `/design --from <pvr-file>` — use PVR as input
- `/design --continue <ad-file>` — resume work on an existing A&D

## Behavior

### Step 1: Establish context

If `--from` specified, read the PVR. If `--continue`, read the existing A&D. If a PVR exists for this project, load it automatically.

### Step 2: Scan for existing work

Glob `claude/workstreams/*/**/*-ad-*.md`, `claude/workstreams/*/**/*-architecture-*.md`, and `usr/*/**/*-architecture-*.md` for existing A&D files. If found, offer to continue.

### Step 3: Build discussion agenda

Map the completeness checklist to discussion items. Skip items already covered.

### Step 4: Start discussion

Invoke `/discuss` via the Skill tool, passing the agenda items.

### Step 5: Update A&D progressively

After each item resolves, update the A&D file. Also update the PVR if design decisions reveal requirement changes.

A&D location: `claude/workstreams/{workstream}/{project}-ad-{YYYYMMDD}.md` or `usr/{principal}/{project}/{project}-architecture-{YYYYMMDD}.md`.

### Step 6: Present completeness scorecard

```
A&D Completeness:

1. Architecture Overview    ✓ Complete
2. Data Model               ✓ Complete
3. Interfaces               ✓ Complete
4. Dependencies             ✓ Complete
5. Technology Choices       ✓ Complete
6. Trade-offs               ✓ Complete
7. Failure Modes            ~ Partial
8. Security Considerations  ✓ Complete
9. Deployment & Operations  ✓ Complete
10. Open Technical Questions 1 remaining

Score: 9/10 complete
```

## Completeness Checklist

1. **Architecture Overview** — High-level system design, component relationships
2. **Data Model** — Entities, relationships, storage strategy
3. **Interfaces** — APIs, protocols, contracts between components
4. **Dependencies** — External services, libraries, infrastructure
5. **Technology Choices** — Languages, frameworks, databases, and why
6. **Trade-offs** — What was considered and rejected, with reasoning
7. **Failure Modes** — What can go wrong? How does the system degrade?
8. **Security Considerations** — Auth, data protection, attack surface
9. **Deployment & Operations** — How it runs, scales, is monitored
10. **Open Technical Questions** — Unresolved technical items
