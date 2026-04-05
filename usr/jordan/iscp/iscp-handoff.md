---
type: session-handoff
date: 2026-04-05
trigger: ISCP v1 complete + code review resolved — awaiting captain re-merge
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Session Handoff

**Agent:** the-agency/jordan/iscp
**Branch:** iscp (worktree at `.claude/worktrees/iscp/`)
**Last commit:** `b2e73f2` — dispatch to captain, all 9 findings fixed

## Current State

**ISCP v1 is complete.** Both phases shipped. Captain code review received and all 9 findings (4 HIGH/MEDIUM + 5 LOW) resolved. 142 BATS tests green. Awaiting captain to re-merge to main.

### Phase 1: Identity + Dispatch + Flag ✅
- 1.1 Design (PVR + A&D)
- 1.2 `_iscp-db` library (51 tests) — `9956644`
- 1.3 `agent-identity` (15 tests) — `86a4f9d`
- 1.4 `dispatch create` (17 tests) — `7721754`
- 1.5 `dispatch` lifecycle (18 tests) — `d50dbff`
- 1.6 `flag` v2 (14 tests) — `3b187e5`

### Phase 2: Hook + Migration + Enforcement ✅
- 2.1 `iscp-check` + hooks (13 tests) — `4d2fb88`
- 2.2 `iscp-migrate` + hookify (14 tests) — `b711ada`

### Post-review fixes
- `AGENCY_PRINCIPAL` env var deprecated — `5fdfa84`
- H1/M1/M2/M3 code review fixes — `aea0f5e`
- L1-L5 code review fixes — `c0f4e7e`

## Bug Found & Fixed: AGENCY_PRINCIPAL Leak

`~/.zshrc` had `export AGENCY_PRINCIPAL="testuser"` (written by `add-principal` tool). Caused all ISCP tools to silently misidentify principal. Fixed: `_path-resolve` and `_address-parse` now always resolve from agency.yaml via `$USER`, never trust pre-set env var. Jordan removed the line from `~/.zshrc`.

## Dispatches Sent (this session)

| # | To | Subject | Type |
|---|-----|---------|------|
| 1 | captain | ISCP v1 ready to land on main | dispatch |
| 2 | captain | CLAUDE-THEAGENCY.md revisions (12 changes) | dispatch |
| 3 | captain | Test leakage + Docker isolation case | escalation |
| 4 | captain | All 9 review findings fixed | review-response |

## Next Action

**Wait for captain to re-merge and roll out.** Captain needs to:
1. Re-merge `iscp` to main
2. Run `iscp-migrate` on main
3. Sync worktrees
4. Apply 12 CLAUDE-THEAGENCY.md revisions

**Then: deferred phases** (dropbox, transcripts, subscriptions) after core is proven.

## Remaining Work (not blocking merge)

- Skill updates (dispatch, flag, session-resume) — skills still reference v1 interface
- Reference doc at `claude/workstreams/iscp/iscp-reference-20260405.md`

## Key Files

| File | What |
|------|------|
| `claude/tools/agent-identity` | Identity resolution with branch-scoped cache |
| `claude/tools/dispatch` | Full dispatch lifecycle |
| `claude/tools/flag` | SQLite-backed flags |
| `claude/tools/iscp-check` | "You got mail" hook |
| `claude/tools/iscp-migrate` | Legacy data migration |
| `claude/tools/lib/_iscp-db` | Shared SQLite library |
| `claude/tools/lib/_path-resolve` | Fixed: AGENCY_PRINCIPAL deprecated |
| `claude/tools/lib/_address-parse` | Fixed: AGENCY_PRINCIPAL deprecated |
| `claude/workstreams/iscp/iscp-reference-20260405.md` | ISCP v1 reference |
| `claude/workstreams/iscp/iscp-plan-20260404.md` | Plan (Phases 1+2 complete) |
