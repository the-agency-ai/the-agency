# REQUEST-jordan-0012: Log Service + LogBench

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** High

**Created:** 2026-01-10 14:45 SST

**Updated:** 2026-01-10 14:45 SST

## Summary

Build **log-service** - a queryable log aggregation service that makes logs accessible to both humans (via LogBench UI) and agents (via API/CLI).

**Vision:** Environment observability for agents and principals. An agent debugging an issue should be able to query logs just like a human would grep through them - but smarter.

**Multi-Service:** This service will aggregate logs from ALL services in the ecosystem - agency-service, future extracted services, and eventually cloud/remote services. We're in a meta situation: building The Agency with The Agency.

**Related Ideas:**
- IDEA-jordan-00001: Context-efficient tool logging - Tools should log to log-service and return minimal output (1 line vs 231 lines), dramatically reducing context window consumption while maintaining debuggability.

## Use Cases

### For Agents
```
"Show me errors in bug-service from the last hour"
"What happened around request ID abc-123?"
"Find all logs mentioning user jordan"
"Show me the request/response for the failed API call"
```

### For Principals (via LogBench UI)
- Live log tailing with filters
- Search across time ranges
- Drill down by service, level, correlation ID
- Error aggregation and trends

### Future (Cloud)
- Aggregate logs from dev/staging/prod
- Cross-environment debugging
- Log retention policies
- Alerting integration

## Architecture

### Embedded Service Pattern
```
services/agency-service/
  src/embedded/
    log-service/
      index.ts
      routes.ts
      service/
        log.service.ts
      repository/
        log.repository.ts
      types.ts
```

### API Design

```
# Ingestion
POST   /api/log                      # Ingest log entry (internal)
POST   /api/log/batch                # Batch ingest

# Query
GET    /api/log                      # Query logs with filters
GET    /api/log/search               # Full-text search
GET    /api/log/stats                # Log statistics (counts by level, service)
GET    /api/log/services             # List services with logs

# Streaming (future)
GET    /api/log/stream               # WebSocket/SSE live tail
```

### Query Parameters

```
GET /api/log?service=bug-service&level=error&since=1h&limit=100

Parameters:
  service     - Filter by service name
  level       - Filter by level (trace, debug, info, warn, error, fatal)
  since       - Time range (1h, 24h, 7d, or ISO timestamp)
  until       - End time (ISO timestamp)
  search      - Full-text search in message
  requestId   - Filter by correlation/request ID
  limit       - Max results (default 100)
  offset      - Pagination offset
```

### Log Entry Schema

```typescript
interface LogEntry {
  id: string;                    // UUID
  timestamp: Date;
  service: string;               // e.g., "bug-service", "core", "queue"
  level: 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal';
  message: string;

  // Context
  requestId?: string;            // Correlation ID
  userId?: string;               // Who triggered this
  userType?: 'principal' | 'agent' | 'system';

  // Structured data
  data?: Record<string, unknown>; // Additional fields

  // Error info
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}
```

### Storage Strategy

**Local (SQLite):**
- Store logs in SQLite with FTS5 for full-text search
- Automatic rotation/cleanup (keep last N days)
- Fast enough for local development

**Cloud (Future):**
- PostgreSQL with TimescaleDB extension
- Or dedicated log service (Loki, Elasticsearch)
- Configurable retention policies

### Integration with Existing Logging

Current pino logger writes to rotating files. Options:

**Option A: Dual Write**
- Logger writes to file AND inserts into log-service DB
- Pro: Real-time queryability
- Con: More I/O, potential performance impact

**Option B: Log Shipper**
- Separate process tails log files, inserts into DB
- Pro: Decoupled, no performance impact on main service
- Con: Slight delay, more moving parts

**Option C: Replace File Logging**
- Logger writes directly to log-service DB only
- Pro: Single source of truth
- Con: Lose file-based debugging if DB issues

**Recommendation:** Start with Option A (dual write) for simplicity. The performance impact is minimal for local development.

## CLI Integration

```bash
# Query logs
./tools/agency-service log                           # Recent logs (all)
./tools/agency-service log --service bug-service     # Filter by service
./tools/agency-service log --level error             # Filter by level
./tools/agency-service log --since 1h                # Time range
./tools/agency-service log --search "failed"         # Full-text search

# Sub-service shorthand
./tools/agency-service bug logs                      # Same as --service bug-service

# Live tail
./tools/agency-service log --follow                  # Stream new logs

# Stats
./tools/agency-service log stats                     # Error counts, etc.
```

## LogBench UX (AgencyBench)

### Features
- Live log stream with pause/resume
- Filter panel (service, level, time range)
- Search bar with autocomplete
- Log detail view (expand to see full context)
- Error highlighting
- Timestamp toggle (relative vs absolute)
- Export to file

### Layout
```
┌─────────────────────────────────────────────────────────────┐
│ LogBench                                    [Live] [Pause]  │
├─────────────────────────────────────────────────────────────┤
│ Service: [All ▼]  Level: [All ▼]  Since: [1h ▼]  [Search...] │
├─────────────────────────────────────────────────────────────┤
│ 14:32:01 INFO  bug-service   Bug created: BENCH-00042       │
│ 14:32:00 DEBUG core          Request: POST /api/bug         │
│ 14:31:58 ERROR bug-service   Validation failed: missing... ▼│
│   └─ { "field": "summary", "error": "required" }            │
│ 14:31:55 INFO  queue         Job enqueued: notify-assignee  │
│ ...                                                         │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Core log-service
- [ ] Create `embedded/log-service/` structure
- [ ] Implement log entry schema and types
- [ ] Implement `log.repository.ts` with SQLite + FTS5
- [ ] Implement `log.service.ts` with query methods
- [ ] Implement routes (`/api/log/*`)
- [ ] Integrate with existing pino logger (dual write)
- [ ] Add CLI commands (`./tools/agency-service log`)

### Phase 2: Sub-service integration
- [ ] Add `./tools/agency-service <service> logs` shorthand
- [ ] Add log stats endpoint
- [ ] Add request ID correlation

### Phase 3: LogBench UX
- [ ] Create LogBench app in AgencyBench
- [ ] Implement live log streaming (SSE or polling)
- [ ] Add filter/search UI
- [ ] Add log detail expansion

### Phase 4: Cloud Readiness
- [ ] PostgreSQL adapter for log storage
- [ ] Multi-environment support
- [ ] Retention policies
- [ ] Log shipping from remote services

## Acceptance Criteria

**Phase 1:**
- [ ] `curl /api/log?service=bug-service&level=error` returns filtered logs
- [ ] `./tools/agency-service log --service bug-service` works
- [ ] Logs are automatically ingested as services run
- [ ] Full-text search works

**Overall:**
- [ ] Agents can query logs via API
- [ ] LogBench UI provides human-friendly log viewing
- [ ] Logs are retained for configurable period
- [ ] Performance impact on main service is minimal

## Dependencies

- REQUEST-jordan-0011 (agency-service foundation) - COMPLETE

## Technical Notes

### SQLite FTS5 for Search

```sql
CREATE VIRTUAL TABLE log_entries_fts USING fts5(
  message,
  content='log_entries',
  content_rowid='id'
);

-- Search
SELECT * FROM log_entries
WHERE id IN (SELECT rowid FROM log_entries_fts WHERE log_entries_fts MATCH 'error');
```

### Pino Integration

```typescript
// Wrap pino to dual-write
import { logger } from './lib/logger';
import { logService } from './embedded/log-service';

const originalInfo = logger.info.bind(logger);
logger.info = (obj, msg) => {
  originalInfo(obj, msg);
  logService.ingest({ level: 'info', message: msg, data: obj });
};
```

---

## Activity Log

### 2026-01-10 14:45 SST - Created
- Request created based on discussion about environment observability
- Vision: queryable logs for both agents and humans
- Supports future cloud/multi-environment debugging
