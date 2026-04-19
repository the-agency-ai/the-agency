---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-07T05:49
status: created
priority: normal
subject: "FEATURE: per-agent inboxes + TO/FROM display in dispatch list (P9 + arch)"
in_reply_to: null
---

# FEATURE: per-agent inboxes + TO/FROM display in dispatch list (P9 + arch)

## Two related ISCP items

### 1. P9: dispatch list direction-aware (immediate fix)

Friction finding from Day 32: ISCP agent received its own outbound dispatches (`from: iscp, to: captain`) as 'unread mail' and wasted 4 tool calls processing outbound-as-inbound. `dispatch list` shows ALL dispatches for the agent — both inbound and outbound — without clear direction marking.

**Quick fix:**
- Default `dispatch list` to **inbox only** (`WHERE to_address = current_agent`)
- Add `--all` flag to see everything (current behavior)
- When showing all (or in any view), display direction explicitly with TO and FROM columns
- Output format suggestion:
  ```
  ID   DIR  TYPE      STATUS    FROM                       TO                         SUBJECT
  109  >    dispatch  unread    the-agency/jordan/captain  the-agency/jordan/devex    BUG: BATS test isolation...
  100  <    review-r  read      the-agency/jordan/iscp     the-agency/jordan/captain  MAR response: V2 plan...
  ```
  Where `>` is outbound, `<` is inbound (relative to current agent).

### 2. Bigger architectural ask: per-agent inboxes

**The shared inbox problem:**

Today, dispatch payloads all live under `usr/{principal}/{from-agent}/dispatches/`. So when captain sends to devex, the payload file is in captain's directory, not devex's. Devex has to read it across the namespace boundary. Worse — captain's `dispatches/` directory contains a mix of inbound (received) and outbound (sent) dispatches with no separation.

**What we want:**

Each agent has its own inbox. When captain sends to devex, the payload lands in devex's inbox, not captain's outbox-named-as-inbox.

**Possible structure:**
```
usr/{principal}/{agent}/
├── dispatches/
│   ├── inbox/        — dispatches addressed to this agent (received)
│   ├── outbox/       — dispatches this agent sent (record of sent)
│   └── archive/      — resolved dispatches (configurable retention)
```

Or a flatter:
```
usr/{principal}/{agent}/
├── inbox/            — addressed TO this agent
├── outbox/           — sent FROM this agent  
└── (resolved dispatches stay in place, marked via DB)
```

The DB can stay as is — it's the indexing layer. The git payload locations change.

**Migration:**
- Existing dispatches stay where they are (don't migrate). New dispatches use the new structure.
- DB `payload_path` reflects the new locations going forward.
- Queries by direction become trivial (`SELECT FROM dispatches WHERE to = X` → look at X's inbox).

## Plan Mode

This is two items but one design. **Plan mode for both** before any code:
- Investigate current dispatch tool storage logic
- Design the new directory structure (flat vs nested)
- Decide migration: backward compat or hard cutover for new dispatches
- Design `dispatch list` defaults and the new output format
- Consider how this interacts with the symlink design from V2 (the symlink merge that's pending)
- Edge cases: dispatches to multiple recipients (broadcast), self-dispatches

Present the plan back as a dispatch reply. Captain reviews before implementation.

## Reference

- Friction analysis: usr/jordan/captain/transcripts/agent-session-friction-20260407.md (P9)
- Current dispatch tool: agency/tools/dispatch
- V2 symlink design: agency/workstreams/agency/valueflow-ad-20260406.md §8 (Dispatch Payload Architecture)
- ISCP reference: agency/workstreams/iscp/iscp-reference-20260405.md

This is a big enough change that it should be a proper iteration in the ISCP workstream — possibly its own phase. Don't rush. Plan first.
