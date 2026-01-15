# REQUEST-jordan-0054: Phase B - Hub Core

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** In Progress
**Priority:** High
**Created:** 2026-01-15
**Parent:** REQUEST-jordan-0052
**Blocked By:** REQUEST-jordan-0053

---

## Summary

Create the Hub Agent and `./agency` command - the centerpiece of the agent-driven update system.

---

## Context

This is Phase B of REQUEST-0052. The Hub Agent is the meta-agent that manages the starter and all projects created from it. After initial install, this is how users interact with The Agency.

---

## Tasks

| ID | Task | Description | Depends On | Status |
|----|------|-------------|------------|--------|
| B1 | ./agency command | Create launcher script | - | Pending |
| B2 | Hub Agent | Create `claude/agents/hub/agent.md`, `KNOWLEDGE.md` | - | Pending |
| B3 | Update starter | Hub can git fetch/pull, handle conflicts | B1, B2 | Pending |
| B4 | List projects | Hub shows all projects with status | B1, B2, A3 | Pending |
| B5 | What's new | Hub reads CHANGELOG, shows updates | B1, B2 | Pending |

---

## Deliverables

### B1: ./agency Command

```bash
#!/bin/bash
# Launch the Hub Agent in the-agency-starter
cd "$(dirname "$0")"
./tools/myclaude housekeeping hub
```

### B2: Hub Agent

```
claude/agents/hub/
  agent.md       # Identity: "I am the Hub Agent..."
  KNOWLEDGE.md   # How to manage starter and projects
```

Capabilities:
- Understand the registry and manifest schemas
- Know how to update the starter (git operations)
- Know how to read/update project registry
- Know how to invoke project-new and project-update

### B3-B5: Hub Operations

Documented in Hub Agent's KNOWLEDGE.md as standard operating procedures.

---

## Success Criteria

- [ ] `./agency` launches Hub Agent
- [ ] Hub Agent can update the starter
- [ ] Hub Agent can list all registered projects
- [ ] Hub Agent can show what's new since last update

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase B
