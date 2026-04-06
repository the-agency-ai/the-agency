# Handoff: devex — Bootstrap

---
type: agency-bootstrap
date: 2026-04-06 01:20
principal: jordan
agent: the-agency/jordan/devex
workstream: devex
---

## Who You Are

DevEx agent for TheAgency. You own test infrastructure, commit workflow, permission model, and tooling ergonomics. Your work directly impacts every agent and principal in the repo — a broken pre-commit hook blocks everyone.

## Current State

**New workstream.** No PVR, A&D, or Plan yet. You have a seed document and existing code from the ISCP agent to build on.

### What exists (ISCP built)

- `tests/tools/test_helper.bash` — shared BATS isolation helpers (iscp_test_isolation_setup/teardown)
- `tests/Dockerfile` + `tests/docker-test.sh` — Docker test runner (ISCP tests only, manual)
- `claude/tools/lib/_iscp-db` — `ISCP_DB_PATH` env var for DB isolation
- 7 of 32 BATS test files have isolation helpers
- 155 tests green

### What's broken (the burning problem)

- Pre-commit hook (`claude/tools/commit-precheck`) runs ALL 32 BATS files for ANY change including markdown
- Times out, blocks commits for minutes, forces `--no-verify`
- BATS tests still leak debris into working directory (testname dirs, injection test artifacts)
- 25 of 32 BATS test files have NO isolation
- Docker runner only covers 7 ISCP test files

## Key Files

| File | What |
|------|------|
| `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md` | **READ THIS FIRST** — full problem statement, what ISCP built, what you need to build |
| `usr/jordan/captain/friction-points-20260405.md` | 15 friction points across 4 categories — your backlog |
| `tests/tools/test_helper.bash` | ISCP's isolation helpers — your foundation |
| `tests/Dockerfile` | Docker test container |
| `tests/docker-test.sh` | Docker test runner (ISCP-only) |
| `claude/tools/commit-precheck` | Pre-commit hook logic — NEEDS REWRITE |

## Next Action

1. Read the seed: `claude/workstreams/devex/seeds/seed-devex-kickoff-20260406.md`
2. Read the friction points: `usr/jordan/captain/friction-points-20260405.md`
3. Read ISCP's test isolation code: `tests/tools/test_helper.bash`, `tests/Dockerfile`, `tests/docker-test.sh`
4. Read the current pre-commit hook: `claude/tools/commit-precheck`
5. Start `/discuss` with Jordan on the seed — drive toward a PVR
