# REQUEST-jordan-0011-housekeeping-theagencyservice-api-layer

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** In Progress (Phases 1-2 Complete, services expanded)

**Priority:** High

**Created:** 2026-01-10 10:15 SST

**Updated:** 2026-01-10 14:30 SST

## Summary

Create **TheAgencyService** - a central HTTP API that AgencyBench, CLI tools, and future clients use.

**Current State:** CLI tools (`report-bug`) and Tauri backend independently access SQLite databases directly. This means:
- Business logic duplicated (ID generation, notifications, validation)
- No path to remote/cloud deployment
- Hard to add new clients

**Target State:** AgencyBench runs an HTTP API server that all clients use:
- CLI tools call the API (not SQLite directly)
- UI calls the API (not Tauri commands directly)
- Remote clients can call the same API
- Single source of truth for all business logic

## Architecture

### System Overview

```
┌─────────────────┐     ┌──────────────┐     ┌────────────┐
│  AgencyBench UI │────▶│              │◀────│    CLI     │
│   (Tauri+Next)  │     │ TheAgency    │     │   Tools    │
└─────────────────┘     │ Service      │     └────────────┘
                        │  :9999       │
┌─────────────────┐     │              │     ┌────────────┐
│  Claude Code    │────▶│              │◀────│   Remote   │
│  Agents         │     └──────┬───────┘     │  Clients   │
└─────────────────┘            │             └────────────┘
                        ┌──────▼───────┐
                        │   Adapters   │
                        │ SQLite/PG/   │
                        │ Queue/etc    │
                        └──────────────┘
```

### Service Architecture (Cloud-Ready)

```
┌─────────────────────────────────────────────────────────┐
│                   TheAgencyService                       │
│  (Hono on Bun)                                          │
├─────────────────────────────────────────────────────────┤
│  Routes           │  Services           │  Repositories │
│  /api/auth        │  AuthService        │  TokenRepo    │
│  /api/bugs        │  BugService         │  BugRepo      │
│  /api/messages    │  MessageService     │  MessageRepo  │
│  /api/queue       │  QueueService       │  QueueRepo    │
│                   │  NotificationSvc    │               │
├─────────────────────────────────────────────────────────┤
│  Adapters (swappable by environment)                    │
│  ├─ SQLiteAdapter     (local)  → PostgresAdapter (cloud)│
│  ├─ LocalQueueAdapter (local)  → RedisAdapter (cloud)   │
│  └─ LocalAuthAdapter  (local)  → JWTAdapter (cloud)     │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure

```
the-agency/
  apps/                           # UX applications (AgencyBench)
    agency-bench/                 # Tauri + Next.js desktop app
  services/                       # SOA services (expose APIs)
    agency-service/               # Main service, embeds domain services
      src/
        index.ts                  # Hono app entry, mounts embedded services

        # Core infrastructure (shared by all embedded services)
        core/
          adapters/
            database/
              index.ts            # Exports factory + interface
              sqlite.adapter.ts   # Uses bun:sqlite
              postgres.adapter.ts # Future
            queue/
              index.ts            # Exports factory + interface
              sqlite.queue.ts     # SQLite-backed queue
              redis.queue.ts      # Future
          middleware/
            auth.middleware.ts    # Token-based auth
            index.ts              # Exports middleware
          config/
            index.ts              # Singleton config
          lib/
            logger.ts             # Pino + rotating files

        # Embedded services (each can be extracted later)
        embedded/
          bug-service/            # Bug tracking (NOT bug-service)
            index.ts              # Factory function
            routes.ts
            service/
              bug.service.ts
            repository/
              bug.repository.ts
            types.ts
          messages-service/       # Future
          idea-service/           # Future
          # ... more services added over time

      tests/                      # Test suite
        core/
          config.test.ts
          database.test.ts
          queue.test.ts
        bug-service/
          repository.test.ts
          service.test.ts
          routes.test.ts

      package.json
      tsconfig.json

  tools/                          # CLI tools
    agency-service                # CLI for managing agency-service
    report-bug                    # v1: direct SQLite (kept until v2 ready)
  claude/                         # Agent configurations, data, logs
```

**Naming Conventions:**
- **Services** = SOA services exposing APIs (bug-service, message-service)
- **Benches** = UX applications in AgencyBench (BugBench, DocBench)

## Design Decisions

### 1. Framework: Hono on Bun

**Options Considered:**

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Hono + Bun** | Ultra-fast, runs anywhere (Bun/Node/Deno/CF Workers/Lambda), tiny (~14KB), explicit | Newer, smaller community | **Selected** |
| **Nitro (UnJS)** | 20+ deployment presets, file-based routing, Nuxt ecosystem, batteries-included | Heavier, more "magic", framework vs library | Good alternative |
| **Elysia + Bun** | Fastest on Bun, great DX | Bun-only (no portability) | No cloud flexibility |
| **Fastify + Node** | Fast, mature, plugins | Node-only, heavier | Less portable |
| **Express + Node** | Most familiar, huge ecosystem | Slow, old patterns | Legacy |
| **NestJS** | Enterprise, DI, structure | Heavy, opinionated | Overkill |

**Why Hono:**
- Runs on Bun today, Node tomorrow, Cloudflare Workers for edge
- Same code deploys to self-hosted, Vercel, AWS Lambda, Cloudflare
- Web standard APIs (fetch, Request/Response) - not runtime-specific
- Minimal - we add what we need, not strip out what we don't

### 2. Authentication (Token-Based)
- **Always implement full token flow** - even locally
- **Local mode:** Auto-generate token, always validate successfully
- **Remote mode:** Real token validation (JWT or API key)

```typescript
// middleware/auth.middleware.ts
export const authMiddleware = (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '');

  if (config.mode === 'local') {
    // Local: accept any token (or generate one)
    c.set('user', { id: 'local', type: 'principal', name: 'local' });
    return next();
  }

  // Remote: validate token properly
  const user = await validateToken(token);
  if (!user) return c.json({ error: 'Unauthorized' }, 401);
  c.set('user', user);
  return next();
};
```

### 3. Database Abstraction (Vendor-Neutral)

**Principle:** Database is an infrastructure concern. Business logic should not know if we're using SQLite, PostgreSQL, Supabase, or anything else.

**Layers:**
```
Service Layer (business logic)
       ↓
Repository Layer (data access interface)
       ↓
Database Adapter (SQLite, PostgreSQL, Supabase, etc.)
```

**Interface:**
```typescript
// adapters/database/database.interface.ts
export interface DatabaseAdapter {
  query<T>(sql: string, params?: unknown[]): Promise<T[]>;
  execute(sql: string, params?: unknown[]): Promise<{ lastId: number; changes: number }>;
  transaction<T>(fn: (tx: Transaction) => Promise<T>): Promise<T>;
}

// repositories/base.repository.ts
export interface Repository<T> {
  findById(id: string): Promise<T | null>;
  findAll(filters?: Partial<T>): Promise<T[]>;
  create(data: Omit<T, 'id'>): Promise<T>;
  update(id: string, data: Partial<T>): Promise<T>;
  delete(id: string): Promise<void>;
}
```

**Implementations:**

| Adapter | When | Notes |
|---------|------|-------|
| `SQLiteAdapter` | Local development | File-based, no setup |
| `PostgresAdapter` | Self-hosted cloud | Standard, powerful |
| `SupabaseAdapter` | Managed cloud | PostgreSQL + auth + realtime |
| `TursoAdapter` | Edge deployment | SQLite at the edge |

```typescript
// repositories/bug.repository.ts
export class BugRepository implements Repository<Bug> {
  constructor(private db: DatabaseAdapter) {}

  async findById(id: string): Promise<Bug | null> {
    const [bug] = await this.db.query<Bug>(
      'SELECT * FROM bugs WHERE bug_id = ?', [id]
    );
    return bug || null;
  }
  // ... implementation uses adapter, not raw driver
}
```

**ORM Consideration:** Could use Drizzle ORM for type-safe queries that work across SQLite and PostgreSQL. Evaluate in Phase 1.

### 4. Message Queue Abstraction (Vendor-Neutral)

**Principle:** Queue implementation is an infrastructure concern, not a business logic concern. The service should not know or care what queue backend is in use.

**Interface:**
```typescript
// adapters/queue/queue.interface.ts
export interface QueueAdapter {
  enqueue(queue: string, message: QueueMessage): Promise<void>;
  dequeue(queue: string): Promise<QueueMessage | null>;
  acknowledge(queue: string, messageId: string): Promise<void>;
  retry(queue: string, messageId: string, delay?: number): Promise<void>;
  deadLetter(queue: string, messageId: string, reason: string): Promise<void>;
}

export interface QueueMessage {
  id: string;
  payload: unknown;
  attempts: number;
  createdAt: Date;
}
```

**Implementations:**

| Adapter | When | Notes |
|---------|------|-------|
| `SQLiteQueueAdapter` | Local development | Simple, no extra deps, good enough for dev |
| `RedisQueueAdapter` | Cloud (pragmatic) | Via BullMQ, widely supported |
| `RabbitMQAdapter` | Cloud (robust) | If we need complex routing, AMQP |
| `SQSAdapter` | AWS deployment | Managed, infinite scale |

**Local (SQLite):**
```typescript
// adapters/queue/sqlite.queue.ts
export class SQLiteQueueAdapter implements QueueAdapter {
  async enqueue(queue: string, message: QueueMessage): Promise<void> {
    // INSERT INTO queue_messages (queue, payload, status, created_at)
  }
  async dequeue(queue: string): Promise<QueueMessage | null> {
    // SELECT ... WHERE status = 'pending' ORDER BY created_at LIMIT 1
    // UPDATE ... SET status = 'processing'
  }
  // ... acknowledge, retry, deadLetter
}
```

**Note:** SQLite and Redis as queues are pragmatic for now. The abstraction allows us to swap to a proper message broker (RabbitMQ, etc.) when needed without changing business logic.

### 5. Auto-Launch Behavior
- CLI tools and AgencyBench check if service is running
- If not running, start it automatically
- Use PID file or port check for detection

```bash
# In CLI tools
ensure_service_running() {
  if ! curl -s http://localhost:9999/api/health > /dev/null 2>&1; then
    echo "Starting TheAgencyService..."
    $PROJECT_ROOT/services/agency-service/start.sh &
    sleep 2
  fi
}
```

### 6. Configuration

```typescript
// config/index.ts
export const config = {
  mode: process.env.AGENCY_MODE || 'local',  // 'local' | 'remote'
  port: parseInt(process.env.AGENCY_PORT || '9999'),

  // Database
  database: {
    type: process.env.DB_TYPE || 'sqlite',   // 'sqlite' | 'postgres'
    url: process.env.DATABASE_URL || 'claude/data/agency.db',
  },

  // Queue
  queue: {
    type: process.env.QUEUE_TYPE || 'local', // 'local' | 'redis'
    url: process.env.REDIS_URL,
  },

  // Auth
  auth: {
    secret: process.env.AUTH_SECRET || 'local-dev-secret',
  },
};
```

### 7. Environment Variables

```bash
# Local development (defaults)
AGENCY_MODE=local
AGENCY_PORT=9999
DB_TYPE=sqlite
QUEUE_TYPE=local
LOG_LEVEL=debug

# Remote/Cloud deployment
AGENCY_MODE=remote
AGENCY_PORT=443
DB_TYPE=postgres
DATABASE_URL=postgresql://...
QUEUE_TYPE=redis
REDIS_URL=redis://...
AUTH_SECRET=your-production-secret
LOG_LEVEL=info
```

### 8. Logging (Local & Remote)

Structured logging for debugging and observability:

```typescript
// middleware/logging.middleware.ts
import { logger } from '../lib/logger';

export const loggingMiddleware = async (c, next) => {
  const start = Date.now();
  const requestId = crypto.randomUUID();

  logger.info({
    type: 'request',
    requestId,
    method: c.req.method,
    path: c.req.path,
    query: c.req.query(),
  });

  await next();

  logger.info({
    type: 'response',
    requestId,
    status: c.res.status,
    duration: Date.now() - start,
  });
};
```

**Log Levels:**
- `debug` - Detailed debugging (local default)
- `info` - Request/response, important operations
- `warn` - Recoverable issues
- `error` - Failures

**Log Output:**
- Local: Pretty-printed to console + rotating log files
- Remote: JSON to stdout (for log aggregators)

**Log File Structure:**
```
claude/logs/services/agency-service/
  log-20260110-1030.log
  log-20260110-1130.log
  log-20260110-1230.log
  ...
```

- New file every hour (or configurable interval)
- Auto-cleanup of logs older than N days
- Easy to find logs for a specific time period

```typescript
// lib/logger.ts
import pino from 'pino';
import { createRotatingFileStream } from './log-rotation';

const logDir = 'claude/logs/services/agency-service';

export const logger = pino({
  level: config.logLevel,
  transport: config.mode === 'local' ? {
    targets: [
      { target: 'pino-pretty', options: { colorize: true } },
      { target: 'pino/file', options: {
        destination: createRotatingFileStream(logDir),
      }},
    ]
  } : undefined,
});
```

**What Gets Logged:**
- All API requests/responses (with timing)
- Auth attempts (success/failure)
- Database queries (in debug mode)
- Queue operations
- Errors with stack traces
- Service startup/shutdown

## API Design

### Bug Service API

**Note:** Routes use singular `/api/bug` (not `/api/bugs`) following REST conventions for resource naming.

```
POST   /api/bug                     # Create bug
GET    /api/bug                     # List bugs (with filters)
GET    /api/bug/stats               # Get bug statistics
GET    /api/bug/:bugId              # Get bug details
PATCH  /api/bug/:bugId              # Update bug (status, assignee, etc.)
PATCH  /api/bug/:bugId/status       # Update status only
PATCH  /api/bug/:bugId/assign       # Assign bug
DELETE /api/bug/:bugId              # Delete bug

# Future
POST   /api/bug/:bugId/attachments  # Add attachment
GET    /api/bug/:bugId/attachments  # List attachments
```

### Messages API

```
POST   /api/messages                # Send message
GET    /api/messages                # List messages
GET    /api/messages/:id            # Get message
PATCH  /api/messages/:id/read       # Mark as read
```

### Future APIs (other AgencyBench apps)

```
# Knowledge Indexer
GET    /api/knowledge/search
POST   /api/knowledge/index

# Agent Monitor
GET    /api/agents
GET    /api/agents/:name/status

# Collaboration
POST   /api/collaboration/request
GET    /api/collaboration/pending
```

## Implementation Phases

### Phase 1: Foundation + bug-service ✅ COMPLETE
Combined foundation and first embedded service to prove the pattern.

**Core Infrastructure:** ✅
- [x] Create `services/agency-service/` structure
- [x] Set up Bun + Hono project
- [x] Implement `core/config/` (local/remote mode, singleton pattern)
- [x] Implement `core/lib/logger.ts` (pino + rotating files)
- [x] Set up log rotation at `claude/logs/services/agency-service/`
- [x] Implement `core/middleware/auth.middleware.ts` (token-based, passes locally)
- [x] Implement `core/adapters/database/database.interface.ts`
- [x] Implement `core/adapters/database/sqlite.adapter.ts` (uses bun:sqlite)
- [x] Implement `core/adapters/queue/queue.interface.ts`
- [x] Implement `core/adapters/queue/sqlite.queue.ts` (SQLite-backed queue)
- [x] Add health check endpoint (`GET /api/health`)
- [x] Create `./tools/agency-service` CLI (renamed from agency-api)

**bug-service (first embedded service):** ✅
- [x] Create `embedded/bug-service/` structure (renamed from bug-service)
- [x] Implement `types.ts` (Bug, CreateBugInput, UpdateBugInput, etc.)
- [x] Implement `repository/bug.repository.ts`
- [x] Implement `service/bug.service.ts` (with queue-based notifications)
- [x] Implement `routes.ts` (`/api/bug/*` - singular, not /bugs)
- [x] Keep v1 `./tools/report-bug` unchanged (v1 = direct SQLite)
- [x] Create `./tools/agency-service bug create` via API (v2)
- [x] Create `./tools/agency-service bug list` via API
- [x] Create `./tools/agency-service bug show` via API

**Test Suite:** ✅ (71 tests passing)
- [x] `tests/core/config.test.ts` - Config singleton, env overrides
- [x] `tests/core/database.test.ts` - SQLite adapter CRUD, transactions
- [x] `tests/core/queue.test.ts` - Queue enqueue/dequeue, priority, retry
- [x] `tests/bug-service/repository.test.ts` - Bug repository operations
- [x] `tests/bug-service/service.test.ts` - Bug service business logic
- [x] `tests/bug-service/routes.test.ts` - API endpoint integration tests

**Manual Testing:**
- [x] `curl http://localhost:9999/api/health` returns OK
- [x] `curl -H "Authorization: Bearer test" http://localhost:9999/api/bug` works
- [x] `./tools/agency-service bug create --workstream X --summary "..."` works

**Deferred to Later:**
- [ ] Update BugBench UI to call API (Phase 2 with UI work)
- [ ] Remove bug-related SQLite code from Tauri (after UI migration)
- [ ] Auto-launch detection (low priority for now)

### Phase 2: messages-service + Queue (agency-service workstream)
Spin up dedicated agents for parallel development.

**messages-service (second embedded service):**
- [ ] Create `embedded/messages-service/` structure
- [ ] Implement `types.ts` (Message, Recipient, etc.)
- [ ] Implement `message.repository.ts`
- [ ] Implement `message.service.ts`
- [ ] Implement `routes.ts` (`/api/messages/*`)
- [ ] Refactor `./tools/send-message` to use API
- [ ] Refactor `./tools/read-messages` to use API
- [ ] Update Messages UI to call API
- [ ] Remove message-related SQLite code from Tauri

**Queue Infrastructure:**
- [ ] Implement `core/adapters/queue/queue.interface.ts`
- [ ] Implement `core/adapters/queue/sqlite.queue.ts`
- [ ] Bug notifications go through queue
- [ ] Message delivery through queue
- [ ] Queue processing worker (background job)

### Phase 3: idea-service - Prove Embeddable Pattern (agency-service workstream)

**Goal:** Build a third embedded service to prove and refine the pattern.

Just like AgencyBench embeds applications (BugBench, DocBench, etc.), TheAgencyService should embed services that can be easily extracted into standalone services later.

**Embeddable Service Pattern:**
```
services/agency-service/
  src/
    index.ts                    # Main app, mounts embedded services
    core/                       # Shared infrastructure
    embedded/                   # Embeddable service modules
      bug-service/        # Bug tracking (from Phase 1)
        routes.ts
        bug.service.ts
        bug.repository.ts
        types.ts
      messages-service/         # Messaging (from Phase 2)
        routes.ts
        message.service.ts
        message.repository.ts
        types.ts
      idea-service/             # NEW: Idea capture service
        routes.ts
        idea.service.ts
        idea.repository.ts
        types.ts
```

**Mounting Pattern:**
```typescript
// src/index.ts
import { Hono } from 'hono';
import { bugBenchRoutes } from './embedded/bug-service/routes';
import { messagesRoutes } from './embedded/messages-service/routes';
import { ideasRoutes } from './embedded/idea-service/routes';

const app = new Hono();

// Mount embedded services
app.route('/api/bugs', bugBenchRoutes);
app.route('/api/messages', messagesRoutes);
app.route('/api/ideas', ideasRoutes);

// Later: extract to standalone service
// app.route('/api/ideas', proxy('http://idea-service:9998'));
```

**Idea Service:**

A simple service for capturing ideas when they arise - invokable by principals and agents.

```
POST   /api/ideas                 # Capture an idea
GET    /api/ideas                 # List ideas (with filters)
GET    /api/ideas/:id             # Get idea details
PATCH  /api/ideas/:id             # Update idea (status, notes)
DELETE /api/ideas/:id             # Delete idea
POST   /api/ideas/:id/promote     # Promote to Request
```

**Idea Schema:**
```typescript
interface Idea {
  id: string;                    // IDEA-00001
  title: string;                 // Short title
  description: string;           // Full description
  source: {
    type: 'principal' | 'agent' | 'system';
    name: string;
  };
  status: 'captured' | 'exploring' | 'promoted' | 'parked' | 'discarded';
  tags: string[];                // e.g., ['agencybench', 'tooling']
  promotedTo?: string;           // REQUEST-jordan-0012 (if promoted)
  createdAt: Date;
  updatedAt: Date;
}
```

**CLI Tool:**
```bash
# Quick capture
./tools/idea "What if we had a visual workflow editor?"

# With details
./tools/idea --title "Visual Workflow Editor" \
  --description "Drag and drop interface for defining agent workflows" \
  --tags "agencybench,ux"

# List ideas
./tools/list-ideas --status captured

# Promote to request
./tools/promote-idea IDEA-00001 --assignee housekeeping
```

**Phase 3 Tasks:**
- [ ] Document embeddable service pattern/conventions
- [ ] Create `embedded/idea-service/` structure
- [ ] Implement `types.ts` (Idea, CreateIdeaDto, etc.)
- [ ] Implement `idea.repository.ts`
- [ ] Implement `idea.service.ts`
- [ ] Implement `routes.ts` (`/api/ideas/*`)
- [ ] Create `./tools/idea` CLI (quick capture)
- [ ] Create `./tools/list-ideas` CLI
- [ ] Create `./tools/promote-idea` CLI (idea → request)
- [ ] Add Ideas section to AgencyBench UI (optional)
- [ ] Document how to extract an embedded service to standalone

### Phase 4: Remaining Embedded Services (agency-service workstream)

Each becomes a proper service, embeddable now, extractable later.

**knowledge-service:**
- [ ] Define knowledge indexing domain model
- [ ] Implement KnowledgeRepository
- [ ] Implement KnowledgeService (indexing, search)
- [ ] Implement routes (`/api/knowledge/*`)
- [ ] Refactor Knowledge Indexer UI to use service

**agent-monitor-service:**
- [ ] Define agent monitoring domain model
- [ ] Implement AgentRepository
- [ ] Implement AgentMonitorService (status, health)
- [ ] Implement routes (`/api/agents/*`)
- [ ] Refactor Agent Monitor UI to use service

**collaboration-service:**
- [ ] Define collaboration domain model
- [ ] Implement CollaborationRepository
- [ ] Implement CollaborationService (requests, responses)
- [ ] Implement routes (`/api/collaboration/*`)
- [ ] Refactor Collaboration Inbox UI to use service

**doc-bench-service:**
- [ ] Define document domain model
- [ ] Implement DocumentRepository
- [ ] Implement DocBenchService (CRUD, search, render)
- [ ] Implement routes (`/api/documents/*`)
- [ ] Refactor DocBench UI to use service

**Architecture After Phase 4:**
```
services/agency-service/
  src/
    embedded/
      bug-service/        # Bug tracking
      messages-service/         # Messaging
      idea-service/             # Idea capture
      knowledge-service/        # Knowledge indexing
      agent-monitor-service/    # Agent monitoring
      collaboration-service/    # Collaboration requests
      doc-bench-service/        # Document management
```

AgencyBench becomes purely a UI layer consuming these services.

### Phase 5: Cloud Readiness
- [ ] Implement PostgresAdapter
- [ ] Implement RedisQueueAdapter
- [ ] Implement real JWT authentication
- [ ] Add rate limiting middleware
- [ ] Add request logging middleware
- [ ] Create Docker container
- [ ] Document Supabase deployment
- [ ] Document self-hosted deployment

## Acceptance Criteria

**Phase 1:** ✅ COMPLETE
- [x] `services/agency-service/` exists with full structure
- [x] `curl http://localhost:9999/api/health` returns OK
- [x] `curl -H "Authorization: Bearer any" http://localhost:9999/api/bug` works in local mode
- [x] `./tools/agency-service bug create/list/show` work via API (v2 path)
- [x] v1 tools (`./tools/report-bug`) remain unchanged until v2 is production-ready
- [x] Extensive test suite (71 tests passing)
- [ ] BugBench UI works entirely through API (deferred)
- [ ] Service auto-starts when CLI tool runs (deferred)

**Overall:**
- [x] All business logic in TheAgencyService, not duplicated
- [x] Adapters are swappable via config (interface/adapter pattern)
- [x] Auth token mechanism in place (passes locally)
- [x] Can switch to remote mode by changing env vars

## Technical Notes

### Framework Choice: Hono on Bun

| Option | Pros | Cons |
|--------|------|------|
| Embed in Tauri (Rust) | Single binary | Requires GUI, less flexible |
| Next.js API routes | Already have Next.js | Tied to Next.js, can't run headless |
| Bun + Hono | Fast, lightweight, TypeScript, deploys anywhere | Additional process |
| Node + Express | Mature | Heavier, older patterns |

**Choice:** Bun + Hono
- Deploys to Cloudflare Workers, Vercel Edge, AWS Lambda
- TypeScript native
- ~3x faster than Express
- Modern middleware patterns

### CLI API Helper

Create `./tools/agency-api` to wrap HTTP calls with auth/URL handling:

```bash
#!/bin/bash
# ./tools/agency-api - Helper for calling TheAgencyService

ensure_service_running

METHOD="$1"
ENDPOINT="$2"
DATA="$3"

TOKEN="${AGENCY_API_TOKEN:-local-token}"
URL="${AGENCY_API_URL:-http://localhost:9999}"

curl -s -X "$METHOD" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  ${DATA:+-d "$DATA"} \
  "$URL$ENDPOINT"
```

Usage:
```bash
./tools/agency-api POST /api/bugs '{"workstream":"BENCH","summary":"..."}'
./tools/agency-api GET "/api/bugs?status=Open"
./tools/agency-api PATCH /api/bugs/BENCH-00001 '{"status":"Fixed"}'
```

### ORM Consideration

For database abstraction, considered:
- **Drizzle ORM** - Lightweight, SQL-first, good SQLite + PostgreSQL support
- **Prisma** - More features but heavier
- **Raw SQL with adapters** - Most flexible but more work

**Recommendation:** Start with Drizzle - good balance of type safety and flexibility.

## Decisions Made

1. **Location:** `services/agency-service/` (sets up pattern for future services)
2. **Framework:** Hono on Bun
3. **Auth:** Token-based, always implemented, passes in local mode
4. **Database:** Repository pattern with swappable adapters (SQLite → PostgreSQL)
5. **Queue:** SQLite-backed locally, Redis for cloud
6. **Auto-launch:** Service starts automatically when needed

---

## Activity Log

### 2026-01-10 11:00 SST - Service-Oriented Architecture
- Renamed to service-oriented naming: bug-service, messages-service, idea-service, etc.
- Each AgencyBench app becomes a UI consuming its corresponding service
- Services are embeddable now, extractable to standalone later
- Added Phase 3: idea-service to prove the embeddable pattern
- Phase 4 expanded: knowledge-service, agent-monitor-service, collaboration-service, doc-bench-service

### 2026-01-10 10:45 SST - Framework Debate
- Compared Hono vs Nitro vs NestJS in depth
- Hono wins for: fast startup (CLI auto-launch), low memory (laptop-friendly), edge deployment
- Nitro: good alternative if we want more structure, 20+ deployment presets
- NestJS: too heavy for auto-launch, but good DI/module patterns
- Decision: Start with Hono, revisit if we need more structure

### 2026-01-10 10:30 SST - Architecture Refined
- Decided on `services/agency-service/` location
- Designed cloud-ready architecture with adapters
- Added repository pattern for database abstraction (vendor-neutral)
- Added queue abstraction for future scaling (SQLite → Redis/RabbitMQ)
- Logging: rotating files at `claude/logs/services/agency-service/log-YYYYMMDD-HHMM.log`
- Combined Phase 1 & 2 for initial implementation
- Plan to create agency-service workstream for Phase 2+

### 2026-01-10 10:15 SST - Created
- Request created based on discussion about BugBench CLI architecture
- Identified need to refactor from direct SQLite access to API-based access
- Designed HTTP API approach for local/remote flexibility

### 2026-01-10 14:30 SST - Phase 1 Complete ✅

**Implementation Completed:**
- Full `services/agency-service/` structure with Bun + Hono
- Core infrastructure: config, logging (pino + rotating files), database adapter, queue adapter
- Auth middleware (token-based, passes in local mode)
- bug-service as first embedded service with full CRUD API
- `./tools/agency-service` CLI for managing the service

**Key Technical Decisions:**
- Using `bun:sqlite` (not better-sqlite3) - better-sqlite3 has native module compilation issues with Bun
- SQLite-backed queue for local development (vendor-neutral interface for future Redis)
- Interface/adapter pattern for all infrastructure (database, queue, auth)

**Naming Conventions Established:**
- Services use singular routes: `/api/bug` not `/api/bugs`
- `bug-service` not `bug-bench-service` (benches = UX, services = SOA)
- `./tools/agency-service` not `./tools/agency-api`

**v1/v2 Coexistence:**
- v1 tools (direct SQLite) remain unchanged: `./tools/report-bug`
- v2 tools use API: `./tools/agency-service bug create`
- Will switch fully to v2 when API is production-ready

**Test Suite:**
- 71 tests across 6 test files
- Tests for: config, database adapter, queue adapter, bug repository, bug service, bug routes
- All tests passing

**Business Model Note:**
- Open source + free for local, solo Principal + multi-Agent development
- Paid for multi-principal + multi-agent development

**Project Structure Clarified:**
- `apps/` at project root (not in `claude/`) - UX applications
- `services/` at project root - SOA services
- `tools/` at project root - CLI tools
- `claude/` - agent configurations, data, logs

### 2026-01-10 15:00 SST - CLI Tool Enhanced + Future Services Planned

**CLI Tool Updates (`./tools/agency-service`):**
- Added `install` command (installs Bun + npm deps)
- Added `status` command (shows running state + health)
- Added `restart` command
- Added `logs` command (tail service logs)
- Added `test` command (runs test suite)

**CLI Command Structure Refined:**
```bash
# Service lifecycle (top-level)
./tools/agency-service install | start | stop | restart

# Service introspection (top-level)
./tools/agency-service status | health | logs | test

# Sub-service introspection
./tools/agency-service bug status | health | logs | test

# Sub-service API
./tools/agency-service bug list | create | get | update | ...
```

**Environment Observability Vision:**
Discussed pattern for making the development environment introspectable for both agents and humans:

1. **Log Service (REQUEST-jordan-0012)**
   - Queryable log aggregation
   - Agents can ask: "Show me errors in bug-service from the last hour"
   - LogBench UX in AgencyBench
   - Single log file, filtered by service tag (Option B)
   - Extends to cloud for multi-environment debugging

2. **Test Service (REQUEST-jordan-0013)**
   - Test execution and history tracking
   - Agents can ask: "Run bug-service tests", "When did this test last pass?"
   - TestBench UX in AgencyBench
   - Flaky test detection
   - Extends to cloud for CI/CD integration

**Key Insight:** The pattern is environment observability - agents should be able to investigate issues by querying logs, running targeted tests, and correlating failures, just like a human would.

**Related Requests Created:**
- REQUEST-jordan-0012: log-service + LogBench
- REQUEST-jordan-0013: test-service + TestBench

### 2026-01-10 18:00 SST - Current State Audit

**Embedded Services Implemented:**
| Service | Routes | Repository | Service | Types | Status |
|---------|--------|------------|---------|-------|--------|
| bug-service | ✓ | ✓ | ✓ | ✓ | Complete |
| messages-service | ✓ | ✓ | ✓ | ✓ | Complete |
| log-service | ✓ | ✓ | ✓ | ✓ | Complete |
| test-service | ✓ | ✓ | ✓ | ✓ | Complete |
| product-service | ✓ | ✓ | ✓ | ✓ | Complete |
| secret-service | ✓ | ✓ | ✓ | ✓ | Complete (Phase 1) |

**What's Done:**
- 6 embedded services with full structure
- Core infrastructure (database adapter, queue adapter, config, logging)
- Auth middleware
- CLI tool (./tools/agency-service)

**What's Remaining:**
- Phase 3: idea-service (quick capture tool)
- Phase 4: knowledge-service, agent-monitor-service, collaboration-service, doc-bench-service
- Phase 5: Cloud readiness (PostgreSQL, Redis, JWT, Docker)
- UI integration: BugBench, LogBench, etc. should call API not SQLite directly

**Priority for Now:** Focus on missing UI integrations and Phase 3 idea-service

### 2026-01-10 19:10 SST - Phase 3 Complete: idea-service

**idea-service Implemented:**
- Full CRUD: create, list, get, update, delete
- Status workflow: captured → exploring → promoted/parked/discarded
- Tag management: add-tags, remove-tags
- Promote to REQUEST endpoint
- Stats for dashboard

**API Endpoints:**
```
POST   /api/idea/create        # Quick capture
GET    /api/idea/list          # List with filters (status, source, tag, search)
GET    /api/idea/get/:ideaId   # Get details
POST   /api/idea/update/:ideaId
POST   /api/idea/promote/:ideaId  # Link to REQUEST
POST   /api/idea/explore/:ideaId
POST   /api/idea/park/:ideaId
POST   /api/idea/discard/:ideaId
POST   /api/idea/add-tags/:ideaId
POST   /api/idea/remove-tags/:ideaId
POST   /api/idea/delete/:ideaId
GET    /api/idea/stats
```

**Files Created:**
- `embedded/idea-service/types.ts`
- `embedded/idea-service/repository/idea.repository.ts`
- `embedded/idea-service/service/idea.service.ts`
- `embedded/idea-service/routes/idea.routes.ts`
- `embedded/idea-service/index.ts`

**Tests:** All 151 tests passing
