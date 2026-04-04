---
type: session-handoff
date: 2026-04-04
trigger: SessionEnd — PVR and A&D complete with QG
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Session Handoff

**Agent:** the-agency/jordan/iscp
**Branch:** iscp (worktree at `.claude/worktrees/iscp/`)
**Last commit:** `a24c9fa` Phase 1.1: ISCP PVR and A&D — first pass with QG

## What Was Done

1. **PVR completed** via /define — 8-item 1B1 discussion with principal:
   - DB path: `~/.agency/{repo-name}/iscp.db` (outside git, centralized)
   - Hook triggers: SessionStart + UserPromptSubmit (cheap check, silent when empty)
   - Dispatch types: 6-type formal enum (directive, request, review, notification, question, response)
   - Success criteria: 7 items including SC-7 (enforcement triangle on payload routing)
   - Non-goals: 6 items (no chat, no pub/sub, no GUI, no cross-machine v1)
   - Dropbox: in ISCP scope as universal intake at `~/.agency/{repo}/dropbox/{principal}/{agent}/`
   - Transcripts: always-on (Granola model), dialogue-only, agent-driven capture with hookify enforcement
   - Notification subscriptions: agents register for events, checked on hook fire

2. **A&D drafted** — 6 tables, 8 tools, 7 hookify rules, 6 trade-offs, review-resolution lifecycle

3. **Quality gate run** — 4 parallel review agents found 42 findings (3 critical, all fixed):
   - F1: `$CLAUDE_AGENT_NAME` doesn't exist → created `agent-identity` tool
   - F2: Transcript capture gap → two-layer hook+hookify approach
   - F3: sqlite3 `?` params don't work → named parameters via `.param set`

4. **Captain + mdpal consumer reviews** — dispatched and findings incorporated:
   - Review-resolution lifecycle documented (6-step audit trail)
   - Outbox tracking added (`dispatch list --from`)
   - SessionStart hookify rule (act now, not later)
   - Transcript fidelity ("actual response, not summary")
   - `AGENCY_PRINCIPAL` explicitly deprecated

5. **Dispatches sent** to captain and mdpal for review (in git, awaiting their sessions)

## What's Next

1. **Discuss remaining items with principal** (5 items from QG):
   - Escalation dispatch type (add or defer?)
   - Dropbox forwarding (`dropbox forward --to <agent>`)
   - Subscription scope for captain (cross-principal visibility)
   - Transcript staleness threshold (5 turns?)
   - Open tech questions: transcript rotation, performance test methodology

2. **Build the Plan** — phases and iterations after A&D discussion resolves

3. **Await dispatch responses** from captain and mdpal agents

## Key Files

- PVR: `claude/workstreams/iscp/iscp-pvr-20260404.md`
- A&D: `claude/workstreams/iscp/iscp-ad-20260404.md`
- QGR: `usr/jordan/iscp/qgr-iteration-complete-1-1-3c35ba7-20260404-2020.md`
- Captain dispatch: `usr/jordan/captain/dispatches/dispatch-iscp-pvr-ad-review-20260404-2012.md`
- mdpal dispatch: `usr/jordan/mdpal/dispatches/dispatch-iscp-pvr-ad-review-20260404-2013.md`

## Known Issues

- `dispatch-create` tool has the `AGENCY_PRINCIPAL` env leak bug — resolved to `testuser` instead of `jordan`. Had to create dispatches manually. Fix is ISCP Phase 1 prerequisite.
- Worktree path confusion: wrote PVR/A&D to main checkout initially instead of worktree. Had to copy. Exactly the problem ISCP solves.
- PVR also exists at main checkout path (`/Users/jdm/code/the-agency/claude/workstreams/iscp/`) — stale copy from before worktree copy. The canonical version is on the iscp branch.
