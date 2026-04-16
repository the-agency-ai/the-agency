# REQUEST-jordan-0070: Log Service Phase 4 - Cloud Readiness

**Status:** Open
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-20
**Updated:** 2026-01-20

## Summary

Cloud readiness features for log-service: PostgreSQL adapter for production, multi-environment support, and log shipping from remote services.

**Continuation of:** REQUEST-jordan-0012 (Log Service + LogBench) - Phases 1-3 complete

## Details

### 1. PostgreSQL Adapter

Replace SQLite with PostgreSQL for production deployments:
- Implement `PostgresLogRepository` following existing adapter pattern
- Add connection pooling (pg-pool)
- Consider TimescaleDB extension for time-series optimization
- Migration scripts for schema
- Config: `AGENCY_LOG_DB_URL` for PostgreSQL connection

### 2. Multi-Environment Support

Aggregate and distinguish logs from different environments:
- Add `environment` field to log entries (dev, staging, prod)
- Environment filtering in queries and CLI
- Cross-environment correlation by requestId
- LogBench UI environment filter

### 3. Log Shipping from Remote Services

Ship logs from remote/cloud services to central log-service:
- Collector agent that runs on remote machines
- Batch logs and ship to central log-service
- Retry logic, compression, authentication
- Could leverage existing queue adapter pattern
- Consider: push (agent ships) vs pull (central fetches)

## Acceptance Criteria

**PostgreSQL Adapter:**
- [ ] PostgreSQL log repository implementation
- [ ] Config switch between SQLite and PostgreSQL
- [ ] Schema migrations for PostgreSQL
- [ ] Tests pass with PostgreSQL backend

**Multi-Environment:**
- [ ] `environment` field in log entries
- [ ] `--environment` filter in CLI
- [ ] Environment filter in LogBench UI
- [ ] Cross-environment requestId correlation

**Log Shipping:**
- [ ] Log collector agent design
- [ ] Secure shipping protocol
- [ ] Retry and reliability handling
- [ ] Remote service configuration

## Technical Notes

### Database Adapter Pattern

Already in place at `src/core/adapters/database/`:
```typescript
interface DatabaseAdapter {
  initialize(): Promise<void>;
  close(): Promise<void>;
  // ... query methods
}
```

LogRepository can be parameterized similarly.

### TimescaleDB Consideration

For high-volume production logging:
```sql
-- Convert logs table to hypertable
SELECT create_hypertable('log_entries', 'timestamp');

-- Automatic data retention
SELECT add_retention_policy('log_entries', INTERVAL '30 days');
```

## Dependencies

- REQUEST-jordan-0012 (Log Service Phases 1-3) - COMPLETE

---

## Activity Log

### 2026-01-20 - Created
- Request created to track Phase 4 of log service
- Split from REQUEST-jordan-0012 which is now complete
