---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/417
github_issue_number: 417
status: open
---

# Add Python unit + integration tests for src/tools/build (on top of existing BATS)

**Filed:** 2026-04-22T01:59:07Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#417](https://github.com/the-agency-ai/the-agency/issues/417)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

# Add Python unit + integration tests for `src/tools/build`

## Context

V5 Phase 4 + Phase 5a shipped `src/tools/build` (Python 3.13+ stdlib build tool, 150 lines) with **CLI-level BATS coverage only** (18 tests in `src/tests/tools/build.bats`). Per the-agency convention, BATS exercises external CLI behavior regardless of implementation language.

Principal directive 2026-04-22: "Use BATS for CLI level tests. I'm fine with that. But create issue to actually build Python unit tests and integration tests for it later."

## Deliverable

Add Python-native tests on top of the existing BATS CLI coverage:

### 1. Unit tests (stdlib unittest, zero pip deps)

Target internal functions in `src/tools/build`:

- `find_repo_root()` — walks from CWD up to .git
  - Happy path: starts in subdir, finds root
  - Edge: CWD is the root
  - Edge: CWD is inside a nested git repo (should return nearest)
  - Edge: no .git anywhere → SystemExit via `die()`

- `mirror_tree(src, dst)` — copies file tree
  - Happy path: single file, returns 1
  - Happy path: nested dirs, returns total count
  - Empty src → returns 0, no side effects
  - Src doesn't exist → returns 0
  - Src is a file (not dir) → SystemExit via `die()`
  - Preserves file mode (executable + non-executable)
  - Overwrites existing dest files
  - Handles non-ASCII filenames
  - Handles filenames with spaces

- `die(msg)` — error helper
  - Prints to stderr
  - Exits with non-zero

### 2. Integration tests

Target end-to-end build scenarios:

- Full tree mirror (src/agency/ populated, src/claude/ populated) → both build products written correctly with correct counts
- Partial tree (only src/agency/ exists, src/claude/ missing) → 0 claude count, no errors
- Idempotent: second run produces identical output and same file contents
- Build from subdirectory CWD (walks up to find root)

### 3. Test harness choice

- **stdlib unittest** — zero dependencies, matches "zero-pip framework tool" rule for framework tooling
- Alternative considered + rejected: pytest (requires pip dep, violates zero-pip rule for src/tools/*)

### 4. Location

- `src/tests/tools/build_test.py` — unit tests
- `src/tests/tools/build_integration_test.py` — integration tests
- Run via: `python3 -m unittest src.tests.tools.build_test`

## Acceptance

- [ ] Both test files present + passing
- [ ] Total coverage (BATS + unittest) addresses every public function + CLI subcommand
- [ ] Zero pip deps (stdlib only)
- [ ] Tests run in isolated temp dirs (per test-pollution discipline from #387/#390)
- [ ] Both stand alongside BATS suite; running the full test battery covers all layers
- [ ] QG passes

## Priority

Post-v46.19 (which ships the bare build tool). Before Phase 5b (YAML frontmatter parsing, versioning) lands — Phase 5b is harder to test safely without a unit harness in place.

## Context

- Principal 1B1: 2026-04-22 session
- Surfaced by principal during Phase 4+5a PR creation ("What tests do you have for and what tests do you run for the build tool?")
- Companion PR that ships the BATS layer: v46.19 (fix/v5-phase-4-src-split)
- Related: V5 Phase 5b (full build-tool spec with frontmatter + manifest regen) should land with these tests already in place

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/417
