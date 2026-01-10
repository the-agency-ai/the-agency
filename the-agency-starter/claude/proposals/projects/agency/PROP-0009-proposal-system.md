# PROP-0009: Proposal System (Meta)

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Ideas and discussions happen that aren't ready to be INSTRs:
1. Need discussion before commitment
2. Need definition before implementation
3. Need a queue for tracking ideas through lifecycle
4. Need visibility into what's being considered

Currently these get lost or scattered across working notes and conversations.

## Proposal

A formal proposal system that sits between "idea" and "instruction."

### Lifecycle

```
draft → discussing → defined → approved → implementing → completed
  ↓         ↓           ↓          ↓            ↓           ↓
Write    Refine     Add specs   Becomes     Do work      Done
idea     together    & details   INSTR
```

### Directory Structure

```
claude/proposals/
├── projects/
│   └── agency/
│       ├── INDEX.md
│       ├── .prop-counter
│       └── PROP-0001-*.md
└── workstreams/
    └── {workstream}/
        ├── INDEX.md
        ├── .prop-counter
        └── PROP-0001-*.md
```

### Naming Convention

- **Project proposals:** `PROP-PROJ-AGENCY-0001` (full) or `PROP-0001` (in context)
- **Workstream proposals:** `PROP-WS-WEB-0001` (full) or `PROP-0001` (in context)

### Tools

```bash
./tools/capture-proposal -t "Title" [-p project] [-w workstream]
./tools/list-proposals [-p project] [-w workstream] [-s status]
./tools/update-proposal PROP-0001 --status discussing
./tools/approve-proposal PROP-0001  # Creates INSTR, links back
./tools/abandon-proposal PROP-0001 --reason "Superseded by..."
```

### Proposal Template

```markdown
# PROP-NNNN: Title

**Status:** draft
**Priority:** high | medium | low
**Created:** YYYY-MM-DD
**Author:** who
**Project:** which project/workstream

## Problem
What problem does this solve?

## Proposal
What's the proposed solution?

## Key Points
- Bullet points

## Open Questions
- [ ] Unanswered questions

## Dependencies
- Related proposals
- Related INSTRs

## When Approved
- Becomes: INSTR-XXXX
- Assigned to: agent
- Target: version/date

---

## Discussion Log
### YYYY-MM-DD - Event
Notes about discussion.
```

### Integration

- TheCaptain knows about proposals for guidance
- `how` command can reference proposals
- Proposals appear in status/briefing

## Key Points

- Fills gap between idea and instruction
- Structured lifecycle prevents losing ideas
- Discussion log preserves context
- Clear path from proposal → INSTR

## Open Questions

- [x] Where do proposals live? → `claude/proposals/`
- [x] Naming convention? → `PROP-NNNN` with project/workstream prefix
- [ ] How to handle cross-project proposals?
- [ ] Voting/approval process for community proposals?

## Dependencies

- Related proposals: none (this is meta)
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.1.0 (already implementing!)

---

## Discussion Log

### 2026-01-06 - Created
Jordan: "We need a mechanism... whatever we come up with here, each cluster is one of those."

### 2026-01-06 - Implementing
Created during discussion. This proposal documents the system being built.
