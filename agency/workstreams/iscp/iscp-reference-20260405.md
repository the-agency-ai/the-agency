# ISCP v1 — Reference

**Workstream:** iscp
**Date:** 2026-04-05 (verified 2026-04-07 against main)
**Status:** Complete (Phases 1 + 2). v1 fully merged to main. Phase 2 (V2 work) in progress.
**Agent:** the-agency/jordan/iscp

## v1 Verification (2026-04-07)

ISCP v1 verified against main checkout for Phase 2 baseline:

- **Tests:** 174/174 BATS green on main, 182/182 on iscp worktree (8 additional Phase 2.0 migration framework tests)
- **Symlink dispatch payload resolution:** verified end-to-end. Symlinks in `~/.agency/the-agency/dispatches/` resolve to live git artifacts across all worktrees (main, iscp, devex, mdpal-cli). `dispatch read` follows symlinks transparently.
- **Structured commit dispatch metadata:** verified present in commit-type dispatches. Fields: `commit_hash`, `branch`, `files_changed`, `stage_hash`, `work_item`, agent identity.
- **Schema versioning framework:** Phase 2.0 done (commits `dfa9f2f` + `e24b2b4`). Migration runner `_iscp_run_migrations` plus `_iscp_migrate_v0_to_v1`. Ready for v1→v2 migration in Phase 2.3 (flag categories).

---

## What Is ISCP?

ISCP (Inter-Session Communication Protocol) is the notification and messaging backbone for The Agency framework. It solves three problems that blocked multi-agent coordination:

1. **No notification layer.** Agents had no signal that work was waiting — they'd start sessions saying "Ready." while dispatches sat unread.
2. **Git-coupled messaging broke in worktrees.** Dispatch payloads on master were invisible to worktree agents without `git merge master` — the #1 friction source in multi-agent sessions.
3. **Flags were principal-scoped, not agent-addressable.** One flat queue per principal, no routing to specific agents.

ISCP v1 delivers: agent-addressable flags, full dispatch lifecycle, automatic "You got mail" notifications, and legacy data migration — all backed by a shared SQLite database outside git.

---

## Architecture

Five primitives share one SQLite database and one addressing system:

| Primitive | Storage | Payload | Status |
|-----------|---------|---------|--------|
| **Flag** | DB only | Content in DB | ✅ v1 complete |
| **Dispatch** | DB notification + git payload | `usr/{principal}/{project}/dispatches/` | ✅ v1 complete |
| **Dropbox** | DB metadata + filesystem | `~/.agency/{repo}/dropbox/` | Deferred |
| **Transcript** | DB metadata + git payload | `usr/{principal}/{project}/transcripts/` | Deferred |
| **Subscription** | DB only (trigger rules) | N/A | Deferred |

### Database Location

```
~/.agency/{repo-name}/iscp.db
```

Outside git. WAL mode for concurrent access. All worktrees share the same DB. Created automatically on first tool invocation via `iscp_db_init`.

### Addressing

Every agent has a fully qualified address: `{repo}/{principal}/{agent}`

| Input | Resolution |
|-------|-----------|
| `captain` | Resolve repo from git, principal from agency.yaml |
| `jordan/captain` | Resolve repo from git |
| `the-agency/jordan/captain` | Fully qualified — no resolution needed |

**Tools always write fully qualified.** Tools accept short forms as input and resolve them. `agent-identity` resolves "who am I" — branch detection (main/master → captain, worktree → agent slug) + agency.yaml principal mapping. Cached per branch to prevent worktree collision.

---

## Tools

### `flag` — Quick-capture observations

```bash
flag <message>                   # flag to self
flag --to <agent> <message>      # flag to specific agent
flag list                        # show flags, mark as read
flag count                       # count unread flags
flag discuss                     # output as /discuss agenda, mark processed
flag clear                       # mark all as processed
```

**Three-state lifecycle:** unread → read (on `list`, Slack-style seen) → processed (on `discuss` or `clear`).

DB-only — no git payload, no git commit needed. Instant capture from any worktree.

### `dispatch` — Structured messaging with git payloads

```bash
dispatch create --to <addr> --subject <text> [--type <type>] [--priority <p>]
dispatch list [--all] [--status <s>] [--type <t>]
dispatch read <id>
dispatch check                   # silent when empty, JSON when items waiting
dispatch resolve <id>
dispatch status <id>
```

**Dispatch types** (8-type enum, validated on creation):

| Type | Direction | Purpose |
|------|-----------|---------|
| `directive` | Principal/Captain → Agent | "Do this work" |
| `seed` | Any → Workstream | Input material |
| `review` | Captain → Agent | Code review findings |
| `review-response` | Agent → Captain | "Findings addressed" |
| `commit` | Agent → Captain | "Work ready on my branch" |
| `master-updated` | Captain → Agent | "Master changed, merge" |
| `escalation` | Agent → Principal | Blocker/urgent |
| `dispatch` | Agent ↔ Agent | Generic coordination |

**Dispatch lifecycle:** unread → read (on `dispatch read`) → resolved (on `dispatch resolve`). Payloads are immutable markdown in git. Mutable state (read/resolved timestamps) lives in the DB only.

**Backward compatibility:** `dispatch-create` is a thin wrapper that calls `dispatch create "$@"`.

### `agent-identity` — "Who am I?"

```bash
agent-identity                   # outputs: repo/principal/agent
agent-identity --agent           # bare agent name
agent-identity --principal       # bare principal
agent-identity --repo            # bare repo
agent-identity --json            # all components as JSON
```

Resolution chain: `CLAUDE_AGENT_NAME` env var → git branch detection → `address_resolve()`. Cache at `~/.agency/{repo}/.agent-identity-{branch-hash}` — branch hash prevents worktree agents from reading each other's cache.

### `iscp-check` — "You got mail" hook

```bash
iscp-check                       # silent or JSON systemMessage
```

Single-pass query across flags, dispatches, dropbox, and notifications. **Silent when empty** (zero tokens, exit 0). JSON `{"systemMessage": "You have 2 dispatch(es), 1 flag(s). Run: dispatch list, flag list"}` when items are waiting.

**Every failure path exits silently** — a broken notification must never block agent work.

Wired into hooks: SessionStart, UserPromptSubmit, Stop.

### `iscp-migrate` — Legacy data migration

```bash
iscp-migrate                     # full migration (flags + dispatches)
iscp-migrate flags               # flags only
iscp-migrate dispatches          # dispatches only
```

**Flag migration:** Reads `usr/jordan/flag-queue.jsonl`, inserts into DB as `read` status (pre-DB era items already seen), renames file to `.migrated`.

**Dispatch migration:** Scans `usr/*/*/dispatches/*.md` AND `usr/*/*/code-reviews/*.md`. Parses YAML frontmatter first, falls back to markdown headers (`**From:**`, `**To:**`, etc.) for older dispatches. Maps unknown types to `dispatch`, maps statuses (created→unread, in-progress→read, resolved→resolved). Idempotent via UNIQUE index on `payload_path`.

---

## Shared Library: `_iscp-db`

All ISCP tools source `claude/tools/lib/_iscp-db`. It provides:

| Function | Purpose |
|----------|---------|
| `iscp_db_init` | Create DB, set pragmas, create schema (idempotent) |
| `iscp_db_path` | Resolve absolute path to the DB file |
| `iscp_db_query` | Read query with named parameters |
| `iscp_db_exec` | Write statement with named parameters |
| `iscp_db_insert_flag` | Convenience: insert a flag |
| `iscp_db_update_status` | Convenience: update status with timestamp |
| `iscp_db_count_unread` | Single-pass count: `flags|dispatches|dropbox|notifications` |
| `iscp_db_check_sqlite` | Verify sqlite3 ≥ 3.38.0 |

**Named parameters** via `.param set :name "value"` — never interpolate variables into SQL. The library handles escaping (backslash, double-quote, newline, CR, tab) and validates parameter names against `^:[a-zA-Z_][a-zA-Z0-9_]*$`.

**SQLite pragmas:** WAL mode (concurrent readers), busy_timeout=1000ms, foreign_keys=ON, synchronous=NORMAL.

---

## Hook Wiring

In `.claude/settings.json`:

```
SessionStart:     session-start.sh → branch-freshness.sh → session-handoff.sh → iscp-check → ghostty-status.sh
UserPromptSubmit: iscp-check
Stop:             stop-check.py → quality-check.sh → iscp-check → ghostty-status.sh
```

### Permissions (pre-approved)

```
Bash(./claude/tools/agent-identity*)
Bash(./claude/tools/iscp-check*)
Bash(./claude/tools/iscp-migrate*)
Bash(./claude/tools/flag *)
Bash(./claude/tools/flag)
Bash(./claude/tools/dispatch *)
Bash(./claude/tools/dispatch-create*)
```

---

## Hookify Rules (Enforcement)

| Rule | Action | What it enforces |
|------|--------|-----------------|
| `hookify.dispatch-manual.md` | warn | Use `dispatch create`, not manual writes to `dispatches/` |
| `hookify.flag-manual.md` | warn | Use `flag`, not manual writes to JSONL or DB |
| `hookify.directive-authority.md` | warn | Only principal/captain may send `--type directive` |
| `hookify.review-authority.md` | warn | Only captain may send `--type review` |
| `hookify.session-start-mail.md` | inform | Process unread mail FIRST on session start |

---

## Database Schema (v1)

### `flags`

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Auto-increment |
| created_at | TEXT | ISO 8601 |
| from_agent | TEXT | Fully qualified |
| to_agent | TEXT | Fully qualified |
| message | TEXT | Flag content |
| status | TEXT | `unread` / `read` / `processed` |
| read_at | TEXT | Nullable |
| processed_at | TEXT | Nullable |
| session_id | TEXT | Session that created it |
| branch | TEXT | Git branch at creation |

### `dispatches`

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Auto-increment |
| created_at | TEXT | ISO 8601 |
| from_agent | TEXT | Fully qualified |
| to_agent | TEXT | Fully qualified |
| type | TEXT | 8-type enum (CHECK constraint) |
| priority | TEXT | `low` / `normal` / `high` |
| subject | TEXT | Subject line |
| payload_path | TEXT | Relative path to git payload (UNIQUE) |
| in_reply_to | INTEGER | FK to dispatches.id (nullable) |
| status | TEXT | `unread` / `read` / `resolved` |
| read_at | TEXT | Nullable |
| read_by | TEXT | Agent that read it |
| resolved_at | TEXT | Nullable |

### Additional tables (schema present, tools deferred)

- **`transcripts`** — session dialogue metadata
- **`dropbox_items`** — universal intake items
- **`subscriptions`** — event notification rules
- **`notifications`** — triggered subscription events

### Indexes

```sql
idx_flags_to_status        ON flags(to_agent, status)
idx_dispatches_to_status   ON dispatches(to_agent, status)
idx_dispatches_type        ON dispatches(type)
idx_dispatches_reply       ON dispatches(in_reply_to)
idx_dispatches_payload     ON dispatches(payload_path)          -- UNIQUE
idx_dropbox_to_status      ON dropbox_items(to_agent, status)
idx_transcripts_agent      ON transcripts(agent)
idx_subscriptions_subscriber ON subscriptions(subscriber, status)
idx_subscriptions_unique   ON subscriptions(subscriber, event_pattern, filter) -- UNIQUE
idx_notifications_to_status ON notifications(to_agent, status)
```

---

## Test Coverage

**142 BATS tests across 7 test files:**

| File | Tests | What |
|------|-------|------|
| `tests/tools/iscp-db.bats` | 51 | Shared library: init, query, exec, params, schema, edge cases |
| `tests/tools/agent-identity.bats` | 15 | Identity resolution, caching, branch detection, output modes |
| `tests/tools/dispatch-create.bats` | 17 | Create subcommand + backward-compat wrapper |
| `tests/tools/dispatch.bats` | 18 | Lifecycle: list, read, check, resolve, status |
| `tests/tools/flag.bats` | 14 | Capture, routing, list/count/discuss/clear |
| `tests/tools/iscp-check.bats` | 13 | Silent when empty, reports items, JSON output, integration |
| `tests/tools/iscp-migrate.bats` | 14 | Flag import, dispatch import, type/status mapping, idempotency |

All tests use HOME override for isolation — no test touches the real `~/.agency/` directory.

---

## Key Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | SQLite outside git | No daemon, concurrent-safe with WAL, ubiquitous, doesn't pollute git history |
| 2 | Single DB for all primitives | One-pass notification query across flags, dispatches, dropbox, subscriptions |
| 3 | Flags are DB-only | High frequency, low ceremony — git commit per flag defeats the purpose |
| 4 | Named parameters via `.param set` | SQL injection safety — never interpolate user input into SQL |
| 5 | Agent identity from branch, not env | `AGENCY_PRINCIPAL` env var leaked from test suites — branch detection is reliable |
| 6 | Branch-scoped identity cache | Prevents worktree agents from impersonating each other |
| 7 | iscp-check fails silently | Broken notification must never block agent work |
| 8 | 8-type dispatch taxonomy | Each type encodes direction and purpose — no ambiguous generics |
| 9 | Dispatch payloads immutable in git | Mutable state in DB only — audit trail preserved |
| 10 | `dispatch-create` thin wrapper | Backward compatibility for existing callers |

---

## Known Limitations (v1)

1. **Skill updates not yet done** — dispatch, flag, session-resume skills still reference v1 interface
2. **No structured payload convention** — mdpal-cli needs machine-parseable dispatch data (proposed: `data:` field in YAML frontmatter)
3. **Deferred primitives** — dropbox, transcripts, subscriptions have schema but no tools yet
4. **Cross-repo dispatches** — filesystem-only in v1, no network transport
5. **No performance benchmarks** — 200ms target stated but not formally measured
6. **Migration is one-shot** — no lazy "on first read" migration path

---

## Files

| File | Purpose |
|------|---------|
| `claude/tools/lib/_iscp-db` | Shared SQLite library |
| `claude/tools/agent-identity` | Identity resolution |
| `claude/tools/dispatch` | Dispatch lifecycle (create/list/read/check/resolve/status) |
| `claude/tools/dispatch-create` | Backward-compat wrapper → `dispatch create` |
| `claude/tools/flag` | Flag capture and processing |
| `claude/tools/iscp-check` | Notification hook |
| `claude/tools/iscp-migrate` | Legacy data migration |
| `claude/tools/lib/_address-parse` | Address resolution library |
| `claude/tools/lib/_path-resolve` | Project root / agency.yaml resolution |
| `claude/tools/lib/_log-helper` | Tool telemetry |
| `.claude/settings.json` | Hook wiring + permissions |
| `claude/hookify/hookify.dispatch-manual.md` | Enforcement: use dispatch tool |
| `claude/hookify/hookify.flag-manual.md` | Enforcement: use flag tool |
| `claude/hookify/hookify.directive-authority.md` | Enforcement: directive authority |
| `claude/hookify/hookify.review-authority.md` | Enforcement: review authority |
| `claude/hookify/hookify.session-start-mail.md` | Enforcement: process mail first |
| `claude/workstreams/iscp/iscp-pvr-20260404.md` | Product Vision & Requirements |
| `claude/workstreams/iscp/iscp-ad-20260404.md` | Architecture & Design |
| `claude/workstreams/iscp/iscp-plan-20260404.md` | The Plan |
| `claude/workstreams/iscp/iscp-reference-20260405.md` | This reference |

---

## End-to-End Flow

```
1. Agent starts session
   → SessionStart hook fires iscp-check
   → iscp-check queries DB: "any unread items for me?"
   → Silent (nothing) or JSON systemMessage ("You have 2 dispatch(es)")

2. Agent processes mail (if any)
   → dispatch list → sees dispatches with IDs
   → dispatch read 1 → reads payload, marks read
   → does the work
   → dispatch resolve 1

3. Agent captures observations
   → flag "noticed a bug in X"
   → flag --to captain "need review on Y"

4. Agent submits each prompt
   → UserPromptSubmit hook fires iscp-check
   → catches dispatches that arrived mid-session

5. Agent stops
   → Stop hook fires iscp-check
   → catches dispatches that arrived during response generation
```

---

## Iteration History

| Iteration | Deliverable | Tests | Commit |
|-----------|-------------|-------|--------|
| 1.1 | PVR + A&D | — | (design) |
| 1.2 | `_iscp-db` library | 51 | `9956644` |
| 1.3 | `agent-identity` | 15 | `86a4f9d` |
| 1.4 | `dispatch create` | 17 | `7721754` |
| 1.5 | `dispatch` lifecycle | 18 | `d50dbff` |
| 1.6 | `flag` v2 | 14 | `3b187e5` |
| 2.1 | `iscp-check` + hooks | 13 | `4d2fb88` |
| 2.2 | `iscp-migrate` + hookify | 14 | `b711ada` |

**Total: 8 iterations, 142 tests, 2 phases.**

---

*ISCP v1 is operational. Agents have mail.*
