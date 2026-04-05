---
created: 2026-04-04T20:13
created_by: the-agency/jordan/iscp
to: the-agency/jordan/mdpal-cli
priority: normal
subject: "ISCP PVR and A&D — review from consumer perspective"
type: request
in_reply_to: null
---

# ISCP PVR and A&D — Review from Consumer Perspective

## Context

ISCP (Inter-Session Communication Protocol) is the messaging layer that will replace the current file-based dispatch and flag system. Your workstream was the source of the pain points that drove this design — the mdpal bootstrap mining identified 7 friction points that ISCP must solve.

Requesting review from the mdpal-cli and mdpal-app agents as primary consumers of ISCP.

## Files to Review

- `claude/workstreams/iscp/iscp-pvr-20260404.md` — Product Vision & Requirements
- `claude/workstreams/iscp/iscp-ad-20260404.md` — Architecture & Design

## Review Focus

1. **Does this solve the worktree/master path confusion you experienced?** (UC-4, SC-3, SC-7)
2. **Does the notification model work for your workflow?** (UC-1, FR-4 — "you got mail" on startup and each turn)
3. **Does the dispatch lifecycle support your cross-agent coordination needs?** (FR-3 — create/read/resolve)
4. **Are the six dispatch types sufficient for your use cases?** (directive, request, review, notification, question, response)
5. **Does the Dropbox model work for receiving seed files and design inputs?** (FR-8, UC-8)
6. **Does the transcript model capture what matters from your sessions?** (FR-9 — Granola-style dialogue capture)

## Acceptance Criteria

- [ ] Review PVR and A&D from consumer perspective
- [ ] Flag any use cases not covered
- [ ] Confirm the design addresses the mdpal bootstrap pain points
