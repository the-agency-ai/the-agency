# Plan: Per-Service Database Isolation

**Plan ID:** PLAN-0001
**Date:** 2026-03-03
**Agent:** captain
**Principal:** jordan
**Status:** Implemented
**Related:** N/A

## Prompt Context

> Implement per-service database isolation for agency-service. All 10 embedded services currently share a single agency.db file — separate them into individual database files.

## Plan

### Context

All 10 embedded services in `agency-service` share a single `agency.db` file. This creates unnecessary coupling — schema migrations in one service risk others, SQLite file-level locking creates write contention, and extracting a service later requires untangling shared state. The queue adapter already uses a separate `queue.db`, proving the pattern works.

**Key design constraint:** The `DatabaseAdapter` interface is unchanged. No repository or service files are modified. The refactor is entirely in the factory layer and wiring layer.

### Steps

1. **Extend database factory with `serviceName`** — Add optional `serviceName` to `createDatabaseAdapter()` that resolves to `{serviceName}.db`. Add per-service env var override `AGENCY_DB_PATH_{SERVICE}`. Add `DatabaseRegistry` with `initializeAll()`, `closeAll()`, `healthCheckAll()`. Remove singleton `getDatabase`/`closeDatabase`.

2. **Re-wire `index.ts`** — Replace shared `db` with per-service adapters via registry. Update `/health` to report per-service DB status. Update shutdown to `registry.closeAll()`.

3. **Migration script** — Create `migrate-to-per-service-db.ts` that opens `agency.db` read-only, creates target adapters (with schema initialization), copies rows with `INSERT OR IGNORE`.

4. **Documentation** — Update `DISPATCH-AND-MESSAGING.md` architecture section.

### File Layout Result

```
claude/data/
  messages.db, dispatch.db, request.db, log.db, bug.db,
  secret.db, test.db, idea.db, observation.db, product.db,
  queue.db (unchanged), agency.db (preserved backup)
```

### Files Modified

- `source/services/agency-service/src/core/adapters/database/index.ts`
- `source/services/agency-service/src/index.ts`
- `claude/docs/DISPATCH-AND-MESSAGING.md`

### Files Created

- `source/services/agency-service/src/scripts/migrate-to-per-service-db.ts`

### Files NOT Changed

All 10 service directories (repositories, services, routes, types) — zero changes.

## Outcome

Implemented in commit `328a9e0`. All 10 per-service databases created and healthy. Migration script successfully moved 28,909 rows from `agency.db` to per-service DBs. Functional verification passed — `./tools/msg`, `./tools/requests`, and health endpoint all working correctly against per-service databases.
