---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/captain
date: 2026-04-06T06:08
status: created
priority: normal
subject: "DevEx PVR: scope proposal — test infra, commit workflow, permissions"
in_reply_to: null
---

# DevEx PVR: scope proposal — test infra, commit workflow, permissions

# DevEx PVR: Scope Proposal

## Problem Statement

TheAgency's developer experience is broken at the commit boundary. The pre-commit hook runs all 155 tests (32 BATS files) on every commit — including markdown-only changes. It times out, forces `--no-verify`, which bypasses QGR enforcement. Tests that DO run can corrupt the live environment (.git/config, ISCP DB, working directory debris). Meanwhile, settings-template.json ships too few permissions, so agents prompt for safe operations constantly.

This was exposed during the ISCP rollout (2026-04-05/06) when captain operations were blocked twice in one session by test corruption. The problems compound as more agents come online.

## Proposed Scope

**In scope:**
- **Test infrastructure** — extend ISCP isolation pattern to all 32 BATS files, fix working directory pollution, Docker runner for full suite
- **Commit workflow** — pre-commit hook rewrite: smart test scoping (changed-file detection), skip tests for non-code changes, timeout with graceful degradation, never run host-corrupting tests from pre-commit
- **Permission model** — audit settings-template.json, pre-approve all non-destructive operations, zero-prompt goal for safe ops
- **Tooling ergonomics** — friction reduction across agent bootstrap and daily operations

**Not in scope (for now):**
- CI/CD pipeline (no CI infrastructure yet)
- Agent lifecycle management (T4 — bigger design question, separate workstream)
- Claude Code behavioral issues (C1, C2 — Anthropic's domain)
- agency-init rewrite (B1 — related but its own workstream candidate)

## Proposed Phasing

1. **Phase 1: Pre-commit + isolation** — the burning problem. Rewrite commit-precheck, extend isolation to all BATS files.
2. **Phase 2: Docker full suite** — make docker-test.sh run all 32 files, integrate into workflow.
3. **Phase 3: Permission model** — settings-template audit, zero-prompt verification.

## Source Materials

- Seed: agency/workstreams/devex/seeds/seed-devex-kickoff-20260406.md
- Friction points: usr/jordan/captain/friction-points-20260405.md (T3, T5, P1-P5)
- Existing code: tests/tools/test_helper.bash, tests/Dockerfile, tests/docker-test.sh, agency/tools/commit-precheck

## Request

Review scope and phasing. Flag anything missing or misscoped. I'll draft the full PVR once scope is aligned.
