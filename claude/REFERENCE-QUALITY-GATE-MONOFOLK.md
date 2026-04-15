## Quality Gate (QG) Protocol

Run this full Quality Gate (QG) before every commit. Do not skip steps even if the work "looks fine" — the audit always finds something.

The gate applies to **any artifact type** — code, commands, config, documentation. The review adapts to the artifact: code gets correctness/security/performance review plus tests; commands and config get design review, spec compliance checks, and edge case analysis; documentation gets accuracy and completeness review. The report format is the same regardless — sections that don't apply are marked "N/A" with an explanation, never omitted.

Commits happen at iteration, phase, and plan completion — not in between. Do not commit partial work mid-iteration.

### Steps

1. **Parallel review** — Launch multiple agents in parallel across two categories, AND conduct your own review:
   - **Code reviewers** (2+ code-reviewer agents) — each reviews independently for bugs, logic errors, security, performance, code quality, convention adherence. Give each reviewer a different focus area (e.g., correctness/logic vs. performance/security) to maximize coverage.
   - **Test reviewers** (2+ code-reviewer agents, test-focused prompts) — each reviews independently for test coverage gaps, missing edge cases, test quality, test/implementation consistency. Give each reviewer a different focus (e.g., edge cases/error paths vs. breadth/integration coverage).
   - **Your own review** — Read the code yourself and conduct your own independent review while agents are running. You may catch things agents miss (architectural issues, subtle interactions, domain-specific concerns).
2. **Consolidate findings** — Merge and deduplicate results from all reviewers (agents + your own) into a single prioritized list of issues.
3. **Write tests for issues** — For each code issue found, write a test that exposes the bug. **Run it and confirm it fails (red).** If the test passes, it doesn't actually expose the bug — rewrite it until it fails. Tests for config/doc issues that can't be tested programmatically are marked N/A in the report.
4. **Fix issues** — Fix each issue. **Re-run the exposing test and confirm it now passes (green).** Red → green is the proof the fix works. If you can't demonstrate the red → green cycle, you don't have a valid bug-exposing test.
5. **Review test coverage** — Using the test reviewer's findings, decide what additional tests are needed (edge cases, breadth, depth, performance).
6. **Add tests** — Write the additional tests identified above.
7. **Fix any new issues** — If new tests expose problems, fix them.
8. **Confirm all clean** — Run all tests in scope plus lint, format, and typecheck. **Zero failing tests — no exceptions.** If pre-existing tests are failing, fix them. If infrastructure is broken (missing packages, wrong paths, flaky parallelism), that's the work. The Failing row in the report must be 0.
9. **Present quality gate report** — Share the report (format below) inline in the conversation. Add it to the Plan.
10. **Commit** — behavior depends on the boundary type:
    - **Iteration boundary** (via `/iteration-complete`): Commit automatically using `/git-safe-commit`. No approval needed. Present the QGR inline and move to the next iteration.
    - **Phase boundary** (via `/phase-complete`): Present the QGR and proposed commit message. **Wait for principal approval** before committing. This is a Sprint Review — the principal reviews the body of work.

### Commit Discipline

- **Always use `/git-safe-commit`** — never run raw `git commit`. The `/git-safe-commit` skill enforces the project's commit message conventions.
- **Iteration complete** — run `/iteration-complete`. QG scoped to changes, auto-commit after clean Quality Gate Report (QGR). No approval needed.
- **Phase complete** — run `/phase-complete`. Squashes iterations, deep QG (full codebase), Sprint Review, approval required, lands on master.
- **Plan complete** — run `/plan-complete`. Final deep QG, finalize Product Vision & Requirements (PVR) / Architecture & Design (A&D) / Plan, produce Reference doc. Captain creates PRs.
- **Before starting a new phase** — run `/pre-phase-review`. Reviews PVR, A&D, and Plan with multiple agents. Gets clearance.

### Quality Gate Report (QGR)

After completing steps 1–8, present a Quality Gate Report (QGR) to the user in this format:

```
## Quality Gate Report

### Issues Found and Fixed

| ID | Type | Summary | Via | Tests Added |
|----|------|---------|-----|-------------|
| 1 | bug/config/design/ux/security/performance | Description | Inspection/Test/Static Check | `test name` (purpose, type, count) or N/A |

Issue types: bug, config, design, ux, security, performance
Via: Inspection (review agents + own review), Test (found by running tests), Static Check (lint/typecheck)
Tests Added format: `test name` (bug-exposing|coverage, unit|integration|e2e-cli|e2e-browser|api|performance, count)

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

**Stage 1 — Parallel Review**
- N code review agents (describe focus areas)
- N test review agents (describe focus areas)
- Own review (describe what you looked at)

**Stage 2 — Consolidate**
- N issues identified, deduplicated from N reviewers
- Breakdown by type

**Stage 3 — Bug-Exposing Tests**
- N tests written targeting issues [list IDs]
- Red→green cycle confirmed for all N tests (each failed before fix, passed after)

**Stage 4 — Fix Issues**
- All N issues fixed
- N found by inspection, N found by test, N found by static check

**Stage 5 — Coverage Review**
- Describe gaps identified by test reviewers

**Stage 6 — Add Coverage Tests**
- N coverage tests added

**Stage 7 — Fix New Issues**
- N additional issues found while fixing (or "None")

**Stage 8 — Confirm Clean**
- Lint: result
- Format: result
- Tests: N/N pass, 0 failing

### What Was Found and Fixed

Plain-language summary grouped by issue type. For each issue: one sentence describing the problem, one sentence describing the fix. This is in addition to the tables — it makes the report scannable.

### Proposed Commit
- **Message:** structured commit message (format and example below)
- **Files:** list of files to be staged
```

At **iteration boundaries**, commit automatically after a clean QGR — no approval needed. At **phase and plan boundaries**, the principal must approve before committing.

### Commit Message Format

Commit messages must be detailed and structured. They are the permanent record of what was done, why, and what the quality gate caught. Reference the plan file so future readers can find context.

**Structure:**

```
prefix: concise summary — iteration/phase context

One-paragraph explanation of what this adds and why. Reference the
audit issue IDs or feature requirements being addressed.

Plan: docs/plans/YYYYMMDD-slug.md

What was built:
- Module/feature 1: details
- Module/feature 2: details

Quality gate (N-agent review + consolidation) — N issues fixed:
- #ID type (via): description (what was done)
- #ID type (via): description (what was done)

Tests: N passing (N new: N bug-exposing, N coverage), 0 failing
- Unit: N new (description)
- E2E: N new (description)

Also: any other changes bundled in this commit.
```

**Example (Phase 1, Iterations 1-2 of deployment infrastructure):**

```
feat: preview local + prototype router + create fix — Phase 1.1-1.2

Adds local preview environment support via /preview local, creates
/prototype and /preview router commands for noun-verb naming (DD-10),
and rewrites /prototype-create with discussion-first flow.

Plan: docs/plans/20260322-deployment-infrastructure-local-cloud-preview-staging-production.md

What was built:
- /preview local: tools/preview-local.ts + preview-local-down.ts
  wrapping Docker dev stack with port allocation, .env.local generation
- /preview router: .claude/commands/preview.md (local/down/list)
- /prototype router: .claude/commands/prototype.md (all subcommands)
- /prototype-create rewrite: worktree-first, two-track flow
- Shared utils: tools/lib/preview-utils.ts (sanitizeName, etc.)

Quality gate (4-agent review + consolidation) — 16 issues fixed:
- #1 bug (inspection): shell injection via unquoted composePath (spawnSync)
- #4 bug (inspection): getPortsOrThrow unhandled exception (clean exit)
- #7 security (inspection): Bash(curl:*) unrestricted (scoped to localhost)
- #8 bug (inspection): unlinkSync swallowed all errors (ENOENT only)
- #13 bug (test): web-audit-crawl.ts broken imports after migration
- #15 config (test): playwright core package not installed
- #16 bug (test): E2E tests flaky under parallel execution (sequential)

Tests: 334 passing (21 new: 8 bug-exposing, 13 coverage), 0 failing
- Unit: 15 new (sanitizeName edge cases, FRONTEND_APPS, unlinkSync)
- E2E (CLI): 6 new (clean exit on missing preview, error messages,
  spawnSync verification)

Also: fixed 8 pre-existing web-audit test failures, updated quality
gate report format in CLAUDE.md.
```

### Plan Updates

After **every commit**, update the plan file (`docs/plans/`) to reflect:

- What was done in this commit (iteration/phase status change)
- What the quality gate found (bugs fixed, test gaps closed)
- Any changes to the plan itself (scope adjustments, reordering, new findings)
- Iteration-level status table for multi-iteration phases
- **Append the full quality gate report** (all three tables + summary) under a "Quality Gate Reports" section at the end of the plan file. Each phase/iteration gets its own subsection.

The plan file is the living record of the work. It must always reflect reality. The quality gate reports live in the plan — no separate files, no separate process.

### Living Documents

Three documents evolve together through the lifecycle of a project:

1. **Product Vision & Requirements (PVR)** — what we need and why. Captured during discovery/discussion. May start as rough notes and get refined.
2. **Architecture & Design (A&D)** — the technical decisions, naming conventions, system structure, and design rationale. Flows from requirements, updated as we learn through implementation. Includes design decisions (DD-N).
3. **Plan** — what we're doing, phase by phase. Includes quality gate reports as receipts. Updated after every commit.

See **File Organization** under Development Methodology for canonical paths.

The flow: **Requirements → Architecture & Design + Plan (evolving together through iteration) → Reference**

At plan completion, the requirements, architecture, and plan are used to produce a **Reference** document — the final "this is how it works" documentation. The living documents are the journey; the reference is the destination.

All three are living documents during active work. Update architecture and design decisions as you learn — don't wait until the end. The plan captures what was done; the architecture captures why it was done that way.

### Quality Gate Tooling

**Built:**

- **Test classification** — `tools/lib/quality-gate.ts`: `classifyTestFile()` classifies by file path patterns (e2e-browser > e2e-cli > integration > api > performance > unit)
- **Report generation** — `tools/quality-gate-report.ts` (`pnpm quality-gate:report`): runs vitest + lint + format, outputs partial QGR skeleton with Coverage Health and Checks tables pre-filled
- **Table generators** — `generateCoverageHealthTable()`, `generateAccountabilityTable()`, `generateChecksTable()` produce exact QGR markdown format
- **Boundary commands:**
  - `/iteration-complete` — QG scoped to changes, auto-commit, no approval needed
  - `/phase-complete` — squash iterations, deep QG (full codebase), Sprint Review, approval, land on master
  - `/plan-complete` — final deep QG, finalize PVR/A&D/Plan, produce Reference doc
  - `/pr-prep` — QG scoped to full diff vs origin/master, before PR creation
  - `/pre-phase-review` — multi-agent review of PVR, A&D, Plan before starting a new phase
- **Stage hash utility** — `tools/lib/stage-hash.ts` + CLI `tools/stage-hash.ts`: computes deterministic 7-char hash from git staging area (SHA-256 of sorted index entries). Used for QGR receipt filenames.
- **QGR receipt files** — standalone files at `usr/{principal}/{project}/qgr-{boundary}-{phase-iter}-{stage-hash}-YYYYMMDD-HHMM.md`. Written by `/quality-gate` Step 10. `/git-safe-commit` checks for a matching receipt before committing.
- **`/git-safe-commit` QG-awareness** — computes stage hash, globs for matching QGR receipt. Found = proceed. Not found = warn and ask. `--force` skips the check for non-QG commits.
- **Hookify enforcement rules:**
  - `hookify.require-qgr.local.md` — warns on `git commit` if QGR checklist not completed
  - `hookify.require-plan-update.local.md` — warns on `git commit` if plan file not in staged changes
  - `hookify.no-push-master.local.md` — blocks push to master
  - `hookify.warn-on-push.local.md` — warns on any `git push`

**TODO:**

- **Red→green enforcement** — mechanically verify that bug-exposing tests failed before the fix and passed after. Currently process-enforced, not tool-enforced.
- **Config validation** — parse `allowed-tools` in command `.md` files and cross-reference against Bash commands in the markdown. Move config issues from "found by inspection" to "found by static check."
- **Coverage tracking over time** — persist the Coverage Health table per commit so we can see trends.
- **Living document scaffolding** — when creating a plan, auto-scaffold PVR, A&D, and Plan files with consistent structure.
