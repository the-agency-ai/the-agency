# WORKNOTE: Log Service & LogBench

**Date:** 2026-01-10 to 2026-01-20
**REQUEST:** REQUEST-jordan-0012
**Status:** Complete (Phases 1-3), Phase 4 pending
**Tags:** REQUEST-jordan-0012-impl, REQUEST-jordan-0012-tests

---

## Executive Summary

Built **log-service** - a queryable log aggregation service that makes logs accessible to both humans (via LogBench UI) and agents (via API/CLI). The service provides environment observability for The Agency, enabling agents to query logs just like humans grep through them—but smarter.

**Key Insight:** We're in a meta situation: building The Agency with The Agency. The log-service aggregates logs from ALL services in the ecosystem, including itself.

**Vision Statement:** "An agent debugging an issue should be able to query logs via API just like a human would use LogBench to filter and search."

---

## The Problem

Before log-service:
```
Agent: "What happened with that failed request?"
↓
grep through rotating log files
↓
Context window filled with raw log output
↓
Information overload
```

After log-service:
```
Agent: "Show me errors in bug-service from the last hour"
↓
./tools/agency-service log --service bug-service --level error --since 1h
↓
3-line status output + structured data in database
↓
Investigate with: log run {run-id}
```

---

## Architecture

### Embedded Service Pattern

```
services/agency-service/
  src/embedded/
    log-service/
      index.ts              # Service initialization (67 lines)
      types.ts              # Domain models + Zod schemas (219 lines)
      routes/
        log.routes.ts       # HTTP API (296 lines)
      service/
        log.service.ts      # Business logic (227 lines)
      repository/
        log.repository.ts   # SQLite + FTS5 (1,004 lines)
```

**Total:** 1,813 lines of production code

### Data Model

Two primary entities:

**LogEntry** - Individual log records
```typescript
interface LogEntry {
  id: number;
  timestamp: Date;
  service: string;           // bug-service, test-service, etc.
  level: LogLevelType;       // trace, debug, info, warn, error, fatal
  message: string;
  runId?: string;            // Tool run correlation
  requestId?: string;        // HTTP request correlation
  userId?: string;
  userType?: UserTypeValue;
  data?: Record<string, unknown>;
  error?: { name, message, stack };
}
```

**ToolRun** - Tool invocation tracking
```typescript
interface ToolRun {
  runId: string;
  tool: string;              // myclaude, git, commit, etc.
  toolType?: ToolTypeValue;  // agency-tool, bash, mcp
  startedAt: Date;
  endedAt?: Date;
  status: 'running' | 'success' | 'failure';
  args?: string[];           // Command arguments
  agentName?: string;        // Which agent called
  workstream?: string;       // Work context
  exitCode?: number;
  outputSize?: number;       // Bytes (for context analysis)
  duration?: number;         // Milliseconds
  output?: string;           // Full captured output
  summary?: string;          // Minimal status
}
```

### Storage: SQLite + FTS5

Full-text search via SQLite FTS5:

```sql
CREATE VIRTUAL TABLE log_entries_fts USING fts5(
  message,
  content='log_entries',
  content_rowid='id'
);

-- Search example
SELECT * FROM log_entries
WHERE id IN (
  SELECT rowid FROM log_entries_fts
  WHERE log_entries_fts MATCH 'validation error'
);
```

Benefits:
- Fast full-text search without external dependencies
- Embedded in SQLite (no Elasticsearch needed for local dev)
- Automatic synchronization with log_entries table

---

## Key Features

### 1. Tool Output Standard

**The Problem:** Tools outputting 231 lines fill the context window.

**The Solution:** Minimal stdout + verbose output in database.

```bash
# Before
$ ./tools/code-review
[... 231 lines of output ...]

# After
$ ./tools/code-review
code-review [run: a1b2c3d4]
✓

# Investigate if needed
$ ./tools/agency-service log run a1b2c3d4
[Full verbose output from database]
```

**Impact:** 231 lines → 3 lines in context. Verbose data still accessible.

### 2. Pino Dual-Write Integration

All service logs automatically ingested:

```typescript
// In logger.ts
export function enableLogServiceDualWrite(logService: LogService) {
  const dualWriteStream = new Writable({
    write(chunk, encoding, callback) {
      // Parse Pino JSON log
      const logData = JSON.parse(chunk.toString());
      // Ingest into log-service
      logService.ingestFromPino(logData);
      callback();
    }
  });
  // Add to Pino streams
}
```

Result: 7,300+ logs automatically captured during development.

### 3. Service Logs Shortcuts

```bash
# Direct query
./tools/agency-service log --service bug-service --level error

# Shorthand (same result)
./tools/agency-service bug logs --level error

# Works for all services
./tools/agency-service test logs --limit 10
./tools/agency-service message logs --since 1h
```

### 4. Configurable Retention

```bash
# Environment variable
AGENCY_LOG_RETENTION_DAYS=30

# Manual cleanup
./tools/agency-service log cleanup 7  # Keep last 7 days
```

Automatic cleanup runs on service initialization.

---

## API Reference

### Log Ingestion
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/log/ingest` | POST | Ingest single log entry |
| `/api/log/batch` | POST | Batch ingest (up to 1000) |

### Log Query
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/log/query` | GET | Query with filters |
| `/api/log/search` | GET | Full-text search |
| `/api/log/stats` | GET | Statistics (counts by level/service) |
| `/api/log/services` | GET | List services with logs |

### Tool Run Tracking
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/log/run/start` | POST | Start tool run |
| `/api/log/run/end/:id` | POST | End tool run |
| `/api/log/run/get/:id` | GET | Get run details |
| `/api/log/run/list` | GET | List recent runs |

### Query Parameters

```
GET /api/log/query?service=bug-service&level=error&since=1h&limit=100

service     - Filter by service name
level       - Filter by level (trace, debug, info, warn, error, fatal)
since       - Time range (1h, 24h, 7d, or ISO timestamp)
until       - End time (ISO timestamp)
search      - Full-text search in message
runId       - Filter by tool run ID
requestId   - Filter by HTTP request ID
limit       - Max results (default 100, max 1000)
offset      - Pagination offset
```

---

## LogBench UI

Located at `/bench/logs` in AgencyBench.

### Features
- Live log stream with pause/resume
- Filter panel (service, level, time range)
- Full-text search
- Log detail expansion (stack traces, metadata)
- Color-coded by level
- Real-time polling (configurable interval)
- Stats panel (totals, errors in last hour, active services)

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

---

## CLI Reference

```bash
# Query logs
./tools/agency-service log                           # Recent logs
./tools/agency-service log --service bug-service     # Filter by service
./tools/agency-service log --level error             # Filter by level
./tools/agency-service log --since 1h                # Time range
./tools/agency-service log search "failed" 1h        # Full-text search

# Tool runs
./tools/agency-service log run <run-id>              # Get run details
./tools/agency-service log run <run-id> all          # Include output

# Stats & maintenance
./tools/agency-service log stats                     # Statistics
./tools/agency-service log services                  # List services
./tools/agency-service log cleanup [days]            # Delete old logs

# Start/end runs (for tools)
./tools/agency-service log start-run <tool>          # Returns run-id
./tools/agency-service log end-run <id> <status>     # Complete run
```

---

## Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Core log-service (schema, repository, API, CLI) | Complete |
| 2 | Sub-service integration (shortcuts, stats, correlation) | Complete |
| 3 | LogBench UX (UI, filtering, live streaming) | Complete |
| 4 | Cloud readiness (PostgreSQL, multi-env, shipping) | Pending |

### Phase 1 Highlights
- SQLite with FTS5 for full-text search
- Zod validation on all inputs
- Tool run tracking infrastructure
- CLI integration

### Phase 2 Highlights
- Service logs shorthand (`bug logs`, `test logs`)
- Run ID correlation across logs
- Pino dual-write integration

### Phase 3 Highlights
- LogBench React component (705 lines)
- Real-time polling with pause/resume
- Expandable log details
- Stats dashboard

---

## Tool Output Standard Implementation

Fixed 17 tools missing `log_end` calls:

| Tool | Issue | Fix |
|------|-------|-----|
| agency-bench | No log_end | Added |
| bench-build | No log_end | Added |
| bug-report | No log_end | Added |
| code-review | Verbose to stdout | Capture + minimal output |
| hello | No log_end | Added |
| hi | No log_end | Added |
| log | No log_end | Added |
| message-read | No log_end | Added |
| message-send | No log_end | Added |
| nit-add | No log_end | Added |
| nit-resolve | No log_end | Added |
| request-complete | Verbose to stdout | Capture + minimal output |
| starter-compare | No log_end | Added |
| starter-test | No log_end | Added |
| tab-status | No log_end | Added |
| tool-find | No log_end | Added |
| version-next | No log_end | Added |

---

## Metrics

| Metric | Value |
|--------|-------|
| Production code | 1,813 lines |
| Test code | 1,269 lines |
| Tests | 91 (48 repository + 43 routes) |
| API endpoints | 12 |
| CLI commands | 10 |
| Tools updated | 17 |
| Logs captured | 7,300+ (during development) |

---

## For the Book

### Key Themes

1. **Observability for Agents**
   - Agents need the same debugging tools as humans
   - Query logs via API, not grep
   - Correlation IDs link related events

2. **Context Window Economics**
   - 231 lines → 3 lines via tool output standard
   - Verbose data in database, minimal in context
   - Critical for effective agent operation

3. **Dual-Write Pattern**
   - Logs go to files AND queryable database
   - Best of both worlds: file debugging + structured queries
   - Minimal performance impact

4. **Full-Text Search Without Infrastructure**
   - SQLite FTS5 provides search capabilities
   - No Elasticsearch/Solr needed for local dev
   - Scales to cloud with PostgreSQL adapter

### Quotable Patterns

**"Tool Output Standard"** - Minimal stdout, verbose in database. `run-id` links them.

**"Dual-Write Logging"** - Write to rotating files AND queryable database simultaneously.

**"Service Logs Shorthand"** - `bug logs` instead of `log --service bug-service`.

**"Log Run Correlation"** - Every tool run gets a `run-id` that correlates all related logs.

### Case Study Angles

1. **Building Observability Into the Framework**
   - Not an afterthought—designed from the start
   - Agents as first-class log consumers

2. **The Meta Situation**
   - Building The Agency with The Agency
   - Log-service logs itself
   - Dogfooding observability

3. **Context Window Optimization**
   - Real numbers: 231 → 3 lines
   - Tool output standard as framework pattern
   - Database as context overflow

4. **Progressive Enhancement**
   - Phase 1: Basic logging
   - Phase 2: Correlation + shortcuts
   - Phase 3: Visual UI
   - Phase 4: Cloud (future)

### Interesting Challenges

**FTS5 Injection Prevention**
SQLite FTS5 has its own query syntax. User input must be sanitized:
```typescript
// Escape FTS5 special characters
const safeTerm = term.replace(/['"*()^]/g, '');
```

**Pino Stream Integration**
Had to create custom Writable stream that parses Pino's JSON format and re-ingests:
```typescript
const dualWriteStream = new Writable({
  write(chunk, encoding, callback) {
    const logData = JSON.parse(chunk.toString());
    logService.ingestFromPino(logData);
    callback();
  }
});
```

**Tool Run Lifecycle**
Ensuring every `log_start` has matching `log_end` required auditing all 17 tools.

---

## Files Summary

### Core Service (1,813 lines)
| File | Lines | Purpose |
|------|-------|---------|
| `types.ts` | 219 | Domain models, Zod schemas |
| `repository/log.repository.ts` | 1,004 | SQLite + FTS5 data access |
| `service/log.service.ts` | 227 | Business logic |
| `routes/log.routes.ts` | 296 | HTTP endpoints |
| `index.ts` | 67 | Service initialization |

### Tests (1,269 lines)
| File | Tests | Purpose |
|------|-------|---------|
| `repository.test.ts` | 48 | Data layer tests |
| `routes.test.ts` | 43 | API endpoint tests |

### LogBench UI
| File | Lines | Purpose |
|------|-------|---------|
| `logs/page.tsx` | 705 | LogBench React component |

---

## References

- REQUEST-jordan-0012: Full specification
- REQUEST-jordan-0067: Verbose output capture
- IDEA-jordan-00001: Context-efficient tool logging
- LogBench: `/bench/logs` in AgencyBench
- Tags: REQUEST-jordan-0012-impl, REQUEST-jordan-0012-tests
