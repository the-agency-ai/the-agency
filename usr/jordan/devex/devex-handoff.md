---
type: handoff
agent: the-agency/jordan/devex
workstream: devex
date: 2026-04-07
trigger: principal-requested pause
---

## Identity

the-agency/jordan/devex — tech-lead on the devex workstream. I own test infrastructure, commit workflow, permission model, enforcement tooling, and context economics for TheAgency.

## Current State

PVR approved (implicit). A&D written and approved — all 4 design decisions resolved. Plan written — 3 phases, 10 iterations. About to start Phase 1.1 (Universal Test Isolation). No implementation started yet.

## Artifacts

- **PVR:** `usr/jordan/devex/devex-pvr-20260406.md` (approved)
- **A&D:** `claude/workstreams/devex/devex-ad-20260407.md` (approved)
- **Plan:** `claude/workstreams/devex/devex-plan-20260407.md` (active)
- **Valueflow A&D:** `claude/workstreams/agency/valueflow-ad-20260406.md` (§4, §6, §9 assigned to DevEx)

## Key Decisions (A&D)

1. Universal test isolation with opt-out (`SKIP_ISOLATION=1`) — safety as default
2. `wc -w` token approximation for context budget linter — zero deps, V2
3. Warn-only QGR check at pre-commit — `git-commit` tool does hard enforcement
4. Blocklist for stage classification — known code extensions trigger, rest skips

## Dispatches

All dispatches resolved:
- #96 — MAR review of Valueflow V2 Plan. Sent review-response dispatch #101 with 13 findings.
- #76 — Polling tip. Resolved (use `dispatch check` not `dispatch list --status unread`).
- #36 — Permission model seed. Captured in Phase 3.1 + backlog.
- #31 — Test reporting service seed. Captured in backlog.
- #29 — Test boundary definitions seed. Already covered in A&D gate tiers. Resolved.

## Flags

4 flags in queue (SMS dispatches, captain's log, friction→toolification, release notes). Not blockers — seed material.

## Principal Feedback

**USE THE TOOLS AND SKILLS.** Principal was frustrated by hand-rolling bash commands and writing files directly instead of using dispatch skill, handoff tool, and agents. This is a pattern — fix it. Always use skills for dispatch ops, handoff tool for handoffs, agents for complex multi-step work.

## Next Action

Start Phase 1.1: Universal Test Isolation.
1. Read the 25 unprotected BATS files to understand what they need
2. Refactor `iscp_test_isolation_setup/teardown` into universal `test_isolation_setup/teardown`
3. Make `setup()` call isolation by default
4. Update all 25 files
5. Run all 32 BATS files to verify

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Check dispatches: `/dispatch check`
3. Check flags: `flag list`
4. Read plan: `claude/workstreams/devex/devex-plan-20260407.md`
5. Begin Phase 1.1 implementation
