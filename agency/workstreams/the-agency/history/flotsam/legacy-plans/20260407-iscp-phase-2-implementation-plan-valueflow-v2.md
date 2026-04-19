---
title: "ISCP Phase 2 Implementation Plan (Valueflow V2)"
slug: iscp-phase-2-implementation-plan-valueflow-v2
path: docs/plans/20260407-iscp-phase-2-implementation-plan-valueflow-v2.md
date: 2026-04-07
status: draft
branch: iscp
worktree: iscp
prototype: iscp
authors:
  - Test User (principal)
  - Claude Code
session: 1c010e18-a978-4bb4-92fa-8ac43b2849cb
---

# ISCP Phase 2 Implementation Plan (Valueflow V2)

## Context

ISCP v1 is complete: 174 BATS tests green, all tools merged to main, full dispatch/flag/notification infrastructure operational. The Valueflow V2 master plan (`agency/workstreams/agency/valueflow-plan-20260407.md`) assigns Phase 2 to the ISCP workstream: dispatch authority, flag categories, dispatch-on-commit wiring, and health metrics.

My MAR review (dispatch #95, 14 findings) identified that **DB schema versioning is the prerequisite** for all schema-touching work — the current `iscp_db_init()` does `CREATE TABLE IF NOT EXISTS` which silently ignores missing columns. Adding a `category` column to flags (2.3) or any new columns requires a migration framework first.

This plan defines iteration-level implementation for all Phase 2 deliverables.

## Sequencing: 2.0 → 2.1 → 2.3 → 2.2 → 2.4 → 2.5

Rationale: Migration framework (2.0) is prerequisite. Verify baseline (2.1) alongside. Flag categories (2.3) before dispatch authority (2.2) because categories exercise the migration framework on simpler code. Authority (2.2) is the most complex. Commit wiring (2.4) needs `--internal` from 2.2. Metrics (2.5) needs category column from 2.3.

---

## Iteration 2.0: Schema Migration Framework

**Goal:** Enable ALTER TABLE operations via versioned migrations.

**Files:**
- `agency/tools/lib/_iscp-db` — add migration runner, keep `ISCP_SCHEMA_VERSION=1`

**Changes:**
1. Add `_iscp_run_migrations(db_path, current_ver, target_ver)` function: iterates from current to target, calling `_iscp_migrate_vN_to_vN+1()` for each step, wrapped in BEGIN/COMMIT
2. Refactor `iscp_db_init()` (line 375): when `current_version < ISCP_SCHEMA_VERSION`, call `_iscp_run_migrations()` instead of re-running `_iscp_schema_ddl()`
3. For fresh installs (no DB file): continue with `_iscp_schema_ddl()` + set `user_version`
4. Each migration function emits SQL to stdout — the runner wraps it in a transaction
5. Add `_iscp_migrate_v0_to_v1()` that outputs `_iscp_schema_ddl` — enables testing the framework against v0→v1

**Tests** (`tests/tools/iscp-db.bats`, ~8 new):
- Fresh install creates DB at current version
- DB at current version: init returns immediately (no regression)
- DB at version > tool: FATAL error preserved
- DB at version 0: migration upgrades to v1
- Migration calls functions sequentially
- Migration failure: DB stays at old version
- All 51 existing tests pass

**Acceptance:** `_iscp_run_migrations()` exists, called on version mismatch, no regressions.

**Estimate:** 2-3 hours

---

## Iteration 2.1: Symlink Verify

**Goal:** Confirm baseline — all 174 tests green, symlink dispatch architecture works.

**Changes:** None. Run `bats tests/tools/iscp-db.bats tests/tools/agent-identity.bats tests/tools/dispatch-create.bats tests/tools/dispatch.bats tests/tools/flag.bats tests/tools/iscp-check.bats tests/tools/iscp-migrate.bats`

**Acceptance:** All 174 tests pass. Document in plan status.

**Estimate:** 15 minutes

---

## Iteration 2.3: Flag Categories

**Goal:** Add `--friction`, `--idea`, `--bug` category flags. First real schema migration.

**Files:**
- `agency/tools/lib/_iscp-db` — bump to v2, add migration, update DDL and insert helper
- `agency/tools/flag` — category parsing, filtered queries

**Changes to `_iscp-db`:**
1. Bump `ISCP_SCHEMA_VERSION` to `2`
2. Add `_iscp_migrate_v1_to_v2()`: `ALTER TABLE flags ADD COLUMN category TEXT CHECK(category IN ('friction', 'idea', 'bug'));`
3. Update `_iscp_schema_ddl()` flags table: add `category` column (fresh installs get v2 directly)
4. Update `iscp_db_insert_flag()`: accept optional category param, add `:category` to INSERT

**Changes to `flag`:**
1. Parse `--friction`, `--idea`, `--bug` flags (position-independent, before or after `--to`)
2. Pass category to `iscp_db_insert_flag()`
3. `flag list --category <cat>`: append `AND category = :cat` to WHERE clause, show `[friction]` labels
4. `flag count --category <cat>`: filtered count
5. `flag discuss`: include category label if non-null

**Tests** (`tests/tools/flag.bats` ~12 new, `tests/tools/iscp-db.bats` ~4 new):
- Category capture roundtrip for each type (friction, idea, bug)
- No-category backward compat (NULL)
- Combined `--to` + category
- Filtered list, count
- Migration v1→v2 adds column, existing rows get NULL
- Fresh v2 install has category column

**Acceptance:** Existing 18 flag tests pass unchanged. `flag --friction "msg"` stored with category, filterable via `flag list --category friction`.

**Estimate:** 3-4 hours

---

## Iteration 2.2: Dispatch Authority Enforcement

**Goal:** Gate `dispatch create` by agent role × dispatch type (A&D §4).

**Files:**
- `agency/tools/dispatch` — authority check in `cmd_create()`
- `agency/tools/git-safe-commit` — add `--internal` flag to commit dispatch call

**Authority matrix (hardcoded — captain detected by agent name suffix `/captain`):**

| Type | Who can create |
|------|---------------|
| `directive`, `review`, `master-updated` | Captain only |
| `seed`, `escalation`, `dispatch` | Any agent |
| `commit` | Any agent with `--internal` flag (used by git-safe-commit) |
| `review-response` | Agent who received the original review (`--reply-to` required, `to_agent` of original must match sender) |

**Changes to `dispatch`:**
1. Add `_check_authority(type, from_agent, reply_to_id)` function after identity resolution (~line 285)
2. Captain check: `[[ "$from_agent" == */captain ]]`
3. Commit check: `[[ "$internal_flag" == "true" ]]`
4. Review-response check: query `SELECT to_agent FROM dispatches WHERE id = :reply_to_id`, verify matches `from_agent`
5. Add `--internal` to argument parsing (no-op for non-commit types)
6. Clear error messages: "Error: dispatch type 'directive' requires captain role. Current agent: the-agency/jordan/iscp"

**Changes to `git-safe-commit`:**
- Line 422: add `--internal` flag to dispatch create call

**Tests** (`tests/tools/dispatch.bats`, ~11 new):
- Captain creates directive ✓, non-captain fails ✗
- Captain creates review ✓, non-captain fails ✗
- Any agent creates seed, escalation, dispatch ✓
- Commit type requires `--internal`
- Review-response requires valid `--reply-to` matching sender
- Review-response with wrong reply-to fails

**Risk:** Existing dispatch tests that create captain-only types with non-captain mock identity will break. Audit all 39 tests and update identity mocks.

**Acceptance:** Unauthorized `dispatch create` fails with actionable error. All existing tests pass (updated for authority).

**Estimate:** 4-5 hours

---

## Iteration 2.4: Dispatch-on-Commit Wiring

**Goal:** Populate phase/iteration fields in commit dispatches, verify end-to-end.

**Files:**
- `agency/tools/git-safe-commit` — add phase/iteration to metadata block

**Changes:**
1. Lines 410-415: Add `phase` and `iteration` fields from env vars `ISCP_PHASE` and `ISCP_ITERATION` (set by `/iteration-complete` skill), fallback to "none"
2. Add `--internal` flag (from 2.2)
3. Verify commit dispatch body includes all structured fields

**Tests** (~5 new):
- Commit on worktree dispatches to captain with structured body
- Commit on main does NOT dispatch
- Phase/iteration populated from env vars
- Phase/iteration default to "none"
- Captain does not dispatch to self

**Acceptance:** Every worktree commit auto-dispatches to captain with phase/iteration metadata.

**Estimate:** 2-3 hours

---

## Iteration 2.5: Health Metrics Data Layer

**Goal:** New `iscp-metrics` tool for lead time and flag rate queries.

**Files:**
- `agency/tools/iscp-metrics` — NEW (~200 lines)
- `tests/tools/iscp-metrics.bats` — NEW

**Subcommands:**
- `iscp-metrics dispatch-lead-time [--since DATE]` — `resolved_at - created_at` for resolved dispatches
- `iscp-metrics dispatch-response-time [--since DATE]` — `read_at - created_at` for read dispatches
- `iscp-metrics flag-rates [--since DATE] [--period day|week]` — counts by category / time period
- `iscp-metrics summary [--since DATE]` — combined markdown + YAML block

**Output:** Markdown table (human) + YAML block at end (machine):
```yaml
---
generated: 2026-04-07T14:30
dispatch_count: 47
avg_lead_time_hours: 2.3
avg_response_time_minutes: 12
flag_rates:
  friction: 0.7/day
  idea: 0.3/day
  bug: 0.1/day
---
```

**Date math:** SQLite `julianday()` for time differences.

**Tests** (`tests/tools/iscp-metrics.bats`, ~13 new):
- Help/version output
- Empty DB produces zero-value report
- Dispatch lead time with known timestamps
- Response time with read dispatches
- Flag rates by category (including NULL/uncategorized)
- `--since` date filter
- Summary combined output with YAML

**Acceptance:** `iscp-metrics summary` produces accurate metrics from DB data, handles empty DB gracefully.

**Estimate:** 4-5 hours

---

## Summary

| Iter | Deliverable | Files | New Tests | Est | Deps |
|------|-------------|-------|-----------|-----|------|
| 2.0 | Migration framework | `_iscp-db` | ~8 | 2-3h | — |
| 2.1 | Baseline verify | — | 0 | 15m | — |
| 2.3 | Flag categories | `_iscp-db`, `flag` | ~16 | 3-4h | 2.0 |
| 2.2 | Dispatch authority | `dispatch`, `git-safe-commit` | ~11 | 4-5h | — |
| 2.4 | Commit wiring | `git-safe-commit` | ~5 | 2-3h | 2.2 |
| 2.5 | Health metrics | NEW `iscp-metrics` | ~13 | 4-5h | 2.3 |
| **Total** | | **5 files** | **~53** | **~16-21h** | |

## Verification

After each iteration:
1. Run full ISCP test suite: `bats tests/tools/iscp-db.bats tests/tools/agent-identity.bats tests/tools/dispatch-create.bats tests/tools/dispatch.bats tests/tools/flag.bats tests/tools/iscp-check.bats tests/tools/iscp-migrate.bats`
2. Verify no regression in existing 174 tests
3. Run new tests for the iteration
4. `/iteration-complete` at each boundary

After Phase 2 complete:
- `flag --friction "test"` → `flag list --category friction` roundtrip
- `dispatch create --type directive` as non-captain → rejected
- `iscp-metrics summary` → accurate output
- Full test count: ~227 tests (174 existing + ~53 new)

## Open Questions for Captain/Principal

1. **SMS-style dispatches** (flag #1 in queue): deferred or Phase 2.6?
2. **BUG 2** (`dispatch list --all` shows other agents' unread): fix in Phase 2 or defer?
3. **Fresh worktree vs reuse**: should I branch from current main for Phase 2 work?
