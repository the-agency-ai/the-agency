# WORKNOTE: Parallel Agent Case Study

**Date:** 2026-01-15
**Context:** REQUEST-jordan-0053 (Phase A - Foundation)
**Coordinator:** captain

---

## Overview

This WORKNOTE documents a case study of parallel agent execution in The Agency. Multiple Claude Code instances work on independent tasks while a coordinator (captain) manages the overall effort.

---

## The Setup

### Task Breakdown (REQUEST-0053: Phase A)

| Task | Description | Dependencies | Assigned To |
|------|-------------|--------------|-------------|
| A1 | Manifest schema | - | captain |
| A2 | Registry schema | - | captain |
| A3 | Project registry schema | - | captain |
| A4 | Update project-new | A1, A3 | Agent (TBD) |
| A5 | Update project-update --init | A1 | Agent (TBD) |
| A6 | myclaude service check | - | Agent (TBD) |

### Parallelization Strategy

```
Wave 1 (Parallel):
  Terminal 1: captain      → A1, A2, A3 (schemas - need consistency)
  Terminal 2: agent        → A6 (independent)

Wave 2 (After schemas complete):
  Terminal 3: agent        → A4 (depends on A1, A3)
  Terminal 4: agent        → A5 (depends on A1)
```

---

## Coordination Protocol

### Principle: Single Writer to REQUEST Files

The coordinator (captain) is the **only agent that updates REQUEST files**. This eliminates merge conflicts entirely.

### Communication Flow

```
┌─────────────┐     collaborate     ┌─────────────┐
│   captain   │ ──────────────────► │   agent     │
│ (coordinator)│                     │  (worker)   │
└─────────────┘                     └─────────────┘
       ▲                                   │
       │      collaboration-respond        │
       └───────────────────────────────────┘
```

1. **Captain creates task** via `./tools/collaborate`
2. **Agent works independently** on assigned task
3. **Agent commits code** directly (no conflicts - separate files)
4. **Agent reports completion** via `./tools/collaboration-respond`
5. **Captain updates REQUEST** with consolidated status

### What Agents Can Update Directly

- Code files they're assigned to modify
- Their own WORKLOG.md (if they have one)
- Test files for their changes

### What Only Captain Updates

- REQUEST-*.md files (status, work log)
- Cross-cutting documentation
- Final success criteria checkmarks

---

## Execution Log

### Wave 1: Setup

**Timestamp:** 2026-01-15 [START]

- [ ] Captain begins schema design (A1, A2, A3)
- [ ] Agent launched for A6 (myclaude service check)

### Wave 1: Completion

*To be filled as work completes*

### Wave 2: Setup

*To be filled when Wave 1 completes*

### Wave 2: Completion

*To be filled as work completes*

---

## Observations

### What Worked Well

*To be filled during/after execution*

### Challenges Encountered

*To be filled during/after execution*

### Lessons Learned

*To be filled after completion*

---

## Metrics

| Metric | Value |
|--------|-------|
| Total tasks | 6 |
| Parallel waves | 2 |
| Agents used | TBD |
| Time to completion | TBD |
| Conflicts encountered | TBD |

---

## Recommendations

*To be filled after completion*
