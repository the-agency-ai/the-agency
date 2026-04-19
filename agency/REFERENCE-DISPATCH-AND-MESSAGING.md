# Dispatch & Unified Messaging

Architecture documentation for the Agent Dispatch and Unified Messaging systems.

## Overview

Two complementary services built into agency-service:

1. **Unified Messaging** — Direct messages and broadcasts between agents, replacing collaboration files, NEWS.md, and the old messages.db
2. **Dispatch Queue** — Work queue with tiered pickup (agent-specific → shared), claim mechanics, and instance registry

Both are embedded services within `agency-service` at port 3141.

### Per-Service Database Isolation

Each embedded service has its own SQLite database file in `agency/data/`:

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
| queue | `queue.db` | Queue adapter (separate) |

Per-service env var override: `AGENCY_DB_PATH_{SERVICE}` (e.g., `AGENCY_DB_PATH_MESSAGES=/custom/path.db`).

## Unified Messaging

### Message Types

| Type | Description | Use Case |
|------|-------------|----------|
| `direct` | Agent-to-agent | Code review requests, collaboration, replies |
| `broadcast` | Agent-to-all | Announcements, convention changes, news |

### Schema

Single `messages` table with UUID IDs:
- `type` — direct or broadcast
- `from_agent`, `to_agent` — sender and recipient (to_agent null for broadcasts)
- `subject`, `body` — content
- `reference_id` — links reply to parent message (threading)
- `tags` — JSON array for categorization (e.g., `["review", "urgent"]`)
- `read_by` — JSON array of agent names who have read the message

### API Endpoints

```
POST /api/message/send              — Send direct message
POST /api/message/broadcast         — Send broadcast
POST /api/message/read/:id          — Mark as read by agent
GET  /api/message/list              — List with filters
GET  /api/message/get/:id           — Get specific message
GET  /api/message/unread/:agentName — Unread count + messages
GET  /api/message/thread/:id        — Message + all replies
POST /api/message/delete/:id        — Delete message
GET  /api/message/stats             — Statistics
```

### CLI Tool: `./agency/tools/msg`

```bash
./agency/tools/msg send research "Review needed" "Please check the PR"
./agency/tools/msg send captain "Re: Review" "Looks good" --ref <msg-id>
./agency/tools/msg broadcast "Convention change" "Use explicit operations"
./agency/tools/msg read                    # Unread messages
./agency/tools/msg read --all              # All messages
./agency/tools/msg thread <msg-id>         # Message chain
./agency/tools/msg ack <msg-id>            # Mark as read
```

### Migration from Old Systems

| Old System | New Equivalent | Notes |
|------------|----------------|-------|
| `./agency/tools/collaborate` | `./agency/tools/msg send <agent> "subject" "body"` | Wrapper delegates to msg |
| `./agency/tools/collaboration-respond` | `./agency/tools/msg send <agent> "Re: subject" "body" --ref <id>` | Old file format retired |
| `./agency/tools/news-post` | `./agency/tools/msg broadcast "subject" "body"` | Wrapper delegates to msg |
| `./agency/tools/news-read` | `./agency/tools/msg read` | Falls back to legacy if service down |
| `./agency/tools/message-send` | `./agency/tools/msg send` | Wrapper delegates to msg |
| `./agency/tools/message-read` | `./agency/tools/msg read` | Wrapper delegates to msg |

Old tools are preserved as `*.legacy` files. Wrappers maintain backward compatibility.

## Dispatch Queue

### Queue Semantics

**Tiered pickup order:**
1. Agent's own queue (highest priority first, oldest first within priority)
2. Shared queue (same ordering)
3. Nothing → agent goes idle

**Item lifecycle:** `pending` → `claimed` → `active` → `completed` | `failed` | `cancelled`

**Claim mechanics:**
- Atomic claim with TTL (default 5 minutes)
- Background sweep resets expired claims to `pending`
- Only one instance can hold a claim at a time

### Schema

**`dispatch_items`** — Work queue:
- `queue_type` — agent or shared
- `agent_name` — target agent (null for shared)
- `work_type` — request, collaboration, review, custom
- `work_id` — e.g., REQUEST-jordan-0065
- `priority` — 0=normal, 10=high, 20=critical
- `status` — pending/claimed/active/completed/failed/cancelled
- `claimed_by`, `claim_expires_at` — claim tracking

**`dispatch_instances`** — Instance registry:
- `id` — session ID
- `agent_name`, `workstream`, `pid`
- `status` — active/idle/stopping/dead
- `last_heartbeat` — updated by statusline hook

### API Endpoints

```
POST /api/dispatch/enqueue           — Add work to queue
POST /api/dispatch/claim             — Claim next (agent-first, then shared)
POST /api/dispatch/release/:id       — Release back to pending
POST /api/dispatch/complete/:id      — Mark completed
POST /api/dispatch/fail/:id          — Mark failed
POST /api/dispatch/cancel/:id        — Cancel pending item
GET  /api/dispatch/next/:agentName   — Peek without claiming
GET  /api/dispatch/list              — List with filters
GET  /api/dispatch/get/:id           — Get specific item
GET  /api/dispatch/stats             — Queue statistics

POST /api/dispatch/instance/register         — Register instance
POST /api/dispatch/instance/heartbeat/:id    — Heartbeat
POST /api/dispatch/instance/deregister/:id   — Remove instance
POST /api/dispatch/instance/release-all/:id  — Release all claims
GET  /api/dispatch/instance/list             — List instances
```

### CLI Tool: `./agency/tools/dispatch`

```bash
./agency/tools/dispatch enqueue --agent captain "Fix bug" "Investigate the crash"
./agency/tools/dispatch enqueue --shared "Review PR" "Check PR #42" --priority 10
./agency/tools/dispatch enqueue --request REQUEST-jordan-0065 --agent captain
./agency/tools/dispatch claim                    # Claim next item
./agency/tools/dispatch complete <item-id>       # Mark done
./agency/tools/dispatch fail <item-id> "reason"  # Mark failed
./agency/tools/dispatch status                   # Queue depth
./agency/tools/dispatch list --status pending    # List items
./agency/tools/dispatch instances                # Active instances
```

Shortcut: `./agency/tools/dispatch-request REQUEST-jordan-0065 [--agent captain]`

## Hook Integration

| Hook | Action |
|------|--------|
| `session-start.sh` | Register instance, show unread messages + queued work |
| `session-end.sh` | Release claims, deregister instance |
| `stop-check.py` | Block stop if pending queue work exists |
| `statusline.sh` | Fire-and-forget heartbeat |

## Service Files

```
source/services/agency-service/src/embedded/
├── messages-service/           # Unified messaging
│   ├── index.ts               # Factory
│   ├── types.ts               # Message types, Zod schemas
│   ├── service/message.service.ts
│   ├── repository/message.repository.ts
│   └── routes/message.routes.ts
├── dispatch-service/           # Dispatch queue
│   ├── index.ts               # Factory
│   ├── types.ts               # Dispatch types, Zod schemas
│   ├── service/dispatch.service.ts
│   ├── repository/dispatch.repository.ts
│   └── routes/dispatch.routes.ts
```

## Standards Landscape

| Standard | Relevance | Phase |
|----------|-----------|-------|
| `CLAUDE_CODE_TASK_LIST_ID` | Native env var for shared task state | Future (Phase 5) |
| A2A (Agent-to-Agent) | Linux Foundation agent interop | Future (Phase 4) |
| MCP | Coordination layer for external clients | Future (Phase 3) |

## Future Phases

- **Phase 2:** External orchestrator using same HTTP APIs
- **Phase 3:** MCP servers exposing dispatch and messaging
- **Phase 4:** A2A compatibility layer
- **Phase 5:** Native Claude Code integration with Agent Teams
