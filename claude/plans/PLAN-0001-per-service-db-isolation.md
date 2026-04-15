# Plan: Per-Service Database Isolation

**Plan ID:** PLAN-0001
**Date:** 2026-03-03
**Agent:** captain
**Principal:** jordan
**Status:** Implemented
**Related:** N/A

## Prompt Context

> Implement the following plan:
>
> # Plan: Per-Service Database Isolation
>
> All 10 embedded services in `agency-service` currently share a single `agency.db` file. This creates unnecessary coupling — schema migrations in one service risk others, SQLite file-level locking creates write contention, and extracting a service later requires untangling shared state. The queue adapter already uses a separate `queue.db`, proving the pattern works. This refactor generalizes that to all services while keeping Postgres migration viable.
>
> Key design constraint: The `DatabaseAdapter` interface is unchanged. No repository or service files are modified. The refactor is entirely in the factory layer and wiring layer.

## Plan

### Steps

1. **Extend database factory with `serviceName`** — Add optional `serviceName` to `createDatabaseAdapter()` that resolves to `{serviceName}.db`. Add per-service env var override `AGENCY_DB_PATH_{SERVICE}`. Add `DatabaseRegistry` with `initializeAll()`, `closeAll()`, `healthCheckAll()`. Remove singleton `getDatabase`/`closeDatabase`.

2. **Re-wire `index.ts`** — Replace shared `db` with per-service adapters via registry. Update `/health` to report per-service DB status. Update shutdown to `registry.closeAll()`.

3. **Migration script** — Create `migrate-to-per-service-db.ts` that opens `agency.db` read-only, creates target adapters (with schema initialization), copies rows with `INSERT OR IGNORE`.

4. **Documentation** — Update `DISPATCH-AND-MESSAGING.md` architecture section.

### File Layout Result

```
claude/data/
  messages.db       # messages-service
  dispatch.db       # dispatch-service
  request.db        # request-service
  log.db            # log-service (+ FTS)
  bug.db            # bug-service
  secret.db         # secret-service
  test.db           # test-service
  idea.db           # idea-service
  observation.db    # observation-service
  product.db        # product-service
  queue.db          # queue adapter (unchanged)
  agency.db         # preserved backup
```

### Service-to-Table Mapping

| Service | DB File | Tables |
|---------|---------|--------|
| messages | `messages.db` | `messages` |
| dispatch | `dispatch.db` | `dispatch_items`, `dispatch_instances` |
| request | `request.db` | `requests`, `request_sequences` |
| log | `log.db` | `log_entries`, `log_entries_fts`, `tool_runs` |
| bug | `bug.db` | `bugs`, `bug_sequences`, `bug_attachments` |
| secret | `secret.db` | `secrets`, `secret_tags`, `secret_grants`, `secret_access_log`, `vault_config`, `vault_recovery` |
| test | `test.db` | `test_runs`, `test_results` |
| idea | `idea.db` | `ideas`, `idea_sequence` |
| observation | `observation.db` | `observations`, `observation_sequence` |
| product | `product.db` | `products`, `product_contributors`, `product_sequences` |

### Files Modified

- `source/services/agency-service/src/core/adapters/database/index.ts` — serviceName support, DatabaseRegistry, removed singleton
- `source/services/agency-service/src/index.ts` — registry wiring, per-service adapters, health + shutdown
- `claude/REFERENCE-DISPATCH-AND-MESSAGING.md` — per-service DB architecture table

### Files Created

- `source/services/agency-service/src/scripts/migrate-to-per-service-db.ts` — one-time data migration

### Files NOT Changed

All 10 service directories (repositories, services, routes, types) — zero changes. The `DatabaseAdapter` interface is unchanged.

## Outcome

### Commits

- `328a9e0` — per-service database isolation (factory, wiring, migration script, docs)
- `60dc1e3` — plan artifact convention + TaskCompleted hook
- `381424e` — REQUEST linkage for plan artifacts

### Migration Results

Migration script ran against 75MB `agency.db`:
- **28,909 total rows** migrated across all services
- Key counts: 11,024 log entries, 17,700 tool runs, 71 requests, 78 secret access log entries
- Empty tables skipped (messages, test_runs, test_results, products, etc.)
- `agency.db` preserved as backup

### Verification Results (all 8 checks passed)

| # | Check | Result |
|---|-------|--------|
| 1 | `bun build src/index.ts` compiles | Bundled 212 modules in 50ms |
| 2 | `curl localhost:3141/health` | All 10 databases: `true` |
| 3 | `./tools/msg send research "test"` lands in `messages.db` | Confirmed: `SELECT subject FROM messages` returns test row |
| 4 | `./tools/dispatch enqueue` lands in `dispatch.db` | Confirmed: `SELECT title FROM dispatch_items` returns test row |
| 5 | `./tools/requests` reads from `request.db` | 71 requests listed correctly |
| 6 | Migration from `agency.db` | 28,909 rows, all services populated |
| 7 | `sqlite3 messages.db ".tables"` | `messages` (plus legacy tables) |
| 8 | `sqlite3 dispatch.db ".tables"` | `dispatch_items`, `dispatch_instances` |
