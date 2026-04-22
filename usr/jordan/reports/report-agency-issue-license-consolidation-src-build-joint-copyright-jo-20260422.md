---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/413
github_issue_number: 413
status: open
---

# License consolidation (src→build) + joint copyright (Jordan + TheAgencyGroup) + trademark reservation

**Filed:** 2026-04-22T00:02:12Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#413](https://github.com/the-agency-ai/the-agency/issues/413)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

# License consolidation + joint copyright + trademark reservation

## Problem (two parts)

### Part A — Architecture

LICENSE content lives at two paths in main today (`LICENSE` repo root + `agency/LICENSE.md`), with no canonical source-of-truth. Per V5 Phase 4 "everything under src/" rule, framework sources belong under `src/`. But GitHub MIT-badge crawler needs LICENSE at repo root, and adopter `my-agency-repo/agency/LICENSE.md` needs LICENSE traveling with the framework install.

### Part B — Copyright + trademark amendments

Current copyright line is `Copyright (c) 2026 Jordan Dea-Mattson` in all 6 tracked license files. Principal directive 2026-04-22:
- Copyright should be jointly held by Jordan Dea-Mattson **and** TheAgencyGroup
- Reserve trademarks for TheAgency family + Valueflow + apps + mascots

## Deliverable

### 1. Architecture: single-source, build propagates

- **Canonical src:** `src/agency/LICENSE.md`
- **Build targets** (populated by Phase 5 Python build tool when it ships):
  - `agency/LICENSE.md` (framework-ship — travels to adopter `my-agency-repo/agency/`)
  - `LICENSE` (repo root — GitHub MIT-badge convention)
- **Interim (pre-Phase-5):** CI lint (`agency/tools/lint-license-sync` or `.github/workflows/license-sync.yml`) diffs the 3 paths; fails red on drift. Retires when build tool owns propagation.

Repo-root governance docs (LICENSE, README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, CHANGELOG.md) are NOT exceptions to the "everything under src/" rule — all of them should have src-then-build shape once Phase 5 ships.

### 2. Copyright line (all 6 files)

```
Copyright (c) 2026-{current-year} Jordan Dea-Mattson and TheAgencyGroup
```

Rolling year; today `2026` bare, rolls each calendar year.

### 3. Trademark footer (appended after MIT or RSL body, all 6 files)

```markdown
---

## Trademarks

The following are trademarks of Jordan Dea-Mattson and TheAgencyGroup.
All rights in these marks are reserved.

Core framework:
  - "The Agency"
  - "TheAgency"
  - "TheAgencyGroup"
  - "Valueflow"

Apps and related works:
  - "MDPal"
  - "mdpal"
  - "MockAndMark"
  - "mockandmark"

Mascots (and their associated visual/textual representations):
  - "Attack Kittens"
  - "Attack Kitties"

Associated names, logos, and brand elements — including case variations
and stylistic permutations of the above — are also reserved.

This license grants permission to use, copy, modify, and distribute the
software, but does NOT grant any right or license to use these trademarks.
Use of the marks — in forks, derivative works, or redistributions —
requires separate written permission from Jordan Dea-Mattson and
TheAgencyGroup.

Forks and derivative works must be rebranded under a distinct name that
does not incorporate any of the reserved marks. Nominative fair use
(e.g., "compatible with The Agency") is permitted where accurate and
non-misleading.
```

### 4. Scope — 6 license files

| File | Type | Action |
|---|---|---|
| `LICENSE` (root) | MIT | amend copyright + trademark footer (build product after Phase 5) |
| `agency/LICENSE.md` | MIT | amend copyright + trademark footer (build product after Phase 5) |
| `src/agency/LICENSE.md` | MIT | **create** as canonical src + amend copyright + trademark footer |
| `agency/workstreams/mdpal/LICENSE` | RSL | amend copyright + trademark footer |
| `agency/workstreams/mock-and-mark/LICENSE` | RSL | amend copyright + trademark footer |
| `src/apps/mdslidepal-web/LICENSE` | RSL | amend copyright + trademark footer |

All 3 MIT files must be identical after this PR. All 3 RSL files share the same copyright line + trademark footer but differ in RSL body text (which is specific to each app).

### 5. CI lint (pre-Phase-5 interim)

- `.github/workflows/license-sync-check.yml` — runs on every PR
- Diffs:
  - `src/agency/LICENSE.md` ↔ `agency/LICENSE.md`
  - `src/agency/LICENSE.md` ↔ repo-root `LICENSE`
- Fails red on any drift; PR cannot merge

### 6. Phase 5 build tool wire-up (deferred to Phase 5, noted here)

When `src/tools/build` ships (V5 Phase 5), it reads `src/agency/LICENSE.md`, propagates to `agency/LICENSE.md` + root `LICENSE`. Lint workflow retires; build tool is the single propagation point.

## Acceptance

- [ ] `src/agency/LICENSE.md` created with amended content
- [ ] All 3 MIT files have identical content (root, `agency/LICENSE.md`, `src/agency/LICENSE.md`)
- [ ] All 3 RSL files have amended copyright line + trademark footer
- [ ] CI lint passes on clean tree, fails on intentional drift (test by introducing drift in a throwaway branch and confirming workflow fails)
- [ ] No node_modules or other vendored LICENSE files modified (only the 6 listed)
- [ ] QG passes (4 reviewers + 1 scorer)
- [ ] PR landed, release cut

## Context

- Principal 1B1: 2026-04-22 session, Item 2 of 6
- Related: Item 1 (dependency consolidation) issue #412
- Release target: v46.19 or whichever slot wins ordering
- V5 plan reference: `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/413
