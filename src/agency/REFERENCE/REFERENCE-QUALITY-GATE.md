## Quality Gate (QG) Protocol

The gate applies to **any artifact type** — code, commands, config, documentation. The review adapts to the artifact: code gets correctness/security/performance review plus tests; commands and config get design review, spec compliance checks, and edge case analysis; documentation gets accuracy and completeness review. The report format is the same regardless — sections that don't apply are marked "N/A" with an explanation, never omitted.

Commits happen at iteration, phase, and plan completion — not in between. Do not commit partial work mid-iteration.

### The 5 Hard Rules

1. **Failing row MUST be 0.** No exceptions. Pre-existing failures are your problem too.
2. **Red-green cycle for every bug-exposing test.** No valid test = no valid fix.
3. **Never skip review agents** — even for "small" or "trivial" changes. The audit always finds something.
4. **Fix every finding.** Every valid finding gets fixed — no "Won't Fix," no "Deferred," no severity-based skip. Severity orders the fix sequence, never the fix decision. Reject invalid findings with reasoning.
5. **Always use `/git-safe-commit`** — never raw `git commit`. The tool computes the stage hash and will verify a QGR receipt exists for the staged changes.

### Boundary Skills

| Boundary | Skill | QG Scope | Approval |
|----------|-------|----------|----------|
| Iteration end | `/iteration-complete` | Changes since last commit | Auto-commit |
| Phase end | `/phase-complete` | Full codebase (deep QG) | Principal required |
| Plan end | `/plan-complete` | Full codebase | Principal required |
| Pre-PR | `/pr-prep` | Full diff vs origin/master | — |
| Pre-phase | `/pre-phase-review` | PVR + A&D + Plan review | Principal required |

### QGR Receipt Files

Each gate produces a standalone receipt at:

```
agency/workstreams/{ws}/quality-gate-reports/qgr-{boundary}-{phase.iter}-{stage-hash}-{YYYYMMDD-HHMM}.md
```

For workstreams with multiple projects, use `agency/workstreams/{ws}/project/{project}/quality-gate-reports/`. The QGR frontmatter must include `agent: {repo}/{principal}/{agent}` for attribution. The stage hash is a deterministic hash of the staged changes (computed by `agency/tools/stage-hash`). `/git-safe-commit` checks for a matching receipt before committing — no receipt means no QG was run.

**Receipt chain:** Each QGR is part of a five-hash chain linking the artifact through the gate (see `REFERENCE-RECEIPT-INFRASTRUCTURE.md` when available). The chain provides an auditable link: staged changes → stage hash → QGR file → commit → PR. `pr-create` (via `/release` or `/pr-prep`) verifies the receipt chain before pushing — a PR cannot be created without a valid T4 QGR receipt matching the current diff.

### Gate Tiers

Gates are tiered by commit boundary type. Higher tiers include all lower-tier checks.

| Tier | Boundary | Checks | Time budget | Skill |
|------|----------|--------|-------------|-------|
| **T1** | Iteration commit | Stage-hash match + build/compile + format + relevant fast tests | **<60s** | `/iteration-complete` |
| **T2** | Phase commit | T1 + full relevant unit tests (changed-file scoping) | <120s | `/phase-complete` (pre-squash) |
| **T3** | Phase complete | Full test suite + MAR on phase artifacts | <5min | `/phase-complete` (deep QG) |
| **T4** | Pre-PR | Full diff QG vs origin/main | <5min | `/pr-prep` |

**T1 is the iteration gate.** Stage-hash match proves the QGR was generated for the exact staged changes. Build/compile catches syntax errors. Format runs on save AND at T1 (belt and suspenders — both cheap). Relevant fast tests run tests that map to changed files (see Changed-File Test Scoping below). If tests exceed the 60s budget, test scoping needs improvement — not skipping.

**T1 baseline is universal:** `stage-hash match + build/compile` works for every language. Format and lint are optional per language toolchain (Swift has no standard linter, JS has eslint). Relevant unit tests included if they fit the time budget.

**T2 adds full scoped tests.** All unit tests relevant to the changed files, not just fast tests. 120s budget. This runs during phase commit before squash.

**T3 is the deep gate.** Full test suite (Docker if available, in-process with isolation if not). MAR review of phase artifacts (PVR updates, A&D updates, plan updates). This is the Sprint Review gate.

**T4 is the shipping gate.** Full diff quality gate against origin/main. Runs before PRs are created. Catches anything that slipped through T1-T3 across the accumulated diff.

### Changed-File Test Scoping

Tests are scoped to changed files to keep T1/T2 fast.

**Convention-based (default):** Source path mirrors test path. `agency/tools/flag` → `tests/tools/flag.bats`. Zero-config, covers 90% of cases.

**Package-level (fallback):** For non-mirrored layouts (Swift, Rust, Go packages): anything in `apps/mdpal/Sources/` changed → run tests in `apps/mdpal/`. Handles projects where test paths don't mirror source paths.

**Manifest (override):** For edge cases where convention and package-level don't map, a tool can declare its test file in metadata.

### Stage-Hash Delta Tolerance

If the delta between QGR hash and current staged hash is **exclusively markdown files** (all changed files are `.md`) → allow with warning. Any non-markdown file in the delta → re-run QG. If the commit contains both a markdown change and a code change, re-run. Simpler than "non-code files changed" — is `package.json` code? Yes, re-run.

### Full QG Protocol (T3/T4)

Run the full protocol below for T3 (phase complete) and T4 (pre-PR) boundaries. T1 and T2 run the subset defined by their tier. Do not skip steps even if the work "looks fine" — the audit always finds something.

### Steps

1. **Parallel review** — Launch multiple agents in parallel across two categories, AND conduct your own review:
   - **Code reviewers** (2+ code-reviewer agents) — each reviews independently for bugs, logic errors, security, performance, code quality, convention adherence. Give each reviewer a different focus area (e.g., correctness/logic vs. performance/security) to maximize coverage.
   - **Test reviewers** (2+ code-reviewer agents, test-focused prompts) — each reviews independently for test coverage gaps, missing edge cases, test quality, test/implementation consistency. Give each reviewer a different focus (e.g., edge cases/error paths vs. breadth/integration coverage).
   - **Your own review** — Read the code yourself and conduct your own independent review while agents are running. You may catch things agents miss (architectural issues, subtle interactions, domain-specific concerns).
2. **Consolidate findings** — Merge and deduplicate results from all reviewers (agents + your own). Evaluate each finding: **Valid** (will fix) or **Rejected** (with reasoning). Every valid finding gets fixed — no severity tiers, no "nits," no deferrals. A finding is either wrong or it gets fixed.
3. **Write tests for issues** — For each code issue found, write a test that exposes the bug. **Run it and confirm it fails (red).** If the test passes, it doesn't actually expose the bug — rewrite it until it fails. Tests for config/doc issues that can't be tested programmatically are marked N/A in the report.
4. **Fix issues** — Fix each issue. **Re-run the exposing test and confirm it now passes (green).** Red → green is the proof the fix works. If you can't demonstrate the red → green cycle, you don't have a valid bug-exposing test.
5. **Review test coverage** — Using the test reviewer's findings, decide what additional tests are needed (edge cases, breadth, depth, performance).
6. **Add tests** — Write the additional tests identified above.
7. **Fix any new issues** — If new tests expose problems, fix them.
8. **Confirm all clean** — Run all tests in scope plus lint, format, and typecheck. **Zero failing tests — no exceptions.** If pre-existing tests are failing, fix them. If infrastructure is broken (missing packages, wrong paths, flaky parallelism), that's the work. The Failing row in the report must be 0.
9. **Present quality gate report** — Share the report (format below) inline in the conversation. Add it to the Plan.
10. **Commit** — behavior depends on the boundary type:
    - **Iteration boundary** (via `/iteration-complete`): Commit automatically. No approval needed. Present the QGR inline and move to the next iteration.
    - **Phase boundary** (via `/phase-complete`): Present the QGR and proposed commit message. **Wait for principal approval** before committing. This is a Sprint Review — the principal reviews the body of work.

### Commit Discipline

- **Iteration complete** — QG scoped to changes, auto-commit after clean Quality Gate Report (QGR). No approval needed.
- **Phase complete** — Squashes iterations, deep QG (full codebase), Sprint Review, approval required, lands on master.
- **Plan complete** — Final deep QG, finalize Product Vision & Requirements (PVR) / Architecture & Design (A&D) / Plan, produce Reference doc. Captain creates PRs.
- **Before starting a new phase** — Reviews PVR, A&D, and Plan with multiple agents. Gets clearance.

### Quality Gate Report (QGR)

After completing steps 1-8, present a Quality Gate Report (QGR) in this format:

```
## Quality Gate Report

### Issues Found

| ID | Type | Summary | Status | Via | Tests Added | Bug-Exposing Fix |
|----|------|---------|--------|-----|-------------|-----------------|
| 1 | bug/config/design/ux/security/performance | Description | Fixed / Rejected: reason | Inspection/Test/Static Check | `test name` (purpose, type, count) or N/A | `abc1234` or N/A (not testable: reason) |

Issue types: bug, config, design, ux, security, performance
Status: **Fixed** (valid finding, resolved) or **Rejected** (invalid finding, with reasoning). No other status. No "Won't Fix," no "Deferred." Severity (critical/high/medium/low) may be used to order the fix sequence — fix critical issues first — but severity never means "don't fix." Every valid finding gets fixed.
Via: Inspection (review agents + own review), Test (found by running tests), Static Check (lint/typecheck)
Tests Added format: `test name` (bug-exposing|coverage, unit|integration|e2e-cli|e2e-browser|api|performance, count)
Bug-Exposing Fix: The commit SHA where the fix landed (short hash, e.g., `abc1234`). For issues that cannot be tested programmatically (documentation, config, design decisions), write `N/A (not testable: reason)`. This creates an auditable link from finding → test → fix.

### Quality Gate Accountability

| Purpose | Before | Added | Removed | Total |
|---------|--------|-------|---------|-------|
| Bug-exposing | N | N | N | N |
| Coverage | N | N | N | N |
| Pre-existing | N | N | N | N |
| **Passing** | **N** | **N** | **N** | **N** |
| **Failing** | **N** | **N** | **N** | **0** |

The Failing row MUST be 0. If it is not 0, fix the failures before proceeding. No exceptions.

### Coverage Health

| Type | Before | Added | Total | % |
|------|--------|-------|-------|---|
| Unit | N | N | N | N% |
| Integration | N | N | N | N% |
| E2E (CLI) | N | N | N | N% |
| E2E (Browser) | N | N | N | N% |
| API | N | N | N | N% |
| Performance | N | N | N | N% |
| **Total** | **N** | **N** | **N** | |

Zeros are visible and intentional — they force the question "why don't we have tests here?"

### Checks

| Check | Result |
|-------|--------|
| Lint | 0 warnings, 0 errors |
| Format | Clean |
| Typecheck | Clean |
| Tests | N/N pass, 0 failing |

### Quality Gate Summary

For each stage, describe what was actually done:

**Stage 1 - Parallel Review**
- N code review agents (describe focus areas)
- N test review agents (describe focus areas)
- Own review (describe what you looked at)

**Stage 2 - Consolidate**
- N issues identified, deduplicated from N reviewers
- Each finding evaluated: Valid (will fix) or Rejected (with reasoning)
- N valid, N rejected
- Breakdown by type

**Stage 3 - Bug-Exposing Tests**
- N tests written targeting issues [list IDs]
- Red-green cycle confirmed for all N tests

**Stage 4 - Fix Issues**
- All N issues fixed
- N found by inspection, N found by test, N found by static check

**Stage 5 - Coverage Review**
- Describe gaps identified by test reviewers

**Stage 6 - Add Coverage Tests**
- N coverage tests added

**Stage 7 - Fix New Issues**
- N additional issues found while fixing (or "None")

**Stage 8 - Confirm Clean**
- Lint: result
- Format: result
- Tests: N/N pass, 0 failing

### What Was Found and Fixed

Plain-language summary grouped by issue type. For each issue: one sentence describing the problem, one sentence describing the fix.

### Proposed Commit
- **Message:** structured commit message
- **Files:** list of files to be staged
```
