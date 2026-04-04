---
type: session-handoff
date: 2026-04-04
trigger: SessionEnd — PVR, A&D, Plan complete
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Session Handoff

**Agent:** the-agency/jordan/iscp
**Branch:** iscp (worktree at `.claude/worktrees/iscp/`)
**Last commit:** `ef7cef0` Phase 1.1: ISCP plan — 7 phases, 22 iterations

## Current State

PVR, A&D, and Plan are complete. QG passed (42 findings, all fixed). Dispatches sent to captain and mdpal for review. Ready to implement.

**Phase 1, Iteration 1.1 (design) is done.** Next: Iteration 1.2 (`_iscp-db` library).

## Key Decisions (all resolved with principal)

1. **DB location:** `~/.agency/{repo-name}/iscp.db` — outside git, centralized under home dir
2. **Hook triggers:** SessionStart + UserPromptSubmit — cheap check, silent when empty, one-line "you got mail" when not
3. **Dispatch types:** 7-type formal enum — directive, request, review, notification, question, response, escalation
4. **Dropbox:** Universal intake at `~/.agency/{repo}/dropbox/{principal}/{agent}/` — outside git, goal state empty, `dropbox forward` for captain rerouting
5. **Transcripts:** Always-on Granola model — hook captures user input, hookify enforces agent self-reporting (actual response, NOT summary), staleness warning at 5 turns, all transcript tool output silent to principal
6. **Subscriptions:** Principal-scoped with captain repo-wide exception. Escalations auto-notify principal.
7. **Transcript size:** One file per session, no rotation. ~200KB is nothing.

## Next Action

Start **Phase 1, Iteration 1.2: `_iscp-db` library**

1. Create `claude/tools/lib/_iscp-db`
2. DB path resolution with repo name sanitization
3. Schema creation (all 6 tables, idempotent)
4. Named parameter handling via `.param set`
5. BATS tests

See plan: `claude/workstreams/iscp/iscp-plan-20260404.md`

## Key Files

| File | What |
|------|------|
| `claude/workstreams/iscp/iscp-pvr-20260404.md` | PVR — 13 UCs, 11 FRs, 7 NFRs |
| `claude/workstreams/iscp/iscp-ad-20260404.md` | A&D — 6 tables, 8 tools, 7 hookify rules |
| `claude/workstreams/iscp/iscp-plan-20260404.md` | Plan — 7 phases, 22 iterations |
| `usr/jordan/iscp/qgr-iteration-complete-1-1-3c35ba7-20260404-2020.md` | QGR for design phase |

## Pending Dispatches (awaiting responses)

- `usr/jordan/captain/dispatches/dispatch-iscp-pvr-ad-review-20260404-2012.md` — captain review
- `usr/jordan/mdpal/dispatches/dispatch-iscp-pvr-ad-review-20260404-2013.md` — mdpal consumer review

## Known Issues

- `dispatch-create` tool has `AGENCY_PRINCIPAL` env leak bug — resolves to `testuser`. Fix is Phase 1 prerequisite (Iteration 1.3 patches `_address-parse`).
- `handoff` tool has the same env leak — wrote to wrong path. Manual handoff this session.
- Main checkout has stale copies of PVR/A&D from before worktree copy. Canonical versions are on the iscp branch.
