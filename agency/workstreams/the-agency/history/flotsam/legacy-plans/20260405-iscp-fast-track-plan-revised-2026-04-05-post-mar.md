---
title: "ISCP Fast-Track Plan — Revised 2026-04-05 (Post-MAR)"
slug: iscp-fast-track-plan-revised-2026-04-05-post-mar
path: docs/plans/20260405-iscp-fast-track-plan-revised-2026-04-05-post-mar.md
date: 2026-04-05
status: draft
branch: iscp
worktree: iscp
prototype: iscp
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 3493ed9c-c4f6-4db8-9884-e492d234f1fa
tags: [Frontend, Infra]
---

# ISCP Fast-Track Plan — Revised 2026-04-05 (Post-MAR)

## Context

ISCP needs to be operational ASAP. mdpal-cli is waiting to be our first consumer. The `_iscp-db` library is complete (51 tests). `_address-parse` is complete. We have working v1 tools that show patterns. Principal wants systematic but fast.

**Pre-implementation:** Write dispatch responses to captain (types approved — ACK) and mdpal-cli (alignment findings — detailed response with type mapping, structured payload open item, DB polling confirmed, joint milestone accepted).

## MAR Findings Incorporated

Key changes from initial plan based on 3-agent MAR:
1. **Merge dispatch-create into dispatch** as `create` subcommand per A&D spec (F-5)
2. **Split dispatch iteration** — create vs lifecycle (F-3, too large for one iteration)
3. **Fix agent-identity cache** — include branch in cache key to prevent worktree collision (F-4)
4. **Add skill updates** alongside tool rewrites (F-2, F-9 — critical breaking changes)
5. **Migration edge cases** — scan code-reviews/, handle no-frontmatter, no-type, non-enum types (F-1, F-6)
6. **Flag default = self** per PVR/A&D (F-7)
7. **Test isolation mandate** — all ISCP test files override HOME (Testing F1)
8. **Note dispatch v1→v2 visibility gap** — old dispatches invisible until migration runs (Testing F7)

---

## Phase 1: Identity + Dispatch (critical path)

### Iteration 1.3: `agent-identity` tool [S]

New tool at `claude/tools/agent-identity`.

**Build:**
- Source `_address-parse`, `_path-resolve`, `_log-helper`
- Resolution: branch detection (main/master → captain, worktree branch → agent slug) + `address_resolve()`
- **Cache key includes branch:** `~/.agency/{repo}/.agent-identity-{branch-hash}` to prevent worktree agents impersonating each other (MAR F-4)
- Support `CLAUDE_AGENT_NAME` env var override for testing (existing dispatch-create pattern)
- Output: `repo/principal/agent` (default), `--agent` (bare name), `--principal` (bare principal), `--json` (all components)
- Provenance header, `set -euo pipefail`, `tool_output`

**Tests:** `tests/tools/agent-identity.bats` (~10 tests)
- Override HOME in setup (test isolation mandate)
- Mock git repo with configurable branch names
- Returns 3-segment address, captain on main, agent on named branch
- CLAUDE_AGENT_NAME override, cache with branch key, --agent/--json flags

### Iteration 1.4: `dispatch create` (DB + git payload) [M]

Merge dispatch-create INTO dispatch tool as the `create` subcommand. The standalone `dispatch-create` file becomes a thin wrapper that calls `dispatch create "$@"` (backward compat).

**Build (in `claude/tools/dispatch`):**
- Add `create` subcommand with dispatch-create's current logic
- Source `_iscp-db`, call `iscp_db_init`
- Add `--type <type>` flag (default: `dispatch`, validated against 8-type enum)
- Use `agent-identity` for `from_agent` (auto-computed, never self-asserted)
- After creating payload file, INSERT into dispatches table
- `--reply-to` accepts dispatch ID (integer) → sets `in_reply_to` FK
- Output: dispatch ID + file path
- `dispatch-create` becomes: `exec "$SCRIPT_DIR/dispatch" create "$@"` (1 line)

**Tests:** Rewrite `tests/tools/dispatch-create.bats` (~15 tests)
- Override HOME in setup
- Preserve: --help, --to required, --subject required, --priority validation
- Add: creates DB row, --type validates enum, DB status = unread, --reply-to links
- Both `dispatch create` and `dispatch-create` (wrapper) work

### Iteration 1.5: `dispatch` lifecycle (list, read, check, resolve) [M]

Complete the dispatch tool with DB-backed lifecycle subcommands.

**Build (continue in `claude/tools/dispatch`):**
- `list [--all] [--status <s>] [--type <t>]` — SELECT from DB, formatted table
- `read <id>` — show payload content (from main checkout via `git worktree list | head -1`), mark read in DB
- `check` — `iscp_db_count_unread`, silent when zero, `jq`-constructed `{"systemMessage": "..."}` when non-zero
- `resolve <id> [--response <id>]` — mark resolved, optionally link response
- `status <id>` — show full record for a dispatch

**Skill updates (same iteration — MAR F-2):**
- Update `.claude/skills/dispatch/SKILL.md` — integer IDs, new subcommands
- Update `.claude/skills/dispatch-read/SKILL.md` — ID-based interface
- Update `.claude/skills/session-resume/SKILL.md` — new check output format

**Tests:** New `tests/tools/dispatch.bats` (~15 tests)
- Override HOME, mock git repo
- list shows dispatches for current agent, --all shows all, --status filters
- read outputs payload, marks read, sets read_by
- check: silent when empty, JSON systemMessage when non-zero (validate with jq)
- resolve marks resolved
- Unknown ID returns error

### Iteration 1.6: Flag v2 [S]

Rewrite `claude/tools/flag` in place. JSONL → SQLite, agent-addressable.

**Build:**
- Source `_iscp-db`, `_address-parse`, `_log-helper`
- `flag <message>` — insert, **default to_agent = self** (per PVR/A&D — MAR F-7)
- `flag --to <agent> <message>` — route to specific agent
- `flag list` — SELECT from DB, mark as read (Slack-style seen)
- `flag count` — unread count
- `flag discuss` — format as numbered agenda, mark processed
- `flag clear` — mark all processed
- Drop jq dependency for flag itself (jq remains available system-wide)
- Drop git-add logic

**Skill update:** `.claude/skills/flag/SKILL.md`

**Tests:** `tests/tools/flag.bats` (~12 tests)
- Override HOME, mock git repo
- Insert/retrieve, --to routing, list marks read, count, discuss format, clear, empty

---

## Phase 2: Hook + Migration + Enforcement

### Iteration 2.1: `iscp-check` + hook wiring [S-M]

New tool at `claude/tools/iscp-check` + settings.json updates.

**iscp-check:**
- Source `_iscp-db`, use `agent-identity` (cache read, no fork on warm path)
- `iscp_db_count_unread "$agent"` → parse pipe-delimited
- Silent when empty (exit 0, no stdout) — handles no-DB, partial schema gracefully
- Non-zero: `jq -n --arg msg "..." '{"systemMessage":$msg}'` (proper JSON — MAR F-8)
- Performance target: <200ms (PVR NFR-3), aspire to <50ms

**Hook wiring in `.claude/settings.json`:**
- Add iscp-check to SessionStart, UserPromptSubmit, Stop hooks
- Add permissions: `Bash(./claude/tools/agent-identity*)`, `Bash(./claude/tools/iscp-check*)`, `Bash(./claude/tools/iscp-migrate*)`

**Tests:** `tests/tools/iscp-check.bats` (~10 tests)
- Override HOME
- Silent when empty, reports dispatches, reports flags, combined counts
- Valid JSON with systemMessage key (validate with jq)
- Graceful: no DB, partial schema, cold cache
- Integration: insert dispatch → iscp-check reports → dispatch read → iscp-check silent

### Iteration 2.2: Migration + hookify rules [M]

**iscp-migrate** (new tool at `claude/tools/iscp-migrate`):

Flag migration:
- Read `usr/jordan/flag-queue.jsonl`, parse with jq, insert into flags table
- Mark all as 'read' (pre-DB era), rename to `.migrated`

Dispatch migration (MAR F-1, F-6 fixes):
- Scan BOTH `usr/*/*/dispatches/*.md` AND `usr/*/*/code-reviews/*.md` (MAR F-1)
- Attempt YAML frontmatter parse first
- Fall back to markdown header parse (`**From:** ...`) for older dispatches (MAR F-6)
- Default `type` to `dispatch` for missing/invalid types (MAR F-6)
- Map old statuses: created→unread, read→read, in-progress→read, resolved→resolved
- Log warnings for unparseable addresses
- Idempotent via UNIQUE index on payload_path

**Hookify rules** (in `claude/hookify/`):
- `hookify.dispatch-manual.md` — blocks writing to `*/dispatches/` without dispatch tool
- `hookify.flag-manual.md` — blocks writing to flag-queue.jsonl or flag DB directly
- `hookify.directive-authority.md` — non-principal/captain → blocked for directive type
- `hookify.review-authority.md` — non-captain → blocked for review type
- `hookify.session-start-mail.md` — if ISCP reports unread on SessionStart, process FIRST

All rules end with: *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

**Tests:** `tests/tools/iscp-migrate.bats` (~10 tests)
- Migrates JSONL flags, migrates dispatches, idempotent
- Handles no-frontmatter (markdown headers), no-type, non-enum types
- Scans code-reviews/ directory

---

## Summary

| Iter | Deliverable | Size | Tests | Value |
|------|-------------|------|-------|-------|
| 1.3 | agent-identity | S | ~10 | Identity for all tools |
| 1.4 | dispatch create | M | ~15 | Dispatches can be created (DB + git) |
| 1.5 | dispatch lifecycle | M | ~15 | **Full dispatch lifecycle — core operational** |
| 1.6 | flag v2 | S | ~12 | Agent-addressable flags |
| 2.1 | iscp-check + hooks | S-M | ~10 | "You got mail" auto-notification |
| 2.2 | migration + hookify | M | ~10 | Legacy data + enforcement |

**Total: 6 iterations, ~72 new tests, 2 phases**

After 1.5: dispatches work end-to-end. After 2.1: agents auto-notified. After 2.2: ISCP v1 complete.

**Known gap:** Between 1.5 and 2.2, old dispatches (pre-DB) are invisible to v2 tools. Migration runs in 2.2. This is acceptable — we document it and run migration promptly.

## Dependency Graph

```
_iscp-db (DONE) ─────────┐
_address-parse (DONE) ────┤
                          ├─ 1.3 agent-identity
                          │       │
                          │       ├─ 1.4 dispatch create
                          │       │       │
                          │       │       └─ 1.5 dispatch lifecycle + skills
                          │       │
                          │       ├─ 1.6 flag v2 + skill
                          │       │
                          │       └─ 2.1 iscp-check + hooks
                          │
                          └─ 2.2 migration + hookify (after 1.5 + 1.6)
```

## Critical Files

| File | Action |
|------|--------|
| `claude/tools/agent-identity` | NEW |
| `claude/tools/dispatch` | REWRITE (add create subcommand + lifecycle) |
| `claude/tools/dispatch-create` | REPLACE with thin wrapper |
| `claude/tools/flag` | REWRITE |
| `claude/tools/iscp-check` | NEW |
| `claude/tools/iscp-migrate` | NEW (temporary) |
| `.claude/settings.json` | UPDATE (hooks + permissions) |
| `.claude/skills/dispatch/SKILL.md` | UPDATE |
| `.claude/skills/dispatch-read/SKILL.md` | UPDATE |
| `.claude/skills/session-resume/SKILL.md` | UPDATE |
| `.claude/skills/flag/SKILL.md` | UPDATE |
| `claude/hookify/hookify.dispatch-manual.md` | NEW |
| `claude/hookify/hookify.flag-manual.md` | NEW |
| `claude/hookify/hookify.directive-authority.md` | NEW |
| `claude/hookify/hookify.review-authority.md` | NEW |
| `claude/hookify/hookify.session-start-mail.md` | NEW |

## Verification

Per-iteration: `bats tests/tools/iscp-db.bats` (regression) + `bats tests/tools/{new}.bats`

End-to-end after 2.1:
1. Start session → iscp-check fires → silent
2. From another terminal: `dispatch create --to iscp --subject "test" --type directive`
3. Return → next prompt → "You have 1 unread dispatch"
4. `dispatch list` → shows dispatch with ID
5. `dispatch read 1` → payload content, marked read
6. `dispatch resolve 1` → marked resolved
7. `flag "observation"` → stored in DB
8. `flag list` → shows flag, marks read
9. iscp-check → "1 flag" (read but not processed)

## Dispatch Responses (pre-implementation)

### Response to captain (directive-dispatch-types-approved):
ACK — taxonomy already incorporated into PVR, A&D, schema, tests. No further action.

### Response to mdpal-cli (MAR findings):
1. **Types: Resolved.** review-request → `review` or `dispatch`, review-feedback → `review-response`, comment-update → subscription system or `dispatch` type
2. **Structured payloads: Open, committed to resolving before mdpal Phase 2.** Proposed: `data:` field in YAML frontmatter for machine-parseable fields
3. **DB polling: Confirmed.** `~/.agency/the-agency/iscp.db`, WAL mode, reads never block, read-only from app side
4. **Joint milestone: Accepted.** After iteration 1.5, mdpal can start Phase 2. ISCP will dispatch notification.
5. **Open items:** structured payload convention, comment-update pattern, app-side dispatch creation, DB path discovery
