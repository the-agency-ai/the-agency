---
type: handoff
agent: the-agency/jordan/iscp
workstream: iscp
date: 2026-04-06
trigger: reboot
---

## Identity

the-agency/jordan/iscp — ISCP agent. Owns the inter-session communication protocol: dispatches, flags, agent identity, notification hooks. The messaging backbone.

## Current State

ISCP v1 is shipped and hardened. 174 BATS tests green. All escalations from Day 30 resolved. Branch `iscp` is merged to main.

Key commits this cycle:
- Dispatch `fetch` + `reply` subcommands + default branch detection
- Branch/worktree transparent payload resolution (4-strategy ladder)
- Hermetic test isolation (`ISCP_DB_PATH`, git config guards)
- Docker test runner
- Template placeholder warning in `dispatch create`
- `dispatch create` requires `--body` (no more empty templates)
- Agent identity PR branch fix (`captain/*` → captain)
- Worktree identity fix (`CLAUDE_PROJECT_DIR` over `SCRIPT_DIR`)
- Symlink-based dispatch payloads (`~/.agency/{repo}/dispatches/`)
- Structured commit dispatch payloads with metadata
- Settings-template ISCP hooks/permissions

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

You reviewed both PVR and A&D. Your verdict: "ready for planning." Read the A&D on startup — it defines how you work.

## Active Work

No active implementation work. Awaiting V2 plan with your assignments. Known backlog:
- Dropbox primitive (deferred — file staging between worktrees)
- Transcript primitive (storage/indexing layer)
- Flag triage skill (seed received, `claude/workstreams/iscp/seeds/seed-flag-triage-workflow-20260406.md`)
- Subscription primitive (not yet discussed)
- DB schema versioning strategy (A&D §8 references)
- Dispatch retention policy (30-day archive mechanism)
- Symlink reconstruction on fresh clone

## Key Decisions

- Dispatch payloads: symlinks in `~/.agency/{repo}/dispatches/` pointing to git artifacts (principal decision)
- MAR triage: free-form V2, structured schema V3. YAML frontmatter for metrics.
- MARFI: subagents V2, dispatches V3. Output to seeds/ for durability.
- Commit dispatch: structured YAML (commit_hash, stage_hash, branch, phase, iteration, files_changed)
- Flag categories: `--friction`, `--idea`, `--bug` as optional enrichment. Bare `flag "msg"` remains default.

## Open Items

- Seeds to process: #29 (test management), #31 (test reporting), #36 (permission model) — addressed to devex, not you
- Unread dispatches: check `dispatch list` on startup

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Await V2 plan assignments from captain
