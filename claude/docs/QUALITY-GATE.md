## Quality Gate (QG) Protocol

Run this full Quality Gate (QG) before every commit. Do not skip steps even if the work "looks fine" — the audit always finds something.

The gate applies to **any artifact type** — code, commands, config, documentation. The review adapts to the artifact: code gets correctness/security/performance review plus tests; commands and config get design review, spec compliance checks, and edge case analysis; documentation gets accuracy and completeness review. The report format is the same regardless — sections that don't apply are marked "N/A" with an explanation, never omitted.

Commits happen at iteration, phase, and plan completion — not in between. Do not commit partial work mid-iteration.

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
