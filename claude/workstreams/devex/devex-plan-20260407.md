---
type: plan
project: devex
workstream: devex
date: 2026-04-07
status: active
author: the-agency/jordan/devex
pvr: usr/jordan/devex/devex-pvr-20260406.md
ad: claude/workstreams/devex/devex-ad-20260407.md
---

# DevEx — Implementation Plan

## Phase 1: Pre-Commit + Test Isolation (the burning problem)

**Goal:** Make `commit-precheck` fast, safe, and smart. Extend isolation to all 32 BATS test files. Fix the corruption cycle.

### Iteration 1.1: Universal Test Isolation

**Scope:** Extend `test_helper.bash` with universal isolation. Update all 25 unprotected BATS files.

**Work:**
- Refactor `iscp_test_isolation_setup/teardown` into `test_isolation_setup/teardown` in `test_helper.bash`
- Keep `iscp_*` as aliases for backward compatibility
- Make `setup()` in test_helper call `test_isolation_setup` by default
- Add `SKIP_ISOLATION=1` opt-out mechanism
- Add filesystem debris detection in teardown (targeted `ls` on `claude/agents/`, `.claude/agents/`, `claude/workstreams/`)
- Update all 25 non-ISCP BATS files to work with universal isolation
- Fix any tests that break due to isolation (fake HOME, git config)

**Acceptance:**
- All 32 BATS files pass with universal isolation enabled
- Teardown guard catches `.git/config` modifications
- Teardown guard catches working directory debris
- `SKIP_ISOLATION=1` correctly bypasses isolation
- ISCP test files unchanged (aliases work)

### Iteration 1.2: Test Scoper

**Scope:** Build `claude/tools/test-scoper` — maps changed files to relevant test files.

**Work:**
- Convention mapping: `claude/tools/{name}` → `tests/tools/{name}.bats`
- Package fallback: `claude/tools/lib/{name}` → grep all `.bats` for `source.*{name}`
- Direct test changes: `tests/**/*.bats` → run the changed file
- Manifest override: `# Test: path/to/test.bats` header comment
- No mapping → warn, output nothing (not an error)
- Stdin interface: reads file list from stdin, outputs test files to stdout

**Acceptance:**
- `echo "claude/tools/flag" | test-scoper` outputs `tests/tools/flag.bats`
- `echo "claude/tools/lib/_iscp-db" | test-scoper` outputs all BATS files that source `_iscp-db`
- `echo "tests/tools/flag.bats" | test-scoper` outputs `tests/tools/flag.bats`
- `echo "usr/jordan/devex/devex-handoff.md" | test-scoper` outputs nothing (no mapping, exit 0)
- Tool has provenance header and `_log-helper` integration

### Iteration 1.3: Commit-Precheck Rewrite

**Scope:** Rewrite `claude/tools/commit-precheck` with smart scoping, non-code skip, 60s timeout, and stage-hash verification.

**Work:**
- Stage classifier: categorize staged files (markdown-only, non-code, tool-change, app-code)
- Integrate test-scoper for changed-file → test mapping
- Non-code skip: all `.md` files → skip tests, allow with warning
- 60s timeout via existing `run_with_timeout` (keep the mechanism, change the budget)
- Graceful degradation: timeout = warn + allow, not block
- Stage-hash verification: warn if no QGR receipt matches (warn-only, not block)
- Remove the 5-step Node.js-centric structure (format/lint/typecheck/test/review)
- Replace with: classify → scope → run scoped tests → verify stage-hash
- Strip the `code-review` step entirely (belongs in `/iteration-complete`, not pre-commit)

**Acceptance:**
- Markdown-only commit completes in <5s (no tests)
- Single tool change (`claude/tools/flag`) runs only `tests/tools/flag.bats`, completes in <60s
- Timeout at 60s produces warning, allows commit
- No `.git/config` corruption (isolation via test-scoper → BATS → universal isolation)
- `--dry-run` shows what would execute without running
- Stage-hash mismatch warns but does not block

### Iteration 1.4: Tests for the Pre-Commit

**Scope:** BATS tests for `commit-precheck`, `test-scoper`, and the isolation helpers themselves.

**Work:**
- `tests/tools/commit-precheck.bats` — test classification, scoping, timeout, skip
- `tests/tools/test-scoper.bats` — test convention mapping, package fallback, manifest, edge cases
- `tests/tools/test-isolation.bats` — test that isolation actually isolates (fake HOME, DB, git config)
- All tests use universal isolation (eating our own dog food)

**Acceptance:**
- All new test files pass
- Tests verify isolation works (meta-test: test that tests are isolated)
- No test modifies live `.git/config`, live ISCP DB, or working directory

---

## Phase 2: Docker Full Suite

**Goal:** Extend Docker runner to all 32 BATS files. Integrate as T3 mechanism.

### Iteration 2.1: Docker Runner Extension

**Scope:** Extend `tests/docker-test.sh` to run all 32 BATS files.

**Work:**
- Update default test list from 7 ISCP files to all 32
- Verify Dockerfile has all dependencies for non-ISCP tests
- Add `--iscp-only` flag to preserve current behavior
- Add `--file <path>` for single-file runs
- Test all 32 files pass in Docker

**Acceptance:**
- `./tests/docker-test.sh` runs all 32 BATS files and passes
- `./tests/docker-test.sh --iscp-only` runs only 7 ISCP files (backward compat)
- Docker image builds in <30s (cached layers)

### Iteration 2.2: T3 Integration + Fallback

**Scope:** Wire Docker runner as the T3 mechanism. Implement in-process fallback.

**Work:**
- T3 entry point: `claude/tools/test-full-suite` — tries Docker, falls back to in-process
- Docker check: `docker info` succeeds → use Docker
- Fallback: run all 32 files in-process with universal isolation, emit warning
- Integrate with phase-complete flow (called by `/phase-complete`)
- 5-minute timeout for full suite

**Acceptance:**
- With Docker: full suite runs in container, zero host contamination
- Without Docker: full suite runs in-process with isolation, warning emitted
- T3 completes within 5-minute budget

---

## Phase 3: Permission Model + Enforcement Tooling

**Goal:** Audit and fix the permission model. Build enforcement registry and context budget linter.

### Iteration 3.1: Permission Model Audit

**Scope:** Audit `claude/config/settings-template.json` against all safe operations. (FR7, dispatch #36)

**Work:**
- Catalog all tools in `claude/tools/` and their system calls
- Catalog all read-only operations agents perform (ls, git show, sqlite3, etc.)
- Catalog all framework paths that need read access (`claude/`, `usr/`, `.claude/`, `~/.agency/`)
- Update `settings-template.json` with comprehensive safe-op permissions
- Categories: read framework, read ISCP, write sandbox, git local ops
- Exclude: destructive ops (push, reset --hard, rm -rf)

**Acceptance:**
- All tools in `claude/tools/` have their operations pre-approved
- Read operations on `claude/`, `usr/`, `.claude/`, `~/.agency/` pre-approved
- ISCP tools (flag, dispatch list/read, iscp-check) pre-approved
- No destructive operations pre-approved
- Existing permissions preserved (no removals)

### Iteration 3.2: Enforcement Registry + Audit Tool

**Scope:** Build `claude/config/enforcement.yaml` and `claude/tools/enforcement-audit`. (FR8, Valueflow A&D §4)

**Work:**
- Define YAML schema for enforcement registry (version, capabilities, workstreams)
- Populate registry with all current capabilities and their actual ladder levels
- Build `enforcement-audit` tool: validates each capability has all artifacts for its declared level
- Level 1: doc exists. Level 2: +skill exists. Level 3: +tool exists. Level 4: +hookify-warn exists. Level 5: +hookify-block exists.
- Output: structured report with pass/fail per capability
- `_log-helper` integration

**Acceptance:**
- `enforcement-audit` runs cleanly against populated registry
- Detects missing artifacts (e.g., capability at level 3 but no tool file)
- Reports per-workstream override status
- Exit 0 = all valid, exit 1 = violations found

### Iteration 3.3: Context Budget Linter

**Scope:** Build `claude/tools/context-budget-lint`. (FR9, Valueflow A&D §9)

**Work:**
- Resolve `@`-import chains from skill files (recursive — imports can import)
- Measure total token count per skill injection using `wc -w` with 0.75 factor
- Default budget: 4000 tokens per skill
- `--budget N` override
- Report: per-skill token count, percentage of budget, over/under
- Exit 0 = all within budget, exit 1 = over-budget skills found

**Acceptance:**
- Correctly follows `@`-import chains (including nested imports)
- Token estimate within 20% of actual (verify against a few known skills)
- Catches skills that exceed 4000 tokens
- `--budget` override works
- Handles circular imports gracefully (detect and warn)

### Iteration 3.4: Tests for Phase 3

**Scope:** BATS tests for all Phase 3 tools.

**Work:**
- `tests/tools/enforcement-audit.bats`
- `tests/tools/context-budget-lint.bats`
- Verify settings-template.json changes don't break existing projects

**Acceptance:**
- All new test files pass with universal isolation
- Enforcement audit tests cover: valid registry, missing artifacts, workstream overrides
- Context budget linter tests cover: simple skill, nested imports, over-budget, circular import

---

## Status

| Phase | Iteration | Status |
|-------|-----------|--------|
| 1 | 1.1 Universal Test Isolation | **Complete** |
| 1 | 1.2 Test Scoper | **Complete** |
| 1 | 1.3 Commit-Precheck Rewrite | **Complete** |
| 1 | 1.4 Tests for Pre-Commit | **Complete** |
| 2 | 2.1 Docker Runner Extension | Not started |
| 2 | 2.2 T3 Integration + Fallback | Not started |
| 3 | 3.1 Permission Model Audit | Not started |
| 3 | 3.2 Enforcement Registry + Audit | Not started |
| 3 | 3.3 Context Budget Linter | Not started |
| 3 | 3.4 Tests for Phase 3 | Not started |

## Seed Backlog (future phases)

- Dispatch #31: Test result reporting service (DB-backed, structured, wires into QG)
- Dispatch #36: Permission model overhaul — broader scope (transcript mining, PermissionDenied hook) beyond Phase 3.1 audit
- Flag #1: SMS-style dispatches (ISCP scope, not DevEx)
- Flag #3: Friction→toolification pattern formalization
