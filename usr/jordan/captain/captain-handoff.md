---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-07
trigger: Day 31 session — collaboration tooling shipped
---

## Identity

the-agency/jordan/captain — Captain. Coordination, dispatch routing, quality gates, PR lifecycle. First up, last down.

## Current State

**Day 31.** Session focused on cross-repo collaboration tooling and commit-precheck bug fix. All shipped and pushed to origin. Monofolk notified via collaboration repo dispatches.

### What shipped Day 31:
- `claude/tools/collaboration` (v2.0.0) — cross-repo dispatch lifecycle tool (check, list, read, resolve, reply, push)
- `/collaborate` skill — captain-only
- `hookify.warn-external-paths.md` — blocks raw bash touching collaboration repos
- `agency.yaml` collaboration.repos config section
- SessionStart hook fires `collaboration check`
- `CLAUDE-CAPTAIN.md` — agent-scoped instructions with cross-repo protocol
- Captain startup sequence updated (step 4: cross-repo check)
- `commit-precheck` fix — fast path for non-app-code commits, timeouts on all steps
- Monofolk dispatches: replied to ISCP setup guidance + Synthoid proposal, sent release notes

### commit-precheck fix (affects all agents):
Bug: test-run and code-review ran on every commit including tooling-only changes, hanging indefinitely. Fix: `has_app_code()` classifies staged files — non-app-code skips steps 4+5. All steps have timeouts (30-120s).

## Valueflow Context

Unchanged from Day 30. V2 implementation plan is the next major deliverable.
- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

## Active Work

**Next: write the Valueflow V2 implementation plan.** Same as Day 30 handoff — deferred by the collaboration tooling work today.

## Agents

| Agent | Worktree | Status | Next action |
|-------|----------|--------|-------------|
| iscp | `.claude/worktrees/iscp/` | Idle, awaiting V2 assignments | Process seeds, await plan |
| devex | `.claude/worktrees/devex/` | Day 1, needs PVR | `/define` with seed, then implement |
| mdpal-cli | `.claude/worktrees/mdpal-cli/` | Phase 1, iter 1.1 code done | `/iteration-complete`, then 1.2 |
| mdpal-app | `.claude/worktrees/mdpal-app/` | Phase 1A in progress | Continue SwiftUI implementation |
| mock-and-mark | (no worktree yet) | Not started | Awaiting seed + principal direction |

## Flags (3 pending)

1. SMS-style dispatches — short DB-only dispatches without payload files (from Day 30)
2. Friction→toolification process — formalize the pattern of recognizing session friction and building tools/skills/hookify in-session
3. Release notes dispatch process — every push to origin gets a release-notes dispatch to collaboration repos, integrated into /sync or /ship

## Cross-Repo Collaboration

Collaboration repos configured in `agency.yaml`. Tool: `./claude/tools/collaboration`. Monofolk has 3 pending dispatches from us (2 replies + release notes).

### Monofolk inbound (resolved):
- ISCP setup guidance request — replied, full guidance dispatch still owed
- Synthoid proposal — replied, routing decision pending principal input

## Startup Actions

1. Read this handoff
2. Set dispatch loop: `/loop 5m dispatch check`
3. Check ISCP: `dispatch list` and `flag list`
4. Check cross-repo: `./claude/tools/collaboration check`
5. Read role: `claude/agents/captain/agent.md`
6. Write the V2 implementation plan
