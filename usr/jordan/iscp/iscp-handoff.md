---
type: handoff
agent: the-agency/jordan/iscp
workstream: iscp
date: 2026-04-07
trigger: session-end
---

## Identity

`the-agency/jordan/iscp` -- ISCP workstream agent. I build and maintain the Inter-Session Communication Protocol: the notification, dispatch, and flag infrastructure that connects all agents.

## Current State

ISCP v1 complete, 182 BATS tests green. Branch `iscp`. **Iteration 2.0 (schema migration framework) is COMPLETE and committed** (`e24b2b4`).

Migration framework delivers:
- `_iscp_run_migrations()` — sequential runner, per-step transactions, version bump on success, partial failure preservation
- `_iscp_migrate_v0_to_v1()` — outputs full v1 DDL
- `iscp_db_init()` refactored to use migration runner for existing-DB upgrades
- 8 new tests covering all migration paths (59 iscp-db tests, 182 full suite)

## Phase 2 Plan (approved)

Plan file: `/Users/jdm/.claude/plans/cozy-coalescing-steele.md`

Sequencing: 2.0 → 2.1 → 2.3 → 2.2 → 2.4 → 2.5

| Iter | Deliverable | Status |
|------|-------------|--------|
| 2.0 | Schema migration framework | **DONE** — committed `e24b2b4` |
| 2.1 | Baseline verify (174 tests) | **DONE** — all pass (now 182) |
| 2.3 | Flag categories | **NEXT** |
| 2.2 | Dispatch authority | Not started |
| 2.4 | Dispatch-on-commit wiring | Not started |
| 2.5 | Health metrics data layer | Not started |

## Dispatches

All dispatches resolved. No unread items.

## Flags in Queue (4 items)

Backlog material — SMS dispatches, captain's log, friction→toolification, release notes process. Not urgent.

## Key Decisions

- Migration framework design: each `_iscp_migrate_vN_to_vN+1()` emits SQL to stdout; runner wraps in BEGIN/COMMIT + PRAGMA user_version bump
- `ISCP_SCHEMA_VERSION` stays at 1 for iteration 2.0 (framework only); bumps to 2 in iteration 2.3 when flag categories add the first real migration
- Dispatch authority: captain detected by agent name suffix `/captain` (hardcoded, not config)
- Review-response authority: sender must match `to_agent` of the original review dispatch

## Next Action

1. Start iteration 2.3: Flag categories
   - Add `category` column to flags table via v1→v2 migration
   - Update `flag` tool to accept `--category` option
   - Update `flag list` / `flag discuss` to show/filter by category
   - Write tests for migration + category functionality
2. Then proceed to 2.2 (dispatch authority)
