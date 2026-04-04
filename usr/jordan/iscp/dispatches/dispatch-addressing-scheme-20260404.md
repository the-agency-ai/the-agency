# Dispatch: Addressing Scheme for Flag/Dispatch

**Date:** 2026-04-04
**From:** the-agency/jordan/captain
**To:** the-agency/jordan/iscp
**Priority:** Foundational — must be resolved before implementation

---

## Decision (from captain discussion 2026-04-04, Item 4)

Two addressing targets for flag and dispatch:

### Agent Addressing

Uses the existing Agency hierarchy:

```
{org}/{repo}/{principal}/{agent}
```

- Bare: `captain` — resolve repo+principal from context
- Principal-scoped: `jordan/captain`
- Fully qualified: `the-agency/jordan/captain`
- Org-qualified: `the-agency-ai/the-agency/jordan/captain` (rare)

**Payload location:** `usr/{principal}/{agent-project}/dispatches/`

### Workstream Addressing

New. Repo-level, no principal scoping — matches `claude/workstreams/{name}/` hierarchy:

```
{repo}/{workstream}
```

- Bare: `iscp` — resolve repo from context
- Fully qualified: `the-agency/iscp`

**Payload location:** `claude/workstreams/{workstream}/dispatches/`

### Flag vs Dispatch

- **Flag:** DB-only (notification + content in SQLite). Same addressing scheme, no git payload location.
- **Dispatch:** Notification in DB + payload in git at the resolved path above.

### Disambiguation

Bare form `iscp` could be agent or workstream. Resolution order:
1. Check `claude/workstreams/{name}/` — if exists, it's a workstream
2. Check agent registrations — if exists, it's an agent
3. Fail with actionable error

### Reference

- CLAUDE-THEAGENCY.md § "Agent & Principal Addressing" — full hierarchy definition
- `claude/tools/lib/_path-resolve` — current resolution library (has env leak bugs to fix)

## Action

Incorporate this addressing scheme into the ISCP PVR and A&D. This is the foundation for all routing.
