---
type: session
date: 2026-04-04 00:05
branch: main
trigger: session-end — plan complete, dispatch sent, morning kickoff plan
agent: the-agency/jordan/captain
---

# Captain Handoff

**Agent:** the-agency/jordan/captain
**Principal:** jordan
**Updated:** 2026-04-04 (session 17)

## Session 17 Summary

Massive session. Completed the entire **Agent Workspace & Bootstrap Quality** plan (5 phases, 17 iterations) plus handled monofolk dispatch and mdpal bootstrap.

### Agent Workspace & Bootstrap Quality Plan — COMPLETE

| Phase | Commits | What |
|-------|---------|------|
| 1 (1.1-1.3) | f19a510, baa542e, 89fb757 | agent-create modernization: stale paths, principal resolution, workspace scaffolding (tools/, tmp/, bootstrap handoff), registration template with startup directives + TODO guard |
| 2 (2.1-2.2) | 075f637 | workstream-create two-phase skill: Phase A deterministic scaffold, Phase B captain instruction output, --worktree/--scaffold-only flags, agent-create as single write path |
| 3+4 | f07229b | Hookify script persistence rule, tool-telemetry agent-script detection, safe-extract tool (unzip with path traversal + symlink validation), scoped permissions (unzip, worktree-sync, safe-extract), worktree-sync skill dispatch check |
| 5 | d05db3e | 37 new BATS tests across 5 files. Found + fixed 2 bugs: agent-create _pr_resolve was capturing stdout (sets env vars instead), safe-extract symlink detection had wrong gating condition |

**Artifacts:** PVR, A&D, Plan all in `usr/jordan/captain/` with `agent-workspace-` prefix, dated 20260403.

### mdpal Bootstrap

- Created mdpal worktree with per-agent handoffs (mdpal-cli, mdpal-app)
- Fixed session-handoff hook (main→captain mapping was missing)
- Fixed agency-init settings (replaced 95-line hardcoded heredoc with cp from settings-template.json)
- Added Read/Glob permissions for usr/**, claude/**, .claude/**
- Updated agent registrations with startup directives + "act on startup"

### DevEx Dispatch from Monofolk — RECEIVED + RESPONDED

Dispatch: `dispatch-devex-bootstrap-20260403.md` — 12 provider tools, topology-driven provisioning, 156 tests. This is where starter packs are going (starter packs never worked — this is the real provisioning model).

Responded with initial reactions on all 6 items: `dispatch-devex-bootstrap-ack-20260403.md`. Key positions:
- Starter packs never worked, clean break to provider catalog model
- Provider interface should be formalized as PROVIDER-SPEC.md
- Topology template variable collision risk (`{{...}}` also used in CLAUDE.md)
- No backward compat needed — no installed base
- Port window: 4-6 weeks after interface + format stable

**MISTAKE:** Pushed dispatch directly to main instead of via PR. Monofolk has no visible notification. Lesson saved to memory — cross-repo dispatches must go through PRs.

**NOTE:** Monofolk sent dispatch to OLD path (`claude/principals/jordan/projects/captain/dispatches/`). Told them to update to `usr/jordan/captain/dispatches/`.

### Discussion Decisions (DD1-DD3)

- **DD1:** Agent identity drives all disambiguation. Agent knows who it is → derives workstream → self-selects handoffs via naming convention. Tools enforce. No hook magic.
- **DD2:** workstream-create and agent-create are guided captain skills. Scaffold structure + TODO template, captain fills substance via /discuss.
- **DD3:** merge-main merges freely. Defense in depth: QG+MAR on main AND before PR. Principal in loop by exception via MAR escalation.

## Morning Kickoff Plan (2026-04-04)

### 1. Pull in mdpal worktree work
- Merge mdpal worktree into main (or sync-all)
- Review what the mdpal agents have done since bootstrap

### 2. Transcript mining — the-agency
- Mine captain session transcripts in `usr/jordan/captain/` for patterns, decisions, and knowledge that should be captured
- Look for recurring friction points, process improvements, tool gaps

### 3. Transcript mining — presence project
- Mine transcripts from `code/presence*/` (separate project directory)
- Extract patterns and learnings applicable to the-agency framework

### 4. DevEx /discuss (when ready)
- 6-item discussion queued from monofolk dispatch
- Wait for monofolk's response to our initial reactions first

## Git State

- **Branch:** `main`
- **HEAD:** `805380c` (in sync with origin after push)
- **Working tree:** clean (untracked: PDF, test artifacts cleaned)
- **Ahead of origin:** 0 commits (just pushed)

## Flag Queue

11 items from session 17 (run `./claude/tools/flag list` to see). Includes:
- Dispatch read/list tools across worktrees
- Transcript review automation
- Test isolation bug (BATS tests polluting INDEX.md and releases.md)
- Command audit
- Various tooling gaps

## Key Files Modified This Session

| File | Change |
|------|--------|
| `claude/tools/agent-create` | v2.0.0 — full rewrite (paths, scaffolding, registration, principal resolution fix) |
| `.claude/skills/workstream-create/SKILL.md` | Two-phase skill (scaffold + guided discussion) |
| `claude/hookify/hookify.warn-script-persistence.md` | NEW — script discipline nudge |
| `claude/hooks/tool-telemetry.sh` | Agent-script detection from usr/*/tools/ |
| `claude/tools/safe-extract` | NEW — unzip with path traversal + symlink validation |
| `claude/config/settings-template.json` | Added safe-extract, worktree-sync, scoped unzip, Read/Glob permissions |
| `.claude/settings.json` | Same permission additions |
| `.claude/skills/worktree-sync/SKILL.md` | Enhanced with dispatch check guidance |
| `tests/tools/agent-create.bats` | NEW — 13 tests |
| `tests/tools/session-handoff.bats` | NEW — 6 tests |
| `tests/tools/safe-extract.bats` | NEW — 10 tests |
| `tests/tools/settings-merge.bats` | Extended — 4 new tests (permissions, idempotency) |
| `tests/tools/worktree.bats` | Extended — 4 new tests (worktree-sync) |
