---
type: session-handoff
date: 2026-04-05
trigger: ISCP v1 complete — Phases 1 and 2 shipped
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Session Handoff

**Agent:** the-agency/jordan/iscp
**Branch:** iscp (worktree at `.claude/worktrees/iscp/`)
**Last commit:** `b711ada` Phase 2.2: iscp-migrate + hookify rules

## Current State

**ISCP v1 is complete.** Both phases shipped. 142 BATS tests all green.

### Phase 1: Identity + Dispatch + Flag ✅
- 1.1 Design (PVR + A&D)
- 1.2 `_iscp-db` library (51 tests) — commit `9956644`
- 1.3 `agent-identity` tool (15 tests) — commit `86a4f9d`
- 1.4 `dispatch create` subcommand (17 tests) — commit `7721754`
- 1.5 `dispatch` lifecycle (18 tests) — commit `d50dbff`
- 1.6 `flag` v2 (14 tests) — commit `3b187e5`

### Phase 2: Hook + Migration + Enforcement ✅
- 2.1 `iscp-check` + hook wiring (13 tests) — commit `4d2fb88`
- 2.2 `iscp-migrate` + hookify rules (14 tests) — commit `b711ada`

## What's Operational

- **Dispatches:** create, list, read, check, resolve, status — DB + git payload
- **Flags:** capture, list, count, discuss, clear — DB-only, agent-addressable
- **Notifications:** iscp-check fires on SessionStart, UserPromptSubmit, Stop — silent when empty, JSON systemMessage when items waiting
- **Migration:** iscp-migrate imports legacy JSONL flags and markdown dispatches
- **Enforcement:** 5 hookify rules (dispatch-manual, flag-manual, directive-authority, review-authority, session-start-mail)

## Next Action

**Land on main.** ISCP v1 is feature-complete. The branch needs:
1. Merge from main (pick up any recent changes)
2. Phase-complete QG (deep review)
3. Land on main via `/phase-complete` or captain coordination
4. Captain runs `/sync-all` to distribute to all worktrees

**Then: deferred phases** (dropbox, transcripts, subscriptions, integration) — these ship after the core is operational and proven.

## Key Files

| File | What |
|------|------|
| `claude/tools/agent-identity` | Unified "who am I" with branch-scoped cache |
| `claude/tools/dispatch` | Full dispatch lifecycle (create/list/read/check/resolve/status) |
| `claude/tools/dispatch-create` | Thin wrapper → `dispatch create` |
| `claude/tools/flag` | SQLite-backed flags, agent-addressable |
| `claude/tools/iscp-check` | "You got mail" hook — silent or JSON systemMessage |
| `claude/tools/iscp-migrate` | Legacy data migration (JSONL flags + markdown dispatches) |
| `claude/tools/lib/_iscp-db` | Shared SQLite library |
| `.claude/settings.json` | Hook wiring + permissions |
| `claude/hookify/hookify.*.md` | 5 enforcement rules |
| `claude/workstreams/iscp/iscp-plan-20260404.md` | Plan (living document) |

## Known Issues

- Skill updates (dispatch, flag, session-resume) noted in plan but not yet done — skills still reference v1 interface
- Main checkout has stale copies of PVR/A&D — canonical versions on iscp branch
- `handoff` tool principal resolution may still have AGENCY_PRINCIPAL leak (not patched in handoff tool itself)
