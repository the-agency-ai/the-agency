---
type: handoff
agent: the-agency/jordan/iscp
workstream: iscp
date: 2026-04-07
trigger: principal requested exit — mid-bugfix on agent-identity
---

## Identity

`the-agency/jordan/iscp` -- ISCP workstream agent. I build and maintain the Inter-Session Communication Protocol: the notification, dispatch, and flag infrastructure that connects all agents.

## Current State

ISCP v1 complete and hardened. 174 BATS tests green. The iscp branch is behind main (main is 8 commits ahead).

## Last Session Work

Investigated and diagnosed a **critical identity resolution bug** in `agent-identity`. The tool resolves to `captain` instead of `iscp` when running on the iscp worktree. This cascades into handoff writing to the wrong path.

### Bug: agent-identity resolves wrong identity on worktrees

**Root cause chain:**
1. `CLAUDE_PROJECT_DIR` is unset in Bash tool calls (only set inside hooks)
2. No `.agency-agent` file existed in the iscp worktree (predates convention)
3. Fallback `SCRIPT_DIR/../..` (line 45) resolves to the **main checkout** root, not the worktree
4. Branch detection runs `git -C $PROJECT_ROOT` on main checkout → gets `main` → resolves to `captain`
5. Cache keyed by branch hash — hits the `main` → `captain` cache entry

**What I tried:**
- Created `.agency-agent` file in iscp worktree (`echo "iscp" > .claude/worktrees/iscp/.agency-agent`)
- Doesn't help — the tool reads `.agency-agent` from `$PROJECT_ROOT` which points to main checkout

**The fix needed** (not yet implemented):
- `agent-identity` line 42-46: When `CLAUDE_PROJECT_DIR` is unset, detect if `$PWD` is inside a git worktree and use that as `PROJECT_ROOT` instead of `SCRIPT_DIR/../..`
- Use `git rev-parse --show-toplevel` from `$PWD` — this returns the worktree root when run inside a worktree
- The `.agency-agent` file approach works IF `PROJECT_ROOT` points to the right place

**Cache state verified:**
- `~/.agency/the-agency/.agent-identity-1787558856` (hash of `main`) → `captain`
- `~/.agency/the-agency/.agent-identity-1942628320` (hash of `iscp`) → `iscp` (correct, but never hit)

### Dispatch status
- Dispatch #106 (escalation from devex re: secret tool) — addressed to captain, not me. Read it but not my action.
- All ISCP dispatches resolved.
- MAR review response dispatch #100 still awaiting captain triage.
- Flagged the identity bug as flag #33.

## Next Action

1. **Fix agent-identity** — replace SCRIPT_DIR fallback with `git rev-parse --show-toplevel` from PWD
2. **Verify fix** — run `agent-identity` from iscp worktree, confirm resolves to `the-agency/jordan/iscp`
3. **Test** — run `bats tests/tools/agent-identity.bats` to ensure no regressions
4. **Then:** Resume waiting for captain triage of dispatch #100 (V2 plan MAR review)

## Key Decisions

- `dispatch create` requires `--body` or explicit `--template`. No silent empty payloads.
- `agent-identity` checks `.agency-agent` file before branch detection. PR branches resolve to captain.
- Symlink-based dispatch payload resolution with legacy 4-strategy fallback.
- Commit dispatches carry structured metadata.

## Open Items

1. **agent-identity PROJECT_ROOT bug** (this session — IN PROGRESS)
2. **DB schema versioning** — migration framework for schema changes. Should be Phase 2.0.
3. **Flag categories** (`--friction`, `--idea`, `--bug`) — V2 Phase 2.3.
4. **Dispatch retention** — archive resolved dispatches after 30 days.
5. **BUG 2** — `dispatch list --all` shows other agents' unread mail.
6. **SMS-style dispatches** — principal requested. Not in V2 plan.

## Flags in Queue

26 items — see `flag list` for full queue. Untriaged.

## Startup Actions

1. Read this handoff
2. `dispatch list` / `flag list` — process unread items
3. **Fix agent-identity** — the bug described above. File: `claude/tools/agent-identity`, lines 42-46. Replace SCRIPT_DIR fallback with PWD-based git worktree detection.
4. Follow Next Action above
