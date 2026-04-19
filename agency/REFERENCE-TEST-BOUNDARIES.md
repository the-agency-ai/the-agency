# Test Boundaries — T1/T2/T3 Reference

> Resolves legacy flag #1: "test management — define what a boundary run looks like (which frameworks, which scopes, at each commit boundary)."

This document defines what testing happens at each commit boundary in TheAgency, the tools that orchestrate it, and the budgets/scope rules that apply.

## The Tiers

| Tier | When | Scope | Budget | Tool | Failure mode |
|------|------|-------|--------|------|--------------|
| **T1** | Pre-commit (every `git commit`) | Stage-hash + compile + format + tests relevant to staged files | 60s | `agency/tools/commit-precheck` (via `.git/hooks/pre-commit`) | Block on failure, warn on timeout |
| **T2** | Iteration boundary (`/iteration-complete`) | T1 + full relevant unit tests (changed-file scoping) | <2 min | `/iteration-complete` skill | Block on failure |
| **T3** | Phase boundary (`/phase-complete`) | **Full** suite, all BATS files + MAR on phase artifacts | <5 min | `agency/tools/test-full-suite` (Docker preferred, in-process fallback) | Block on failure |
| **T4** | Pre-PR (`/pr-prep`) | Full diff QG vs origin/main | <5 min | `/pr-prep` skill | Block on failure |

Source: Valueflow A&D §6 "Quality Gate Architecture".

## T1 — Pre-Commit (the burning problem, now solved)

**Goal:** fast feedback on what the agent just changed. Never run irrelevant tests.

### How it works
1. `git commit` triggers `.git/hooks/pre-commit` → `agency/tools/commit-precheck`
2. `commit-precheck` classifies staged files into one of:
   - `docs-only` — `.md`, `.txt`, `.json`, `.yaml`, `.yml` → **fast path, no tests**
   - `config-only` — config files outside `agency/tools/` → **fast path, no tests**
   - `tool-code` — bash/test files in `agency/tools/` or `tests/` → **scoped tests**
   - `app-code` — `.ts/.js/.py/.rs/.go/.java/.swift` → **scoped tests + format/lint/typecheck**
3. For tool-code and app-code: `commit-precheck` pipes staged file paths to `agency/tools/test-scoper`, which maps them to relevant test files via four strategies:
   - **Manifest:** `# Test: tests/tools/foo.bats` header in source file (highest priority)
   - **Convention:** `agency/tools/{name}` → `tests/tools/{name}.bats` + `tests/tools/{name}-*.bats`
   - **Dependency:** `agency/tools/lib/{_name}` → all `tests/tools/*.bats` that source `{_name}`
   - **Direct:** `tests/**/*.bats` → itself
4. `commit-precheck` runs only the matched test files via `bats <files>`.
5. 60s budget. On timeout: warn but allow commit (graceful degradation). On test failure: block.

### Configuring the registered test suites
`agency.yaml` → `testing.suites` declares what runs as part of the full suite. `commit-precheck` itself doesn't read this section — it always uses BATS for tool-code and JS test runners for app-code via `test-scoper` output. The suites section feeds T3 (`test-full-suite`).

### Examples

| Staged file | Scoped tests |
|-------------|-------------|
| `agency/tools/flag` | `tests/tools/flag.bats` |
| `agency/tools/dispatch` | `tests/tools/dispatch.bats` + `tests/tools/dispatch-create.bats` |
| `agency/tools/lib/_iscp-db` | `tests/tools/iscp-db.bats` (direct) + all `.bats` files that source `_iscp-db` |
| `usr/jordan/devex/devex-handoff.md` | nothing (docs-only fast path) |
| `agency/config/agency.yaml` | nothing (config-only fast path) |

## T2 — Iteration Boundary

**Goal:** prove the iteration is shippable in isolation. Runs the same test scope as T1 plus the formatting/linting pass that pre-commit may have skipped.

### How it works
1. Agent runs `/iteration-complete` skill
2. Skill calls `commit-precheck` (full path: classify → scope → run)
3. Skill calls format/lint/typecheck for app-code projects (when scripts exist in `package.json`)
4. On clean: auto-commits via `agency/tools/git-safe-commit` with the iteration prefix
5. On failure: blocks, surfaces findings, agent fixes and re-runs

T2 exists primarily to enforce the boundary commit ritual — it doesn't add test coverage beyond T1, it adds the surrounding hygiene.

## T3 — Phase Boundary

**Goal:** validate the entire framework still works after a body of work lands. Runs ALL BATS files, all test files, no scoping. This is the "deep QG."

### How it works
1. Agent runs `/phase-complete` skill
2. Skill runs the multi-agent quality gate (parallel review agents)
3. Skill calls `agency/tools/test-full-suite` for the full test execution
4. `test-full-suite` decides between Docker and in-process:
   - **Docker available** (`docker info` succeeds): runs `tests/docker-test.sh` which mounts the repo read-only and runs all BATS files in container isolation. Zero host contamination possible.
   - **Docker not available**: runs in-process via `bats <all files>` with universal isolation from `tests/tools/test_helper.bash`. Emits a warning that protection is good-but-not-perfect.
5. 5-minute budget. Same graceful behavior as T1: timeout warns + allows, real failures block.

### Why Docker for T3
The full suite runs against the live repo. Without container isolation, individual tests have leaked into the real `.git/config`, the real ISCP DB, and the real working tree (the `Test User` commit-author saga, the 62 ghost flags incident). Universal test isolation in `test_helper.bash` catches most of this, but Docker is the belt-and-suspenders that makes T3 reliably hermetic.

## T4 — Pre-PR

**Goal:** validate the full diff against origin/main before opening or updating a PR. T3 validates the working tree; T4 validates what's about to ship to humans.

### How it works
1. Agent (or captain) runs `/pr-prep` skill before pushing a PR branch
2. Skill diffs the branch against `origin/main`
3. Runs the multi-agent QG against the diff (focus on what's changing, not what's already merged)
4. Produces a QGR receipt scoped to the PR diff
5. Same 5-minute budget as T3
6. On clean: PR is ready to push. On findings: dispatch back to the implementing agent.

T4 is captain-driven in the standard flow — agents land work via T3 (`/phase-complete`), captain accumulates landed work and runs `/pr-prep` before `/sync` pushes to origin.

## Tool Inventory

| Tool | Location | Purpose |
|------|----------|---------|
| `commit-precheck` | `agency/tools/commit-precheck` | T1 orchestrator (classify → scope → run) |
| `test-scoper` | `agency/tools/test-scoper` | File → test mapping (4 strategies) |
| `test-full-suite` | `agency/tools/test-full-suite` | T3 orchestrator (Docker or fallback) |
| `test-run` | `agency/tools/test-run` | Reads `agency.yaml` `testing.suites`, runs all configured suites. Used outside the boundary flow. |
| `tests/docker-test.sh` | `tests/docker-test.sh` | Container runner for T3. `--iscp-only` for backward compat, `--file <path>` for single file, default = all files. |
| `tests/tools/test_helper.bash` | `tests/tools/test_helper.bash` | Universal test isolation: fake HOME, GIT_DIR/_*/_AUTHOR_* unset, teardown guards for `.git/config` pollution and working-tree debris. |

## Budgets at a Glance

```
T1 (pre-commit)    ──── 60s ──── scoped tests
T2 (iteration)     ──── ~2m ──── scoped tests + format/lint/typecheck
T3 (phase)         ──── 5m  ──── ALL tests in container
```

Each tier has graceful timeout: if the runner hits the budget, it warns but doesn't block. The goal is to surface signal without holding up legitimate work — agents can still run the full suite manually when they need to.

## Universal Isolation Contract

Every BATS test inherits the default `setup()` from `test_helper.bash`, which calls `test_isolation_setup` to:

- `unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_AUTHOR_* GIT_COMMITTER_*` — prevents leakage from a parent pre-commit hook context
- `export HOME="$BATS_TEST_TMPDIR/fakehome"` — isolates dotfiles, cache, DB paths
- `export ISCP_DB_PATH="$BATS_TEST_TMPDIR/test-iscp.db"` — explicit override
- `export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null` — blocks writes to user/system git config
- Snapshot live `.git/config` checksum for teardown validation
- Snapshot key directories (`claude/agents/`, `.claude/agents/`) for debris detection

`test_isolation_teardown` verifies the snapshots and fails loudly if anything leaked. Tests can opt out via `SKIP_ISOLATION=1` for the rare case that needs real environment access.

## Hookify Rules That Touch the Boundaries

| Rule | What it catches |
|------|----------------|
| `git-safe-commit-block` | Raw `git commit` (use `/git-safe-commit` skill which goes through `git-safe-commit` tool which triggers the pre-commit hook) |
| `git-add-and-commit-block` | Compound `git add ... && git commit` (dodges /git-safe-commit) |
| `cd-outside-worktree-block` | Worktree escape via `cd /any/path`, `cd ..`, etc. — protects identity resolution that drives the test paths |
| `raw-git-config-user-in-tests-block` | Raw `git config user.*` outside `test_isolation_setup` (the historical pollution vector that broke T1) |
| `no-verify-block` | `git commit --no-verify` (skips T1 entirely) |

## Related

- `agency/workstreams/devex/devex-ad-20260407.md` §4 (enforcement ladder) and §6 (QG tiers)
- `agency/workstreams/devex/devex-plan-20260407.md` Phase 1 (test scoping + commit-precheck rewrite) and Phase 2 (Docker T3)
- Legacy flag #1 — original ask, now closed by this document
