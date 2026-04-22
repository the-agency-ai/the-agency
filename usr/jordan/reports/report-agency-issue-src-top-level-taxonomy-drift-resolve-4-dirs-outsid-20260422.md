---
report_type: agency-issue
issue_type: friction
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/420
github_issue_number: 420
status: open
---

# src/ top-level taxonomy drift — resolve 4 dirs outside V5 allowlist (assets, integrations, spec-provider, tools-developer)

**Filed:** 2026-04-22T02:17:46Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#420](https://github.com/the-agency-ai/the-agency/issues/420)
**Type:** friction
**Status:** open

## Filed Body

**Type:** friction

# Resolve src/ top-level taxonomy drift (assets, integrations, spec-provider, tools-developer)

## Surfaced by

Multi-agent structural audit during V5 Phase 4 v46.19 verification (2026-04-22). Reviewer: "4 unexpected top-level dirs at `src/` outside the documented allowlist: `src/assets/`, `src/integrations/`, `src/spec-provider/`, `src/tools-developer/`. Allowed set was `{agency, claude, tests, tools, apps, archive}`."

## Context

Per V5 plan (`/Users/jdm/.claude/plans/melodic-inventing-platypus.md`), the framework-dev `src/` allowlist is:

- `src/agency/` — framework sources that build to `agency/`
- `src/claude/` — Claude Code shippable subset
- `src/apps/` — application sources (mdpal, mdslidepal-web, etc.)
- `src/archive/` — retired code
- `src/tests/` — BATS + vitest fixtures
- `src/tools/` — framework-dev-only tools (the `build` tool)

The 4 drift items came in from earlier phase work (likely Phase 2 in plan v4) but weren't re-audited against v5's allowlist.

## Scope (decide + consolidate or relabel)

For each drift dir, one of:

### 1. `src/assets/`
- Content: framework brand assets (logos, marks, etc.)
- Allowlist decision: create new slot `src/assets/` in v5 plan OR move to `src/agency/assets/`
- My recommendation: **`src/agency/assets/`** — framework brand belongs with framework content

### 2. `src/integrations/`
- Content: `claude-desktop/` directory (IDE integration helpers)
- Allowlist decision: create `src/integrations/` OR move to `src/agency/integrations/`
- My recommendation: **`src/integrations/`** kept as top-level — integrations are a distinct ship unit (per-integration install paths), not part of the main framework ship

### 3. `src/spec-provider/`
- Content: starter-packs/ (SPEC-PROVIDER starter pack scaffolds for service-add, ui-add)
- Allowlist decision: new slot `src/spec-provider/` OR move to `src/agency/spec-provider/` OR `src/templates/`
- My recommendation: **`src/agency/templates/spec-provider-starter-packs/`** — starter packs are templates that ship with the framework

### 4. `src/tools-developer/`
- Content: dev-only tools like `skill-audit`, not shipped to adopters
- Allowlist decision: consolidate with `src/tools/` OR keep split (framework-dev shippable vs framework-dev-only)
- My recommendation: **merge into `src/tools/`** (which is already framework-dev-only by V5 spec) — eliminate the split. OR rename to `src/tools-dev/` for clarity if the split is intentional.

## Deliverable (single PR)

1. Principal 1B1 to confirm each disposition above
2. `git mv` each drift dir to its chosen destination
3. Update any references in tool code + docs
4. Run src/tools/build to regenerate build products (relevant dirs)
5. Update the V5 plan's target tree to reflect the final allowlist
6. Add a pre-commit lint or BATS test that fails if a non-allowlisted top-level src/ dir appears

## Acceptance

- [ ] All 4 drift dirs relocated (or new slots added to allowlist)
- [ ] V5 plan target tree section updated
- [ ] src/ top-level contains ONLY allowlisted slots
- [ ] No broken references to old paths
- [ ] Lint/test guard prevents regression

## Priority

**Medium** — not blocking but erodes plan-invariance. Schedule before Phase 5b (where the build tool gains schema-aware versioning — needs stable src/ taxonomy to parse frontmatter from known locations).

## Context

- V5 Phase 4 audit surfaced (2026-04-22)
- Pre-existing from earlier phase work (Phase 2 subdir reorg or later)
- Per principal 2026-04-22 directive: "fix or tag for immediate followup"

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/420
