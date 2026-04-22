---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/419
github_issue_number: 419
status: open
---

# Pre-existing pollution cleanup at agency/ build-product side (testname, test; rm -rf, test-auto QGRs, housekeeping workstream)

**Filed:** 2026-04-22T02:17:12Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#419](https://github.com/the-agency-ai/the-agency/issues/419)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

# Clean up pre-existing pollution at agency/ build-product side

## Surfaced by

Multi-agent structural audit during V5 Phase 4 v46.19 verification (2026-04-22). Reviewer found pollution present at agency/ + .claude/ build-product side that is NOT in src/ (source-of-truth), indicating leftover test artifacts + one taxonomy miss.

## Scope (delete + gitignore)

### 1. Test-leak directories (BATS pollution from earlier incidents)

- `agency/agents/testname/` — placeholder dir, likely from a BATS test that didn't clean up
- `agency/agents/unknown/` — same class of leak
- `.claude/agents/jordan/testname.md` — single-file leak

These should be covered by existing `.gitignore` entries from purge-test PR #387/#390 (`agency/agents/testname/`, `agency/agents/unknown/`, `.claude/agents/*/testname.md`). Verify they're tracked; if tracked, `git rm`.

### 2. Shell-injection-style directory name

- `agency/workstreams/test; rm -rf/` — literal directory name `test; rm -rf` under workstreams/

This is the exact pattern the test-pollution hookify + gitignore guards were built to catch. Must `git rm -rf` and verify no hookify rule is leaking the pattern.

### 3. Test-auto QGR leaks

- `agency/workstreams/devex/qgr/test-org-jordan-devex-devex-test-auto-qgr-iteration-complete-20260421-2005-eeee.md`
- `agency/workstreams/devex/qgr/test-org-jordan-devex-devex-test-auto-qgr-iteration-complete-20260421-2008-eeee.md`

Per gitignore rule `agency/workstreams/*/qgr/test-*-test-auto-*.md`, these should not be tracked. Verify + `git rm` if tracked.

### 4. Stale workstream dir (build-product-only)

- `agency/workstreams/housekeeping/` — exists at agency/ only, not in src/

Plan v4 called for this to migrate into `agency/workstreams/the-agency/` workstream. Per V5 plan Phase 3.5, consolidate:
- Content → `src/agency/workstreams/the-agency/`
- Delete `agency/workstreams/housekeeping/` from build-product side
- Rebuild

## Deliverable (single PR)

1. `git rm -r` each polluted path at agency/ + .claude/ sides
2. Verify existing gitignore rules block re-addition (or add missing rules)
3. Consolidate `agency/workstreams/housekeeping/` into `agency/workstreams/the-agency/` per plan
4. Re-run src/tools/build to confirm no stale files regenerated
5. Write a BATS test that asserts the polluted paths DO NOT exist in tracked state (preventive guard)

## Acceptance

- [ ] `git ls-files agency/agents/testname/` returns empty
- [ ] `git ls-files agency/agents/unknown/` returns empty
- [ ] `git ls-files '.claude/agents/*/testname.md'` returns empty
- [ ] `git ls-files 'agency/workstreams/test; rm -rf/'` returns empty
- [ ] `git ls-files agency/workstreams/*/qgr/test-*-test-auto-*.md` returns empty
- [ ] `agency/workstreams/housekeeping/` deleted; content migrated to `the-agency/` workstream
- [ ] BATS test shipped to prevent regression

## Priority

**IMMEDIATE followup** per principal 2026-04-22 directive. Ship as v46.20 or v46.21 (whichever slot wins ordering).

## Context

- V5 Phase 4 verification audit surfaced the items (2026-04-22)
- Related incidents: #387, #390 (purge-test pollution)
- PR #418 / v46.19 deferred these for scope control — landing in separate PR per principal "fix or tag for immediate followup"

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/419
