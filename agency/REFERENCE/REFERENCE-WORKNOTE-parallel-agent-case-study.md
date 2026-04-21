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

| Task | Description | Dependencies | Assigned To | Status |
|------|-------------|--------------|-------------|--------|
| A1 | Manifest schema | - | captain | DONE |
| A2 | Registry schema | - | captain | DONE |
| A3 | Project registry schema | - | captain | DONE |
| A4 | Update project-create | A1, A3 | COLLABORATE-0001 | PENDING |
| A5 | Update project-update --init | A1 | COLLABORATE-0002 | PENDING |
| A6 | myclaude service check | - | subagent | DONE |

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

1. **Captain creates task** via `./agency/tools/collaborate`
2. **Agent works independently** on assigned task
3. **Agent commits code** directly (no conflicts - separate files)
4. **Agent reports completion** via `./agency/tools/collaboration-respond`
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

**Timestamp:** 2026-01-15

- [x] Captain begins schema design (A1, A2, A3)
- [x] Subagent launched for A6 (myclaude service check)

### Wave 1: Completion

**A6 (subagent):** Completed - added `check_services()` function to myclaude
- Interactive prompts for Bun install, dependency install, service start
- Follows quiet-by-default pattern
- Commit: cda8f39

**A1, A2, A3 (captain):** Completed - created all schemas
- `agency/REFERENCE/schemas/manifest.schema.json`
- `agency/REFERENCE/schemas/registry.schema.json`
- `agency/REFERENCE/schemas/projects.schema.json`
- `registry.json` (actual component registry)
- Commit: 86ba7ce

### Wave 2: Setup

**Timestamp:** 2026-01-15

- [x] COLLABORATE-0001 created for A4 (project-create updates)
- [x] COLLABORATE-0002 created for A5 (project-update --init)
- [ ] Agents launched via `./agency/tools/dispatch-collaborations`

### Wave 2: Completion

*Waiting for agents to complete tasks*

---

## Observations

### What Worked Well

*To be filled during/after execution*

### Challenges Encountered

**Challenge 1: Agents don't auto-activate on launch**
- **Issue:** When agents launched, they greeted the user but didn't automatically check for pending collaborations
- **Workaround:** Manually prompt each agent to check `./agency/tools/collaboration-pending`
- **Future fix:** AGENTNIT-0001 - Add auto-check on launch via ONBOARDING.md, myclaude hook, or dispatch-collaborations enhancement

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
