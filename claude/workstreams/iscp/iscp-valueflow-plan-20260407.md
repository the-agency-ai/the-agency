---
type: plan
project: iscp-v2
workstream: iscp
date: 2026-04-07
status: draft — MAR reviewed (2 subagents, 19 findings, 15 autonomous, 2 disagree), revised
author: the-agency/jordan/iscp
master-plan: claude/workstreams/agency/valueflow-plan-20260407.md
pvr: claude/workstreams/agency/valueflow-pvr-20260406.md
ad: claude/workstreams/agency/valueflow-ad-20260406.md
mar-review: dispatch #100 (MAR response with 14 findings)
plan-mar: 2 subagents (feasibility+scope, risk+dependency), 19 findings, 15 autonomous incorporated
---

# ISCP V2 — Workstream Implementation Plan

## Overview

This plan implements **Phase 2 of the Valueflow V2 master plan**: dispatch authority enforcement, flag categories, dispatch-on-commit, health metrics, and the DB schema versioning that underpins all of them.

**Scope:** Five iterations (2.0–2.5) delivering the ISCP messaging layer enhancements defined in A&D §§4, 8, 10 and assigned to the iscp workstream in the master plan.

**Starting state:** ISCP v1 complete on main. 174 BATS tests green. All dispatch/flag/identity tools operational. The iscp branch has zero unique commits — main is ahead. Symlink dispatch payloads (1e610fd) and structured commit dispatches (41fb5cf) already on main.

**Worktree:** Fresh worktree from current main recommended (existing iscp worktree has stale state). Branch: `iscp-v2`.

---

## Adjustments from Master Plan

Based on MAR review findings (dispatch #100):

| Master plan | Adjustment | Rationale |
|-------------|------------|-----------|
| 2.1: Symlink merge | Reduced to verification step | Symlink commit (1e610fd) already on main. Zero divergence. MAR finding #1. |
| 2.4: Dispatch-on-commit | Scoped to remaining work only | Structured YAML metadata implemented (41fb5cf). Remaining: git-commit tool wiring + phase/iteration fields. MAR finding #2. |
| 2.5: DB schema versioning as part of metrics | Promoted to 2.0 (prerequisite) | Schema versioning is needed by 2.3 (flag category column) and 2.5 (any future columns). Must come first. MAR finding #6. |
| 2.2: review-response authority | Corrected rule | Reviewers send responses (not authors). Check sender was in to_address of original review dispatch. MAR finding #4. |
| 2.5: lead_time_hours | Defined as two metrics | lead_time = created→resolved. response_time = created→read. MAR finding #7. |
| 2.3→2.5 dependency | Made explicit | Flag rate metrics require flag categories to exist first. MAR finding #12. |

---

## Iteration Plan

### Iteration 2.0: DB Schema Versioning

**What:** Migration framework for ISCP DB schema changes. Prerequisite for everything else in Phase 2.

**Why:** Adding a `category` column to flags (2.3) or any future columns requires a versioning mechanism. Without it, agents with different tool versions will corrupt each other's DB or fail silently. Every multi-agent system hits this — solve it once, first.

**Delivers:**
- `schema_version` table in iscp.db: `version INTEGER, migrated_at TEXT, description TEXT`
- Version check on every `iscp_db_init` call — compare DB version to tool's expected version
- Migration runner: ordered migration functions in `_iscp-db` library, each bumps version
- Current schema = version 1 (retroactive — existing DBs get version 1 on first check)
- Fail-loud on version mismatch: "DB is version N, tool expects version M. Run iscp-migrate."
- `iscp-migrate` gains `--schema` subcommand for version migrations

**Acceptance criteria:**
- Fresh DB creates with version 1
- Existing DB without version table: auto-creates version table, sets version 1
- Tool detects version mismatch and fails with actionable error
- Migration from version 1→2 works end-to-end with a real column add (preview: add `category` column to flags, same migration 2.3 will use — proves the framework with a real ALTER TABLE, not a no-op)
- `iscp-migrate --schema` reports current version and available migrations
- Migration runs inside an exclusive transaction (serializes concurrent agent access)

**Test cases (BATS):**
- `iscp-db-version.bats`: fresh DB has version table, version = 1
- Existing DB gets version table on init
- Version mismatch detected and error message is actionable
- Migration runs in order, each bumps version
- Concurrent access during migration serialized via exclusive transaction
- Real column-add migration succeeds on DB with existing data

**Estimated effort:** Small. Low risk — additive to existing `_iscp-db` library.

---

### Iteration 2.1: Verification + Baseline

**What:** Verify ISCP v1 state on current main BEFORE any Phase 2 changes. Establish clean test baseline.

**Why:** Master plan expected this might be a merge task. It's not — iscp is fully merged (MAR finding #1). But verification is still needed: confirm tests pass from main, confirm symlink resolution works, confirm dispatch-on-commit metadata is correct. Run this on main before branching to iscp-v2, so any failure is unambiguously pre-existing.

**Delivers:**
- Run full BATS suite from main: `bats tests/tools/iscp-db.bats tests/tools/agent-identity.bats tests/tools/dispatch-create.bats tests/tools/dispatch.bats tests/tools/flag.bats tests/tools/iscp-check.bats tests/tools/iscp-migrate.bats`
- Verify symlink dispatch payload resolution: create a dispatch, confirm symlink in `~/.agency/the-agency/dispatches/`, confirm `dispatch read` follows it
- Verify structured commit dispatch metadata fields: `commit_hash`, `branch`, `files_changed`, `stage_hash`
- Document baseline test count and any findings
- Update `iscp-reference-20260405.md` with v1 final state

**Acceptance criteria:**
- All existing tests pass (174+)
- Symlink resolution confirmed working from main checkout
- Commit dispatch metadata fields verified present and correct
- Reference doc updated

**Estimated effort:** Small. Verification only, no code changes expected.

---

### Iteration 2.2: Dispatch Authority Enforcement

**What:** Gate `dispatch create` by agent role — certain dispatch types restricted to certain agents.

**Why:** A&D §4 specifies dispatch authority. Without enforcement, any agent can send directives or reviews, breaking the coordination model. Enforce at the tool level (enforcement ladder level 3).

**Design question (from MAR finding #3):** How does the dispatch tool resolve "role" from agent name? Resolution: **hardcode the captain role check in the dispatch tool.** Captain is the only privileged role in V2. The check is: `if agent_name == "captain"` for captain-only types. Simple, auditable, no agency.yaml lookup needed. If more roles emerge in V3, factor into a registry then.

**Delivers:**
- `dispatch create` checks agent name (via `agent-identity --agent`) against type's allowed creators
- Authority rules (from A&D §4, with corrected review-response rule):

| Dispatch type | Allowed creators | Enforcement |
|---------------|-----------------|-------------|
| `directive` | captain only | `agent == "captain"` |
| `review` | captain only | `agent == "captain"` |
| `master-updated` | captain only | `agent == "captain"` |
| `seed` | any agent | No check |
| `escalation` | any agent | No check |
| `dispatch` | any agent | No check |
| `review-response` | recipient of the original review | `--reply-to` required; query DB for referenced dispatch's `to_agent`, compare to current sender |
| `commit` | git-commit tool only | env var `ISCP_COMMIT_DISPATCH=1` (set by git-commit, not by agents directly) |

- `review-response` implementation: dispatch tool queries `SELECT from_agent, to_agent FROM dispatches WHERE id = <reply_to_id>`. Validates: (a) current sender is in `to_agent` of referenced dispatch (you received the review), AND (b) `--to` of the response is the `from_agent` of the referenced dispatch (response goes back to the reviewer's source). This second check catches misrouted responses (e.g., dispatch #105 case where mdpal-cli sent response to iscp instead of captain). If referenced dispatch doesn't exist in local DB → fail with "referenced dispatch not found" (cross-repo dispatch edge case: not supported in V2, fail loud)
- Unauthorized create fails with actionable error: "Only captain can create [type] dispatches. You are [agent]."
- No `--force` bypass — enforcement is the point. Principal can override via direct SQL if truly needed (auditable, intentionally inconvenient)

**Acceptance criteria:**
- Non-captain agent creating `directive` → fails with actionable error
- Captain creating `directive` → succeeds
- Agent sending `review-response` to a review they received, addressed to the original reviewer → succeeds
- Agent sending `review-response` to a review addressed to someone else → fails
- Agent sending `review-response` with wrong `--to` (not the original reviewer) → fails (catches dispatch #105 misrouting case)
- `review-response` with `--reply-to` referencing non-existent dispatch → fails with actionable error
- All existing dispatch tests still pass (no regression)

**Test cases (BATS):**
- `dispatch-authority.bats`: one test per rule in the table above
- Non-existent reply-to reference test
- Regression: existing dispatch create tests unchanged

**Estimated effort:** 1 session. Moderate — touches dispatch create validation path.

---

### Iteration 2.3: Flag Categories

**What:** Categorized flag capture: `--friction`, `--idea`, `--bug`.

**Why:** A&D §10 specifies categories at capture time. Categories route flags to different pipelines (improvement, new work, immediate fix). Without categories, all flags are an undifferentiated pile — triage must re-discover what the flagger already knew at capture time.

**Delivers:**
- DB migration (version 1→2): add `category` column to flags table
  - `category TEXT CHECK(category IN ('friction', 'idea', 'bug', NULL))` — nullable for backward compatibility
- `flag --friction "description"`, `flag --idea "description"`, `flag --bug "description"`
- `flag list --category friction` — filter by category
- `flag list` (no filter) — shows all flags, category displayed in output
- Uncategorized flags (existing + new without category flag) work unchanged
- `flag discuss` shows category in discussion context

**Acceptance criteria:**
- `flag --friction "test"` creates flag with category "friction" in DB
- `flag list --category friction` shows only friction flags
- `flag list` shows all flags with category column
- Existing uncategorized flags display with blank/null category
- DB migration from version 1→2 succeeds on existing DB with data (2.0 already ran the real migration — 2.3 just uses it)
- Mixed data display: `flag list` with both categorized and uncategorized flags shows both correctly
- All existing flag tests pass without modification

**Dependencies:** Iteration 2.0 (DB schema versioning — migration framework + category column already added)

**Test cases (BATS):**
- `flag-categories.bats`: create with each category, list with filter, list without filter
- Mixed data: DB with uncategorized flags + new categorized flags → list shows both
- Backward compat: `flag "message"` (no category) still works

**Estimated effort:** Small — DB migration already done in 2.0, this is CLI flags + filtering + display.

---

### Iteration 2.4: Dispatch-on-Commit Wiring

**What:** Wire the existing structured commit dispatch into the git-commit tool so every commit auto-notifies captain.

**Why:** A&D §5 specifies dispatch-on-commit as the coordination path. The structured YAML metadata is already implemented (41fb5cf). What's missing: the git-commit tool doesn't call it automatically, and the phase/iteration fields aren't populated.

**Delivers:**
- `git-commit` tool calls `dispatch create --type commit` after successful commit
- Commit dispatch carries: `commit_hash`, `stage_hash`, `branch`, `phase`, `iteration`, `files_changed`, `work_item`
- `phase` and `iteration` extracted from commit message slug (e.g., "Phase 1.3: feat: ..." → phase=1, iteration=3). Non-matching formats (merge commits, "housekeeping/captain: ...") → null fields, no error
- Env var `ISCP_COMMIT_DISPATCH=1` set during the dispatch create call — serves dual purpose: (a) gates the dispatch (opt-out: unset to disable), (b) authorizes commit-type dispatch creation (from 2.2)
- Suppress in test environments (`ISCP_DB_PATH` override present → skip dispatch)

**Acceptance criteria:**
- Commit via git-commit tool → commit dispatch appears in captain's dispatch list
- Dispatch metadata includes all structured fields
- Phase/iteration parsed correctly from commit message
- Non-matching commit message format → phase/iteration are null, dispatch still created
- No dispatch in test environments
- `/iteration-complete` → commit → dispatch (end-to-end)

**Dependencies:** 
- **Co-ship with 2.2** (dispatch authority). Land together — if 2.2's commit authority check is live but git-commit isn't setting `ISCP_COMMIT_DISPATCH=1` yet, all manual commit dispatches break. No partial deployment.
- Changes to `claude/tools/git-commit` (shared tool — coordinate with captain for merge)

**Test cases (BATS):**
- `dispatch-on-commit.bats`: mock git-commit, verify dispatch created with correct metadata
- Phase/iteration parsing: matching format, non-matching format, merge commit
- Suppression in test environment
- Env var unset → no dispatch

**Estimated effort:** Small-moderate — touches git-commit tool (shared, needs careful testing).

---

### Iteration 2.5: Health Metrics Data Layer

**What:** `iscp-metrics` query tool that computes lead time and flag rate metrics from ISCP DB.

**Why:** A&D §10 + PVR SC7/SC8. The data is already in the DB (timestamps on dispatches and flags). This iteration surfaces it as queryable metrics. Captain's Phase 6.4 builds the presentation layer on top.

**Delivers:**
- New tool: `claude/tools/iscp-metrics`
- Dispatch metrics:
  - Per-dispatch: `dispatch_id`, `created_at`, `read_at`, `resolved_at`, `lead_time_hours` (created→resolved), `response_time_hours` (created→read)
  - Aggregate: mean/median/p90 lead time, mean response time, dispatch volume by type
  - Filterable by: `--period 7d`, `--type review`, `--agent captain`
  - Note: `response_time` is dispatch-only (dispatches have `read_at`). Flags have `processed_at`, not `read_at` — different lifecycle.
- Flag metrics:
  - Per-category: `category`, `count`, `rate_per_day`
  - Accumulation trend: flags created vs processed per period
  - Filterable by: `--period 7d`, `--category friction`
  - Flags with null category included in totals, excluded from per-category breakdowns
- Output formats:
  - Default: markdown table (human-readable)
  - `--yaml`: structured YAML (machine-parseable, for captain's summary tool)
- No DB schema changes needed — all metrics computed from existing timestamp columns

**Acceptance criteria:**
- `iscp-metrics dispatches --period 7d` shows dispatch lead time table
- `iscp-metrics flags --category friction` shows friction flag rate
- `iscp-metrics dispatches --yaml` produces parseable YAML
- Given N dispatches with known timestamps: lead_time = created→resolved, response_time = created→read (both correct)
- Given flags with categories: rate_per_day computed correctly
- Empty DB / no matching data → empty table with headers, not error

**Dependencies:** Iteration 2.3 (flag categories — flag rate by category requires the category column)

**Test cases (BATS):**
- `iscp-metrics.bats`: insert known data, verify computations
- Lead time calculation with various timestamp patterns
- Flag rate with categories
- Period filtering (7d, 30d)
- YAML output format validation
- Empty data → empty table with headers

**Estimated effort:** Moderate — new tool, but queries are straightforward SQL aggregation.

---

### Iteration 2.6: Per-Agent Inboxes + Direction-Aware Dispatch List

**What:** Each agent has its own `inbox/` and `outbox/` directory. Dispatches land in the recipient's inbox (not the sender's directory). `dispatch list` defaults to inbox-only with TO/FROM display.

**Why:** Today's shared structure (`usr/{principal}/{from-agent}/dispatches/` for both inbound and outbound) caused dispatch #105 misrouting and the wasted-tool-calls friction captain documented. Per-agent inboxes give clean direction semantics, enable trivial direction filtering, and match the universal email metaphor agents already understand.

**Approved by captain in dispatch #128.**

**Delivers:**
- New directory structure: `usr/{principal}/{agent}/inbox/` and `usr/{principal}/{agent}/outbox/`
- DB migration (uses 2.0 framework): add `sender_path` column to dispatches table
- `dispatch create` writes payload to BOTH locations:
  - Recipient's inbox: canonical `payload_path`
  - Sender's outbox: `sender_path`
  - Self-dispatch (sender == recipient): single file in inbox, `sender_path = payload_path`
- Symlink in `~/.agency/{repo}/dispatches/` points to recipient's inbox (V1 design preserved)
- `dispatch list` defaults: inbox only (`WHERE to_agent = current_agent`)
- New flags: `--all` (current behavior, both directions), `--outbox` (outbound only)
- New output format with DIR column (`<` inbound, `>` outbound, `=` self), FROM, TO columns
- Default view (inbox only) hides DIR column since all entries are inbound
- Existing dispatches stay in place — no migration tool, hard cutover for new dispatches only

**Acceptance criteria:**
- New dispatch creates both inbox and outbox files at the right paths
- Self-dispatch creates one file in inbox with `sender_path = payload_path`
- `dispatch list` (no flags) shows only inbound dispatches
- `dispatch list --all` shows both directions with DIR column
- `dispatch list --outbox` shows only outbound
- Output uses bare agent names in FROM/TO columns
- Existing dispatches (pre-2.6) remain readable via `dispatch read <id>`
- Symlink resolution still works (V1 symlink design preserved, target path updated)
- All existing dispatch tests pass without modification (backward compat)

**Dependencies:**
- Iteration 2.0 (DB schema versioning — adds `sender_path` column via migration)
- Iteration 2.2 (dispatch authority — review-response check uses recipient validation that this iteration enables cleanly)

**Test cases (BATS):**
- `dispatch-inbox.bats`: create dispatch, verify both files exist at correct paths
- Self-dispatch: single file in inbox
- `dispatch list` default = inbox filter
- `dispatch list --all` = both directions, DIR column populated
- `dispatch list --outbox` = outbound only
- Mixed legacy/new: existing pre-2.6 dispatches still readable
- Symlink target points to inbox copy

**Estimated effort:** ~3–4 hours, half a day. Migration framework from 2.0 makes the schema change trivial; the storage logic is two writes instead of one.

---

## Sequencing

**Sequence:** 2.1 → 2.0 → 2.3 → 2.2+2.4 (co-ship) → 2.5 → 2.6

- **2.1 first** — verify baseline on main before any changes. Run on main before branching. ✅ DONE (174/174)
- **2.0 second** — schema versioning + real category column migration. Unblocks 2.3 and 2.6.
- **2.3 next** — flag categories. Exercises the migration, gives early value (triage 26 flags with categories).
- **2.2+2.4 co-ship** — dispatch authority + dispatch-on-commit land together (partial deployment breaks commit-type dispatches).
- **2.5 next** — health metrics. Depends on 2.3 for flag category rates.
- **2.6 last** — per-agent inboxes + direction-aware dispatch list. Approved by captain (#128).

**Phase 1 M2 reconciliation:** Before landing 2.2 to master, validate against ISCP-PROTOCOL.md if published. If M2 hasn't shipped yet, proceed with current reference doc and reconcile when M2 arrives.

---

## Timeline Estimate

| Iteration | Effort | Calendar |
|-----------|--------|----------|
| 2.1 (verify) ✅ | 30 min | Done |
| 2.0 (schema versioning) | 1–2 hours | Day 1 |
| 2.3 (flag categories) | 1–2 hours | Day 1–2 |
| 2.2+2.4 (authority + commit wiring) | 2–3 hours | Day 2 |
| 2.5 (health metrics) | 2–3 hours | Day 3 |
| 2.6 (per-agent inboxes) | 3–4 hours | Day 3–4 |
| **Total** | **~12–14 hours** | **~3.5 working days** |

These are well-scoped extensions on code I own. 174 existing tests provide confidence for fast iteration.

---

## Open Items Deferred from Phase 2

These were raised in MAR review but are intentionally not in Phase 2:

| Item | Status | Rationale |
|------|--------|-----------|
| SMS-style dispatches | Deferred | Principal requested (flag #1). Short DB-only dispatches without git payload. Valuable but not in master plan scope. Propose as Phase 2.6 or V2.1. |
| BUG 2: `dispatch list --all` | Deferred | Shows other agents' unread mail. Known bug, minor impact. Fix as cleanup. |
| Dispatch retention | Deferred | Archive resolved dispatches after 30 days. Not blocking. |
| Existing flag migration | Not needed | Existing uncategorized flags work with null category (backward compat). No migration tool needed. MAR finding #5 resolved. |

---

## Success Criteria (from Master Plan)

Phase 2 contributes to these V2 success criteria:

- **SC3** (every artifact has a gate): Dispatch authority enforcement ensures only authorized agents create certain dispatch types
- **SC5** (captain loop with batch processing): Dispatch-on-commit provides the input stream for captain's batch processing (Phase 6.2)
- **SC7** (lead time measurable): Health metrics data layer delivers the measurement
- **SC8** (principal intervention frequency): Health metrics data layer delivers the measurement

---

## Next Action

1. Await formal seed dispatch from captain (or principal approval to start proactively)
2. Create fresh worktree from main: `iscp-v2` branch
3. Begin Iteration 2.0: DB schema versioning
