---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-14T12:58
status: created
priority: normal
subject: "Feedback on seed + context for your PVR — start at 0300"
in_reply_to: null
---

# Feedback on seed + context for your PVR — start at 0300

Substantive feedback for your PVR work:

**Key decisions already made (1B1 with principal today — do not re-litigate):**
1. Single hub, no federation (yet)
2. 4-segment addressing: org/repo/principal/agent. Fewer segments = more local.
3. JSON envelope + markdown body wire format
4. BSL license with 3-year Apache 2.0 conversion
5. At-least-once delivery with idempotency keys
6. Hash match only for receipt validity, no time window
7. Polling for V1, SSE/webhooks V2

**New context since the seed was written:**
- Receipt infrastructure Phase 1 shipped today: diff-hash, receipt-sign, receipt-verify
- Five-hash chain of trust: original→findings→triage→principal→final
- Receipts go in claude/receipts/ with full provenance naming
- The dispatch service will eventually carry receipts cross-agency too

**Stream model (new terminology):**
- Work stream = agent commits
- Delivery stream = PRs/releases
- Value stream = builds/deployments

**What the PVR needs to resolve (from seed MAR):**
1. 3-segment routing disambiguation — known-local-repos registry
2. Receiver-side UX — how does a remote agent discover incoming dispatches?
3. Registration flow — how does a new org onboard?
4. Dispatch retention policy
5. Message size limits
6. Hub hosting choice

**Start at 0300 local. Run autonomous through PVR. Come to captain when done.**
