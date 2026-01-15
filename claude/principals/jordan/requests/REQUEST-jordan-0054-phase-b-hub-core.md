# REQUEST-jordan-0054: Phase B - Hub Core

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Complete
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

| ID | Task | Description | Depends On | Status | Commit |
|----|------|-------------|------------|--------|--------|
| B1 | ./agency command | Create launcher script | - | Done | a3f4dea |
| B2 | Hub Agent | Create `claude/agents/hub/agent.md`, `KNOWLEDGE.md` | - | Done | 55dd7ef |
| B3 | Update starter | Hub can git fetch/pull, handle conflicts | B1, B2 | Done | In KNOWLEDGE.md |
| B4 | List projects | Hub shows all projects with status | B1, B2, A3 | Done | In KNOWLEDGE.md |
| B5 | What's new | Hub reads CHANGELOG, shows updates | B1, B2 | Done | In KNOWLEDGE.md |

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

- [x] `./agency` launches Hub Agent
- [x] Hub Agent can update the starter
- [x] Hub Agent can list all registered projects
- [x] Hub Agent can show what's new since last update

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase B
- Started Phase B after Phase A completion
- Created COLLABORATE-0003 for B1 (./agency command) → foundation-alpha
- Created COLLABORATE-0004 for B2 (Hub Agent) → foundation-beta

**B1 Complete:** foundation-alpha created ./agency entry point
- Commit: a3f4dea
- Executable script that launches Hub Agent
- Supports optional initial command argument

**B2 Complete:** foundation-beta created Hub Agent
- Commit: 55dd7ef
- Full agent.md with identity, purpose, capabilities
- KNOWLEDGE.md with operational procedures for B3, B4, B5

**B3, B4, B5:** Implemented via Hub Agent's KNOWLEDGE.md
- Update starter: git operations documented
- List projects: .agency/projects.json parsing
- What's new: CHANGELOG.md and VERSION reading

**Phase B Complete:** All success criteria met
