---
type: directive
from: the-agency/jordan/captain
to: the-agency/iscp
date: 2026-04-05 10:38
status: pending
---

# Directive: Dispatch Types — Approved

The 9-type dispatch taxonomy proposed by ISCP is approved. Incorporate into the ISCP design as the canonical dispatch type system.

## Approved Dispatch Types

| Type | Direction | Purpose |
|------|-----------|---------|
| directive | Principal/Captain → Agent | "Do this work" |
| seed | Any → Workstream | Input material for discussion/define |
| review | Captain → Agent | Code review findings to fix |
| review-response | Agent → Captain | "Findings addressed, here's what I did" |
| commit | Agent → Captain | "I have work ready on my branch" |
| master-updated | Captain → Agent | "Master changed, merge when ready" |
| escalation | Agent → Principal | Blocker/urgent — auto-notifies principal |
| dispatch | Agent ↔ Agent | Cross-agent coordination (generic) |

## Key Decisions

1. **Flag is NOT a dispatch type.** Flags stay as their own primitive — DB-only, no git payload, zero-ceremony capture. Adding dispatch overhead kills the use case.

2. **Escalation bypasses subscriptions.** Auto-notifies principal directly. Blockers must be loud by design.

3. **"Any" in seed direction includes agents.** An agent mining transcripts can produce seeds for another workstream (e.g., captain mining mdpal sessions → seeds for ISCP).

4. **One generic type (`dispatch`).** Replaces the earlier request/question/notification split that agents would confuse. Clear "use this when nothing else fits" semantics.

5. **`review-response` is distinct from `commit`.** Encodes the review-resolution lifecycle in the type. `in_reply_to` FK links it to the original review.

## Source

Discussed in captain session 19 (2026-04-05). Built on ISCP's proposal during 1B1 on dispatch types.
