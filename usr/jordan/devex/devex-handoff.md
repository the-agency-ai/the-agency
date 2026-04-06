---
type: handoff
agent: the-agency/jordan/devex
workstream: devex
date: 2026-04-06
trigger: reboot
---

## Identity

the-agency/jordan/devex — tech-lead on the devex workstream. I own test infrastructure, commit workflow, permission model, enforcement tooling, and context economics for TheAgency.

## Current State

New workstream, Day 1. Bootstrapped, reviewed Valueflow PVR and A&D, sent scope proposal. No implementation started. No DevEx PVR written yet — scope proposal (dispatch #47) was pre-PVR alignment.

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

Read the A&D on startup — it assigns work to DevEx: §4 enforcement ladder, §6 quality gates, §9 context budget linter.

## Active Work

Nothing in progress. Seed at `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md`. Scope proposal at dispatch #47. Captain received it but priority was Valueflow PVR/A&D. Now that those are done, DevEx work begins.

## Key Decisions

- T1 gate: stage-hash + compile + format + fast tests, **60s budget** (Valueflow A&D §6)
- Convention-based test scoping (path mirroring) as default, package-level fallback
- Enforcement registry: `claude/config/enforcement.yaml` + audit tool. **No registry without auditor — you build both.**
- Context budget linter: **Ships with CLAUDE-THEAGENCY.md decomposition or neither ships.**
- Hooks you implement: `WorktreeCreate`, `PostCompact`, `PermissionDenied`, conditional `if:`
- Permission model: settings-template audit, zero-prompt for safe ops — you own

## Open Items

- Seeds to process: #29 (test management boundaries), #31 (test reporting service), #36 (permission model overhaul)
- Dispatch #76 (polling tip from ISCP)
- Write DevEx PVR — use `/define` with the seed
- The burning problem: `claude/tools/commit-precheck` runs all 155 tests on every commit. Rewrite with smart scoping.
- BATS tests corrupt `.git/config` — happened 4+ times in Day 30 session

## Need Help?

If you're stuck or have a question, send a dispatch to captain: `dispatch create --to captain --subject "Question: ..." --body "..."`

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Read your seed: `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md`
6. Start `/define` to write the DevEx PVR
