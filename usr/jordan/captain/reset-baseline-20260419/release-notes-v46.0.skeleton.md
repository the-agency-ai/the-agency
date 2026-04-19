# The Agency v46.0 Release Notes — SKELETON (Phase 6 finalizes)

**Status:** SKELETON only. Phase 6 fills every section; Gate 6 blocks PR
creation if any §0d slot is empty.

**Tag:** v46.0
**Date:** <TODO: Phase 6 date>
**Branch:** v46.0-structural-reset

---

## TL;DR

<TODO: 2 lines. Example shape:
  "v46.0 renames `claude/` → `agency/` across the whole framework. Run
   `agency-migrate-prep --apply --yes` before `agency update --migrate`."
>

## Why now (bootstrap paradox acknowledgment)

<TODO: Plan v4 §0 paradox explanation. One-time transitional condition,
not a pattern. References captain-private alias-shim approach (Principle 12).>

## What changed (adopter-visible; per-change impact)

- **Directory rename `claude/` → `agency/`**
  - Adopter impact: see runbook § migration-paths for all 5+ path categories
- **New top-level `src/` dir**
  - Adopter impact: none (source-code tree, not runtime)
- **New canonical class `design-lead`**
  - Adopter impact: if your repo registers a design agent, consider
    `@import @agency/agents/design-lead/agent.md` as the new canonical.
    Legacy `agency/agents/designex/` class directory replaced;
    `agency-migrate-prep` rewrites `@import @agency/agents/designex` references automatically.
- **Agent templates relocated from `agency/agents/templates/` to `agency/templates/`**
  - Adopter impact: any reference to `agency/agents/templates/` swept automatically
- **9 non-class agents archived to `src/archive/agents/`**: apple, cos, discord,
  gumroad, iscp, marketing-lead, platform-specialist, project-manager, testname
  - Adopter impact: if your repo has `@import @agency/agents/{name}` OR
    `.claude/agents/*/{name}.md`, see runbook § agent-migration

## What's preserved

- `usr/` principal sandboxes — untouched
- workstream data in `agency/workstreams/*/` — content preserved verbatim
- `@import` semantics — only the path prefix changes
- **test fixture at `test/test-agency-project/` (embedded git repo — fixture's
  internal `claude/` references preserved verbatim as historical fixture content;
  adopters take no action on it)**
- dispatches + flags (ISCP DB) — format stable

## What's broken (migration-required — ≥5 breaking-path categories)

<TODO: Phase 6 fills with before/after examples for each category>

1. **`.claude/settings.json` hook paths**
   - Before: `$CLAUDE_PROJECT_DIR/claude/hooks/foo.sh`
   - After: `$CLAUDE_PROJECT_DIR/agency/hooks/foo.sh`

2. **Root `CLAUDE.md` @imports**
   - Before: `@agency/CLAUDE-THEAGENCY.md`
   - After: `@agency/CLAUDE-THEAGENCY.md`

3. **Skill `required_reading:` frontmatter**
   - Before: `required_reading: agency/REFERENCE-QUALITY-GATE.md`
   - After: `required_reading: agency/REFERENCE-QUALITY-GATE.md`

4. **Agent registration `@import` headers**
   - Before: `@import @agency/agents/captain/agent.md`
   - After: `@import @agency/agents/captain/agent.md`

5. **Tool invocation paths (examples)**
   - Before: `./agency/tools/handoff`
   - After: `./agency/tools/handoff`

## Migration summary

See `migration-runbook-v46.0.md` for step-by-step prep + update + verify + rollback.

## Rollback (3 paths)

1. **Origin tag**: `git reset --hard v45.3-pre-reset` (forces full-repo rollback)
2. **Adopter-local tag**: `git reset --hard v45.3-pre-reset-local` (created by prep)
3. **Tool-assisted**: `./agency/tools/agency-update-migrate-back` (BATS-tested
   round-trip; includes dispatch rescue)

## Known diagnostic signatures (post-migration failures)

- `Hook fire ENOENT agency/hooks/*.sh` → settings.json not rewritten
- `@import resolve error` at session start → CLAUDE.md @import stale
- `required_reading not found` → skill frontmatter stale
- `agency-verify-v46 --customer` exit 10..14 → tree/settings/registration/ISCP anomaly

## Contact path

`agency-report` tool auto-opens a cross-repo issue with diagnostic + dispatches
to `the-agency/captain`. If that fails, manual issue filing at
https://github.com/the-agency-ai/the-agency/issues/new.

## Link to A&D

`agency/workstreams/the-agency/ad-the-agency-structural-reset-20260419.md`
(for mechanics-curious).
