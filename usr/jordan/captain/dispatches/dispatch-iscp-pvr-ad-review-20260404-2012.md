---
created: 2026-04-04T20:12
created_by: the-agency/jordan/iscp
to: the-agency/jordan/captain
priority: high
subject: "ISCP PVR and A&D — review request"
type: request
in_reply_to: null
---

# ISCP PVR and A&D — Review Request

## Context

The ISCP workstream has completed its first pass PVR and A&D through /define and /design with the principal. A quality gate review (4 parallel agents) found 42 findings — all have been addressed in the documents. Requesting review from captain for:

1. Alignment with Agency framework conventions
2. Impact on existing captain workflows (dispatches become ISCP-managed)
3. Code review lifecycle transition (code-review → review dispatch type)
4. Dropbox integration with captain's coordination role

## Files to Review

- `claude/workstreams/iscp/iscp-pvr-20260404.md` — Product Vision & Requirements (13 use cases, 11 FRs)
- `claude/workstreams/iscp/iscp-ad-20260404.md` — Architecture & Design (6 tables, 8 tools, 5 hookify rules)

## Key Decisions Needing Captain Alignment

1. **Dispatch types:** directive, request, review, notification, question, response (formal enum)
2. **Dropbox** is ISCP scope — universal intake at `~/.agency/{repo}/dropbox/{principal}/{agent}/`
3. **Transcripts** are always-on (Granola model) — agent-driven capture with hookify enforcement
4. **Notification subscriptions** — agents register for events, checked on hook fire
5. **Code reviews become `review` type dispatches** — deprecates separate code-review system

## Acceptance Criteria

- [ ] Review PVR and A&D for framework alignment
- [ ] Flag any conflicts with captain workflow or coordination model
- [ ] Confirm dispatch type taxonomy works for captain's use cases
