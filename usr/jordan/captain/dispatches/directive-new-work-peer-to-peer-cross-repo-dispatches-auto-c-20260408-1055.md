---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-08T02:55
status: created
priority: normal
subject: "New work: peer-to-peer cross-repo dispatches + auto-CC to captains"
in_reply_to: null
---

# New work: peer-to-peer cross-repo dispatches + auto-CC to captains

# Peer-to-peer cross-repo dispatches + auto-CC to captains

Queue this as a new plan item in your Phase 2 sequence (after your current per-agent inboxes work). Plan-mode required, send plan to captain for review, execute after approval.

## Background

Currently, cross-repo dispatches flow captain → captain:

```
monofolk/jordan/devex
  → monofolk/jordan/captain (relay)
  → collab repo
  → the-agency/jordan/captain (relay)
  → the-agency/jordan/devex
```

Today's monofolk RFI (dispatch-rfi-spec-provider-spec-environment-20260407.md) literally says \"relaying for monofolk/jordan/devex\" — pure protocol overhead. Captains shouldn't be in the critical path.

Principal decision: **cross-repo goes peer-to-peer, with auto-CC to both captains for situational awareness.**

## The model

**Peer-to-peer delivery:**
- Any agent can send to any cross-repo address: `monofolk/jordan/devex → the-agency/jordan/devex`
- Collaboration tool permission expands: captain-only → all agents
- Primary recipient owns resolution

**Auto-CC to captains:**
- When a dispatch crosses repos, the collaboration tool auto-injects both captains into a `cc:` field
- CC'd captains get the dispatch in their `dispatch list` with a CC flag
- Captains can READ for awareness but cannot resolve (primary recipient owns lifecycle)
- Local (same-repo) dispatches are unchanged — no auto-CC

**Noise control:**
- `commit`-type dispatches **skip auto-CC by default** — too chatty, captains don't need every commit notification from the other repo
- Other types (directive/review/review-response/escalation/seed/dispatch/master-updated) auto-CC normally
- Captains can filter their loop: `dispatch list --status unread --exclude-cc` for critical-path only

## Implementation scope (yours)

1. **Schema bump: add `cc:` field to dispatch frontmatter**
   - Array of fully-qualified addresses
   - Backward compatible (empty/missing = no CC)
   - Schema version bump per ISCP Phase 2.0 framework
   - Migration path for existing dispatches (just leave them — cc is additive)

2. **Dispatch tool changes**
   - `dispatch list` shows CC column and supports `--cc-only` and `--exclude-cc` filters
   - `dispatch read` works for CC'd recipients (read is fine, state tracked per-recipient)
   - `dispatch resolve` FAILS for CC'd recipients — only primary can resolve
   - Reply-to semantics: CC'd recipients can send new dispatches but not reply in-thread (TBD in your plan)

3. **iscp-check notification**
   - Separate counts: \"2 unread, 3 cc\"
   - CC count does not block Stop hook (captains can exit with CC unread; can't exit with primary unread)

4. **Collaboration tool**
   - Permission model: remove captain-only restriction
   - Auto-CC injection: when writing a dispatch that crosses repos, inject both captains into cc: (unless type is commit)
   - Config: per-repo captain addresses resolved from agency.yaml

5. **Documentation**
   - Update claude/docs/ISCP-PROTOCOL.md with the cc model
   - Update claude/workstreams/iscp/iscp-reference-20260405.md
   - Cross-repo section in CLAUDE-THEAGENCY.md updated to reflect peer-to-peer
   - Leave README-ENFORCEMENT.md + hookify rule removal to devex (dispatched separately)

## What you own vs what devex owns

**iscp owns:**
- Schema, dispatch tool, iscp-check, collaboration tool behavior, protocol docs

**devex owns (separate dispatch):**
- Remove captain-only hookify guard on collaboration tool
- Update README-ENFORCEMENT.md enforcement table

## Acceptance

- Cross-repo dispatch from non-captain agent reaches primary recipient
- Both captains see the dispatch in their `dispatch list` marked CC
- Primary recipient can resolve; captains cannot resolve (error)
- `commit` type dispatches don't auto-CC
- BATS tests cover: peer-to-peer send, auto-CC injection, CC filter flags, resolve authorization, schema migration
- ISCP protocol doc updated

## Priority

Queue after your current per-agent inboxes work. This is structural cleanup, not urgent — but it's directly unblocking the captain-as-bottleneck friction we're hitting right now.

## Notes

- Don't start until your current Phase 2 iteration ships and you've sent commit notifications
- Plan-mode first: send plan to captain via review dispatch, wait for approval, then execute
- Expand-Migrate-Contract pattern applies: schema bump with PRAGMA user_version per Phase 2.0
- This is a good candidate to coordinate with devex on the hookify/docs edge before shipping

Good cleanup. Low risk, high clarity.
