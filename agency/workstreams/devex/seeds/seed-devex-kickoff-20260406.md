---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "DevEx workstream kickoff — test isolation, pre-commit, developer friction"
---

# DevEx Workstream Seed

## Mission

DevEx owns the developer experience for agents and principals working in TheAgency. Test infrastructure, commit workflow, permission model, tooling ergonomics — anything that creates friction between "I want to do X" and X actually happening.

## Why Now

ISCP rollout (2026-04-05/06) exposed cascading failures in test infrastructure that blocked captain operations twice in one session. The pre-commit hook is broken enough that we're routinely bypassing it with `--no-verify`, which defeats its purpose. These problems will only compound as more agents come online.

## The Burning Problem: Test Isolation + Pre-Commit

### What broke (2026-04-05/06, captain session)

1. **BATS tests corrupt `.git/config`** — `agent-identity.bats` sets `core.bare=true` and `user.email=test@example.com` in the LIVE repo config. All git operations break. Commits get wrong author attribution. Discovered twice in one session — the pre-commit hook re-triggered it.

2. **BATS tests leak into live ISCP DB** — `flag.bats`, `dispatch.bats` insert test records into `~/.agency/the-agency/iscp.db`. Between test and teardown, `iscp-check` reports "You have 62 flag(s)" to any agent that starts up. Indistinguishable from real flags.

3. **Test debris in working directory** — Tests create `.claude/agents/testname.md`, `agency/agents/testname/`, and `agency/workstreams/test; rm -rf /` (injection test) in the live working tree. These show up in `git status` and can be accidentally committed.

4. **Pre-commit hook runs full BATS suite for ANY change** — `commit-precheck` runs all 32 BATS test files (155 tests) even for markdown-only changes. Takes minutes. Times out. Captain killed stuck processes twice. Forces `--no-verify`, which bypasses QGR enforcement.

5. **Pre-commit BATS run re-triggers the corruption** — The hook runs BATS, BATS corrupts `.git/config`, the commit fails, captain fixes config, tries again, hook runs BATS again, re-corrupts. Vicious cycle.

### What ISCP built (foundation to build on)

ISCP agent fixed the immediate test isolation bugs in dispatches #20-22. This work is merged to main.

**Layer 1: In-process isolation** (`tests/tools/test_helper.bash`)
- `iscp_test_isolation_setup()` — overrides HOME, sets `ISCP_DB_PATH` to temp file, sets `GIT_CONFIG_GLOBAL=/dev/null`, snapshots `.git/config` hash
- `iscp_test_isolation_teardown()` — verifies `.git/config` hash unchanged, cleans temp files
- All 7 ISCP BATS files updated to use these helpers
- `ISCP_DB_PATH` env var support in `agency/tools/lib/_iscp-db`

**Layer 2: Docker isolation** (`tests/Dockerfile` + `tests/docker-test.sh`)
- Alpine container with bash/git/sqlite/jq/bats
- Repo mounted read-only at `/repo`
- Non-root `testrunner` user
- Container destroyed after run — zero host contamination
- Currently manual: `./tests/docker-test.sh`
- Only runs ISCP tests (7 files) — not the full 32-file suite

**What ISCP did NOT fix:**
- Pre-commit hook still runs full suite unconditionally
- Non-ISCP test files (25 of 32) have NO isolation
- Docker runner isn't integrated into the commit workflow
- No smart test scoping (changed-file detection)
- Working directory test debris (testname agent, injection test dirs)

### What DevEx needs to build

**Priority 1: Make pre-commit not broken**
- Smart test scoping — detect changed files, run only relevant BATS tests
- Skip tests entirely for non-code changes (markdown, dispatches, handoffs)
- Timeout with graceful degradation — if tests take too long, warn but don't block
- Never run BATS tests that can corrupt the host environment from the pre-commit hook

**Priority 2: Extend isolation to all tests**
- Apply ISCP's isolation pattern to all 32 BATS test files, not just the 7 ISCP ones
- Fix working directory pollution (testname agent, injection test dirs)
- Ensure all test fixtures use temp directories, not the live working tree
- Docker runner should support the full suite, not just ISCP tests

**Priority 3: Make Docker the default for full-suite runs**
- `./tests/docker-test.sh` runs ALL tests, not just ISCP
- Pre-commit hook uses Docker for full-suite (if Docker available), in-process for targeted runs
- CI integration (future — when we have CI)

## Broader DevEx Scope (beyond first task)

The friction points document (`usr/jordan/captain/friction-points-20260405.md`) catalogs 15 issues across 4 categories. DevEx owns most of them:

**Permission Friction (P1-P6):** settings-template.json ships too few permissions, agents prompt for safe operations, macOS permissions break on updates.

**Tooling Gaps (T1-T5):** T1 (dispatch fetch/reply — DONE by ISCP), T2 (worktree payload access — DONE by ISCP), T3 (pre-commit timeout — THIS SEED), T4 (worktree agent lifecycle), T5 (test isolation leaks — THIS SEED).

**Agent Bootstrap (B1-B3):** agency-init broken, agent-create missing essentials, no permission prompt counter.

**Claude Code Behavioral (C1-C2):** Agent permission scope undefined, multi-principal DB security.

## Key Files

| File | What | Status |
|------|------|--------|
| `tests/tools/test_helper.bash` | Shared BATS isolation helpers | EXISTS — ISCP built |
| `tests/Dockerfile` | Docker test container | EXISTS — ISCP built |
| `tests/docker-test.sh` | Docker test runner | EXISTS — ISCP built, ISCP-only |
| `agency/tools/commit-precheck` | Pre-commit hook logic | EXISTS — needs rewrite |
| `.git/hooks/pre-commit` | Git hook entry point | EXISTS — calls commit-precheck |
| `agency/tools/lib/_iscp-db` | ISCP DB with env var override | EXISTS — ISCP built |
| `usr/jordan/captain/friction-points-20260405.md` | Full friction catalog | EXISTS |

## References

- ISCP dispatches #20, #21, #22 — the bug reports that triggered this work
- ISCP commits: b1cd1b0, efa00d6, 52222e7, d0c7c9e
- Friction points: `usr/jordan/captain/friction-points-20260405.md`
- ISCP reference: `agency/workstreams/iscp/iscp-reference-20260405.md`
