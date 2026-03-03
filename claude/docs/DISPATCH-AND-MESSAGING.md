# Dispatch & Unified Messaging

Architecture documentation for the Agent Dispatch and Unified Messaging systems.

## Overview

Two complementary services built into agency-service:

1. **Unified Messaging** — Direct messages and broadcasts between agents, replacing collaboration files, NEWS.md, and the old messages.db
2. **Dispatch Queue** — Work queue with tiered pickup (agent-specific → shared), claim mechanics, and instance registry

Both are embedded services within `agency-service` at port 3141.

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

### CLI Tool: `./tools/msg`

```bash
./tools/msg send research "Review needed" "Please check the PR"
./tools/msg send captain "Re: Review" "Looks good" --ref <msg-id>
./tools/msg broadcast "Convention change" "Use explicit operations"
./tools/msg read                    # Unread messages
./tools/msg read --all              # All messages
./tools/msg thread <msg-id>         # Message chain
./tools/msg ack <msg-id>            # Mark as read
```

### Migration from Old Systems

| Old System | New Equivalent | Notes |
|------------|----------------|-------|
| `./tools/collaborate` | `./tools/msg send <agent> "subject" "body"` | Wrapper delegates to msg |
| `./tools/collaboration-respond` | `./tools/msg send <agent> "Re: subject" "body" --ref <id>` | Old file format retired |
| `./tools/news-post` | `./tools/msg broadcast "subject" "body"` | Wrapper delegates to msg |
| `./tools/news-read` | `./tools/msg read` | Falls back to legacy if service down |
| `./tools/message-send` | `./tools/msg send` | Wrapper delegates to msg |
| `./tools/message-read` | `./tools/msg read` | Wrapper delegates to msg |

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

### CLI Tool: `./tools/dispatch`

```bash
./tools/dispatch enqueue --agent captain "Fix bug" "Investigate the crash"
./tools/dispatch enqueue --shared "Review PR" "Check PR #42" --priority 10
./tools/dispatch enqueue --request REQUEST-jordan-0065 --agent captain
./tools/dispatch claim                    # Claim next item
./tools/dispatch complete <item-id>       # Mark done
./tools/dispatch fail <item-id> "reason"  # Mark failed
./tools/dispatch status                   # Queue depth
./tools/dispatch list --status pending    # List items
./tools/dispatch instances                # Active instances
```

Shortcut: `./tools/dispatch-request REQUEST-jordan-0065 [--agent captain]`

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
