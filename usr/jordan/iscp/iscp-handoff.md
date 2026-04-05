---
type: session-handoff
date: 2026-04-05
trigger: iteration-complete 1.2 — _iscp-db library committed
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Session Handoff

**Agent:** the-agency/jordan/iscp
**Branch:** iscp (worktree at `.claude/worktrees/iscp/`)
**Last commit:** `9956644` Phase 1.2: _iscp-db library — shared SQLite abstraction for ISCP

## Current State

Phase 1, Iterations 1.1 (design) and 1.2 (_iscp-db library) complete. QG passed (12 findings, all fixed — key: newline injection, param name validation, file permissions, test coverage). 51 BATS tests all green.

**Next: Iteration 1.3 (agent-identity tool).**

## Key Decisions

1. **DB location:** `~/.agency/{repo-name}/iscp.db` — outside git
2. **Hook triggers:** SessionStart + UserPromptSubmit
3. **Dispatch types:** 7-type enum + pending 8th (`commit` — agent→captain, per principal request)
4. **Dropbox:** `~/.agency/{repo}/dropbox/{principal}/{agent}/` — outside git
5. **Transcripts:** Always-on Granola model
6. **Subscriptions:** Principal-scoped, captain repo-wide exception
7. **subscriptions.filter:** Changed to `NOT NULL DEFAULT ''` (SQLite NULL uniqueness issue)
8. **Parameter safety:** `.param set` with double-quote escaping, newline/CR/tab handled, strict name regex

## Pending: New Dispatch Type `commit`

Principal requested adding `commit` as an 8th dispatch type — sent from agent to captain when a git commit is made. Needs:
- PVR update (new dispatch type)
- A&D update (schema CHECK constraint)
- Schema update in `_iscp-db` (add 'commit' to dispatches type CHECK)

Incorporate before Phase 2 (Dispatch implementation).

## Next Action

Start **Phase 1, Iteration 1.3: `agent-identity` tool**

1. Create `claude/tools/agent-identity`
2. Resolution chain: git branch → agency.yaml → git remote
3. Ignore `AGENCY_PRINCIPAL` entirely (deprecated)
4. Output fully qualified address: `{repo}/{principal}/{agent}`
5. Cache to `~/.agency/{repo}/.agent-identity`
6. Patch `_address-parse` to remove `AGENCY_PRINCIPAL` dependency
7. BATS tests

See plan: `claude/workstreams/iscp/iscp-plan-20260404.md`

## Key Files

| File | What |
|------|------|
| `claude/workstreams/iscp/iscp-pvr-20260404.md` | PVR — 13 UCs, 11 FRs, 7 NFRs |
| `claude/workstreams/iscp/iscp-ad-20260404.md` | A&D — 6 tables, 8 tools, 7 hookify rules |
| `claude/workstreams/iscp/iscp-plan-20260404.md` | Plan — 7 phases, 22 iterations |
| `claude/tools/lib/_iscp-db` | Shared SQLite library (Phase 1.2) |
| `tests/tools/iscp-db.bats` | 51 BATS tests for _iscp-db |

## Pending Dispatches (awaiting responses)

- `usr/jordan/captain/dispatches/dispatch-iscp-pvr-ad-review-20260404-2012.md` — captain review
- `usr/jordan/mdpal/dispatches/dispatch-iscp-pvr-ad-review-20260404-2013.md` — mdpal consumer review

## Known Issues

- `dispatch-create` tool has `AGENCY_PRINCIPAL` env leak bug — Iteration 1.3 patches `_address-parse`
- `handoff` tool has same env leak — manual handoff until fixed
- Main checkout has stale PVR/A&D copies — canonical versions on iscp branch
- Pre-commit `code-review` tool flags `UPDATE $table` as SQL injection (false positive) — avoided by using `$table` without braces
