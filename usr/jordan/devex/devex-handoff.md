---
type: handoff
agent: the-agency/jordan/devex
workstream: devex
date: 2026-04-06
trigger: reboot
---

## Identity

the-agency/jordan/devex — DevEx agent. Owns test infrastructure, commit workflow, permission model, tooling ergonomics. Your work affects every agent — a broken pre-commit blocks everyone.

## Current State

New workstream, Day 1. You bootstrapped, sent a scope proposal (dispatch #47), reviewed the Valueflow PVR (dispatch #64, 9 findings) and A&D (dispatch #91, 10 findings). No implementation work started yet. PVR not yet written for DevEx — scope proposal was the pre-PVR alignment.

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

Read the A&D — many sections directly assign work to you (§4 enforcement ladder, §6 quality gates, §9 context budget linter).

## Active Work

Nothing in progress. Your seed is at `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md`. Your scope proposal is at dispatch #47 payload. Captain received it but the priority was valueflow PVR/A&D. Now that those are done, DevEx work begins.

## Key Decisions (from valueflow A&D, affecting you)

- T1 gate: stage-hash + compile + format + fast tests, **60s budget**
- Convention-based test scoping (path mirroring) as default, package-level fallback
- Enforcement registry: `claude/config/enforcement.yaml` + audit tool. **No registry without auditor — you build both.**
- Context budget linter: V2 deliverable. **Ships with CLAUDE-THEAGENCY.md decomposition or neither ships.**
- `WorktreeCreate` hook: auto-register agents — you implement
- `PostCompact` hook: re-inject handoff — you implement
- `PermissionDenied` hook: auto-retry safe commands — you implement
- Conditional `if:` on hooks: reduce overhead — you implement
- `effort:` levels on all skills: you audit and set
- Permission model: settings-template audit, zero-prompt for safe ops — you own

## Open Items

- Seeds to process: #29 (test management boundaries), #31 (test reporting service), #36 (permission model overhaul)
- Dispatch #76 (polling tip from ISCP)
- Write DevEx PVR — use `/define` with the seed
- The burning problem: `claude/tools/commit-precheck` runs all 155 tests on every commit. Rewrite with smart scoping.
- BATS tests corrupt `.git/config` — happened 4+ times in Day 30 session

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Read your seed: `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md`
6. Start `/define` to write the DevEx PVR
