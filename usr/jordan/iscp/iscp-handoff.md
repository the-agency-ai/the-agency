---
type: handoff
agent: the-agency/jordan/iscp
workstream: iscp
date: 2026-04-07
trigger: MAR review dispatch #95 completed — V2 plan ISCP perspective review sent as dispatch #100
---

## Identity

`the-agency/jordan/iscp` -- ISCP workstream agent. I build and maintain the Inter-Session Communication Protocol: the notification, dispatch, and flag infrastructure that connects all agents.

## Current State

ISCP v1 is complete and hardened. 174 BATS tests green. The iscp branch is fully merged into main -- zero unique commits on iscp, main is 8 commits ahead. Both the symlink commit (1e610fd) and structured commit dispatch (41fb5cf) are on main.

Full tool suite operational: `agent-identity`, `dispatch` (create/list/read/check/resolve/status/reply), `flag` (capture/list/count/discuss/clear/resolve), `iscp-check` (hook notification), `iscp-migrate` (legacy migration).

## Last Session Work

Completed MAR review of Valueflow V2 implementation plan (dispatch #95). Sent review-response as dispatch #100 to captain with 14 findings. Key findings:
- Iteration 2.1 (symlink merge) is already done -- reduce to verification step
- Iteration 2.4 (dispatch-on-commit) is partially implemented (41fb5cf)
- Dispatch authority role resolution mechanism undefined (finding #3)
- Review-response authority rule is inverted -- reviewers send responses, not authors (finding #4)
- DB schema versioning should be Phase 2.0, not part of 2.5 (finding #6)
- SMS-style dispatches and BUG 2 not in plan -- intentional? (findings #10, #11)
- Flag categories (2.3) must precede health metrics (2.5) for flag rate metrics (finding #12)

## Valueflow Context

- Plan: `claude/workstreams/agency/valueflow-plan-20260407.md`
- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

## Key Decisions

- `dispatch create` requires `--body` or explicit `--template`. No silent empty payloads.
- `agent-identity` checks `.agency-agent` file before branch detection. PR branches resolve to captain.
- `CLAUDE_PROJECT_DIR` is authoritative over `SCRIPT_DIR` for project root in all ISCP tools.
- Symlink-based dispatch payload resolution with legacy 4-strategy fallback.
- Commit dispatches carry structured metadata: commit_hash, branch, files_changed, stage_hash, work_item.

## Open Items

1. **DB schema versioning** -- migration framework for schema changes. Should be Phase 2.0 (prerequisite for flag categories and health metrics).
2. **Flag categories** (`--friction`, `--idea`, `--bug`) -- A&D Section 10. V2 Phase 2.3.
3. **Dispatch retention** -- archive resolved dispatches after 30 days. Not started.
4. **Dropbox primitive** -- file staging between worktrees. Not started.
5. **BUG 2** -- `dispatch list --all` shows other agents' unread mail. Not in V2 plan.
6. **SMS-style dispatches** -- principal requested. Not in V2 plan. Flag #1 in queue.
7. **Dispatch authority role resolution** -- design question raised in MAR review finding #3.

## Flags in Queue (4 items)

1. SMS-style dispatches (principal request)
2. Captain's log formalization
3. Friction-to-toolification pattern
4. Release notes on push

## Next Action

1. Await captain's triage of dispatch #100 (MAR review response)
2. When V2 plan is approved and seed dispatched, write ISCP workstream implementation plan at `claude/workstreams/iscp/iscp-valueflow-plan-20260407.md`
3. Start with DB schema versioning (Phase 2.0 / backlog item #1) -- it unblocks everything else
4. Fresh worktree from main recommended (existing iscp worktree has stale state)

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Follow Next Action above
