---
type: handoff
agent: the-agency/jordan/devex
workstream: devex
date: 2026-04-07
trigger: principal requested handoff for exit/resume
---

## Identity

the-agency/jordan/devex — tech-lead on the devex workstream. I own test infrastructure, commit workflow, permission model, enforcement tooling, and context economics for TheAgency.

## Current State

Phase 1.1 (Universal Test Isolation) shipped last session — all 37 BATS files isolated. This session was brief: startup, investigation into the burning problem, then principal-requested handoff. No code changes.

Still awaiting captain's triage of MAR review findings (dispatch #99) and Valueflow plan approval before starting Phase 3.

## Artifacts

- **PVR:** `usr/jordan/devex/devex-pvr-20260406.md` (approved)
- **A&D:** `claude/workstreams/devex/devex-ad-20260407.md` (approved)
- **Plan:** `claude/workstreams/devex/devex-plan-20260407.md` (active)
- **Valueflow A&D:** `claude/workstreams/agency/valueflow-ad-20260406.md` (§4, §6, §9 assigned to DevEx)

## Investigation: commit-precheck / test-run (the burning problem)

Analyzed the full commit-time test execution chain:

1. **`commit-precheck`** classifies staged files via `has_app_code()` — checks for .ts/.js/.py/.rs etc.
2. **Bash tools (`claude/tools/*`) don't match** `has_app_code()`, so tool changes get NO test coverage in pre-commit. Any app code change triggers ALL 703 BATS tests (32 files).
3. **`test-run`** reads `agency.yaml` with a single suite: `bats tests/tools/` — runs everything, no scoping.
4. **No git pre-commit hook** — commit-precheck is invoked by Agency tooling, not git hooks.
5. **`git-commit`** does NOT call commit-precheck — it runs `git commit` directly.

### Fix needed (two parts):
- **Part A:** `has_app_code()` must recognize bash/shell scripts in `claude/tools/` as testable code
- **Part B:** Smart test scoping — map staged files to relevant test files:
  - `claude/tools/{name}` → `tests/tools/{name}.bats` + `tests/tools/{name}-*.bats`
  - `claude/tools/lib/{name}` → run all tests (conservative — libs are cross-cutting)
  - `tests/tools/{name}.bats` → run that test file directly
  - Non-tool files (docs, config, markdown) → skip tests (fast path)

## Key Decisions (A&D)

1. Universal test isolation with opt-out (`SKIP_ISOLATION=1`) — safety as default
2. `wc -w` token approximation for context budget linter — zero deps
3. Warn-only QGR check at pre-commit — `git-commit` tool does hard enforcement
4. Blocklist for stage classification — known code extensions trigger, rest skips

## Principal Feedback (CRITICAL — read every session)

**USE THE TOOLS AND SKILLS.** Do not hand-roll bash commands. Do not `cd` to main repo from worktree. Do not write files directly when a tool exists. Do not blame tools for failures you caused by running them wrong. Use `/handoff`, `/dispatch`, and the skill system. Run tools from the worktree CWD with relative paths — never `cd /Users/jdm/code/the-agency && ...`.

## Open Items

- 27 flags in queue (permissions friction, MAR process, conventions, seeds)
- Seeds to process: #29 (test boundaries), #31 (test reporting), #36 (permission model)
- BATS tests corrupt `.git/config` — happened 4+ times in Day 30 session
- Write DevEx PVR update if needed after Valueflow plan approval

## Next Action

1. Set dispatch loop: `/loop 5m dispatch check`
2. **Implement smart test scoping** for commit-precheck (investigation done, ready to implement)
3. Check if captain has triaged MAR findings and plan is approved
4. If approved: read seed dispatch, begin Phase 3.1 (QG tier definitions)
