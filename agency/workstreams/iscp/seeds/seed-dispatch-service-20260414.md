---
type: seed
project: dispatch-service
workstream: iscp
date: 2026-04-14
origin: captain/principal discussion — Day 40
mar: 4-agent review complete, 7 high-confidence findings incorporated
---

# Seed: Dispatch Service — Cloud-Hosted Agent Messaging

## The Problem

Two completely different dispatch mechanisms that don't match:

1. **Local ISCP** (SQLite) — fast, great UX, works for intra-agency messaging. Agents use `dispatch create/read/list/resolve`. Proven over 40 days of daily use.

2. **Collaborate** (git-file-based) — clunky. Requires writing markdown files, committing to a shared git repo, pushing, and the other side pulling. Different tool, different pattern, different mental model.

Inter-agency communication is second-class. Agents have to think about transport. This doesn't scale.

## The Vision

One cloud-hosted dispatch service that mirrors what ISCP does locally, but works across agencies. Same addressing scheme, same dispatch format, same tool interface. Agents use one tool — it routes automatically based on the address. Local, remote, broadcast — the agent doesn't care.

## Addressing Scheme

Hierarchical routing with local-first resolution:

| Segments | Format | Scope | Transport |
|----------|--------|-------|-----------|
| 1 | `agent` | Same principal, same repo, same org | Local ISCP |
| 2 | `principal/agent` | Same repo, same org | Local ISCP |
| 3 | `repo/principal/agent` | Same org, possibly different repo | Local or remote |
| 4 | `org/repo/principal/agent` | Fully qualified — cross-org | Remote (cloud) |

The fewer segments, the more local the assumption. Like DNS: unqualified names resolve locally, FQDNs route globally.

Current ISCP addressing (`the-agency/jordan/captain`) is 3-segment (repo level). Adding org gets the full 4-segment FQDN.

### 3-segment disambiguation (MAR finding)

3-segment addresses are ambiguous — could be local repo or remote. Resolution uses a **known-local-repos registry** (in agency config), not segment counting alone:

1. Parse the first segment as repo name
2. Check `claude/config/agency.yaml` for registered local repos
3. If repo is local → route via local ISCP
4. If repo is unknown → route via cloud service
5. If ambiguous → fail with actionable error, never guess

This is analogous to DNS search domains — known suffixes resolve locally.

## Architecture

### Single hub model

One cloud-hosted service. All agencies connect to the same hub. No federation (yet — could add later if needed).

### Components

1. **Cloud service** (Vercel or similar serverless) — REST API for dispatch lifecycle
   - POST `/dispatches` — send a dispatch (idempotency key required)
   - GET `/dispatches?to={address}&status=unread` — poll for dispatches
   - PATCH `/dispatches/{id}` — mark read/resolved
   - Authentication: scoped API tokens (see Security)

2. **Dispatch tool** (client, in the framework) — single tool that routes based on address
   - 1-2 segment address → local ISCP (SQLite, existing)
   - 3+ segment address → check known-local registry → route local or cloud
   - Agent never thinks about transport

3. **Local ISCP** (unchanged) — stays as the fast local backend. Cloud adds the remote layer on top.

### Wire format (MAR finding — resolved)

**JSON envelope with markdown body.** The envelope carries routing, metadata, and threading. The body stays markdown — same format agents write today. This enables schema validation, indexing, and clean API contracts while preserving the human-readable dispatch format.

```json
{
  "id": "uuid",
  "from": "org/repo/principal/agent",
  "to": "org/repo/principal/agent",
  "type": "dispatch",
  "priority": "normal",
  "subject": "...",
  "in_reply_to": "uuid-or-null",
  "idempotency_key": "client-generated-uuid",
  "body": "# Markdown dispatch content\n\n..."
}
```

### Delivery guarantees (MAR finding)

**At-least-once delivery** with client-side idempotency keys. The service deduplicates on idempotency key. Clients must handle potential duplicate reads gracefully (the resolve/read status lifecycle already handles this — reading an already-read dispatch is a no-op).

### Local fallback

If cloud is down, local ISCP continues working for intra-agency messaging. Remote dispatches are **not queued in V1** — the send fails with a clear error. Offline queuing is a V2 feature that requires queue persistence, sync ordering, and deduplication design. Scoping it out of V1 avoids underspecified behavior.

## Capabilities

### Current (what we have locally, mirrors to cloud)
- Create, read, list, resolve dispatches
- Priority levels (normal, high)
- Dispatch types (dispatch, directive, review, escalation, etc.)
- In-reply-to threading
- Status lifecycle (unread → read → resolved)

### New with cloud service
- **Multi-recipient** — send to multiple agents in one dispatch
- **Broadcast** — send to an entire agency (`org/repo/*`). Requires elevated scope (see Security).
- **Mixed routing** — one dispatch to both local and remote agents
- **Cross-org messaging** — `anthropic/the-agency/jordan/captain` ↔ `acme/their-project/alice/devex`

## Licensing

Open-source framework + hosted service (dual model):
- **Framework/client** — MIT (ships with the-agency)
- **Service component** — BSL (Business Source License) with 3-year conversion to Apache 2.0. Rationale: prevents competitors from immediately offering a competing hosted service while ensuring the code becomes fully open over time. Self-hosting for internal use is always permitted.

Decision criteria: must allow self-hosting, must prevent cloud resale without contribution, must eventually become fully open.

## Security

### Authentication (MAR finding — upgraded from API keys)

- **Per-org/repo scoped tokens** — not a single API key per agency. Tokens are scoped to `org/repo` and identify the calling principal.
- **Token lifecycle** — issuance, rotation, revocation supported
- **Short-lived tokens preferred** — JWTs with audience claim, refreshed periodically. Static API keys as fallback for simple setups.

### Authorization (MAR finding — tightened)

- Agents can only read dispatches where the `to` field matches their authenticated identity (full address match, not just org)
- **Broadcast send requires elevated scope** — a separate permission on the token. Not all agents can broadcast.
- Cross-org dispatch requires both orgs to be registered on the hub

### Encryption

- **On the wire:** TLS (HTTPS)
- **At rest:** Encrypted storage (AES-256 or equivalent)

### V2 security (parked)
- Message signing with sender's key (non-repudiation)
- Reply-chain authorization (validate participants can see parent)
- Data residency options

## Evolution Path

1. Cloud service for inter-agency (replaces collaborate)
2. Unified tool interface for intra + inter
3. Local-first remains the invariant — cloud is additive, never required for intra-agency
4. Collaborate tool deprecated and removed

## Replaces

- `claude/tools/collaboration` — git-file-based cross-repo dispatches
- Collaboration repos (`collaboration-monofolk`, etc.)
- Manual git commit/push/pull for inter-agency messaging

## V1 Scope

**In V1:**
- Cloud hub with REST API
- 4-segment addressing with known-local registry for 3-segment disambiguation
- JSON envelope / markdown body wire format
- At-least-once delivery with idempotency keys
- Per-org/repo scoped tokens
- Broadcast with elevated scope
- Polling for remote dispatch notification
- Local ISCP unchanged, remote sends fail if cloud is down

**Parked for V2:**
- Offline queue with sync (requires persistence + dedup design)
- SSE/webhooks for real-time remote notification
- Message signing / non-repudiation
- Rate limiting (beyond basic API gateway throttling)
- Federation between hubs
- Data residency
- Statusline integration with remote dispatch counts

## Open Questions (for PVR)

1. Dispatch retention policy — 30 days default? Configurable per org?
2. Message size limits — 64KB? 256KB?
3. Hub hosting — Vercel, Fly.io, Railway? (affects cold start, region, cost)
4. Registration flow — how does a new org onboard to the hub?
5. Receiver-side UX — how does a remote agent discover incoming dispatches? (polling interval, session-start check, statusline integration)

## MAR Summary

4-agent review (code, security, design, product). 25 total findings, 7 high-confidence incorporated:
1. 3-segment routing needs registry, not segment counting → added known-local-repos registry
2. Offline queue underspecified → scoped out of V1, explicit fail on cloud-down
3. Authorization too coarse → upgraded to per-org/repo scoped tokens
4. Delivery guarantees undefined → at-least-once with idempotency keys
5. Wire format must be decided → JSON envelope with markdown body
6. Service license needs criteria → BSL with 3-year Apache 2.0 conversion
7. Broadcast needs auth controls → elevated scope required
