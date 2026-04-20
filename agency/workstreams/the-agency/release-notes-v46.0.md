# The Agency v46.0 Release Notes

**Tag:** v46.0
**Date:** 2026-04-20
**Branch:** v46.0-structural-reset
**Base:** v45.3
**Rollback anchor:** `v45.3-pre-reset` (tagged on origin)

---

## TL;DR

v46.0 is a **structural reset** — the framework code directory renames from `claude/` to `agency/` across the whole repo (hooks, tools, hookify, config, skills' `required_reading`, agent registrations, and every `@import`). One-time breaking change; every adopter migrates once and then stays on the new path forever.

**Adopters run:** `./agency/tools/agency-migrate-prep --apply --yes` → `./agency/tools/agency-update-migrate --migrate` → `./agency/tools/agency-verify-v46 --customer`. Exit 0 on verify = done.

## Why now — the bootstrap paradox

The framework's own tooling lives at `claude/tools/`, `claude/hooks/`, etc. Renaming those paths requires those same tools to execute the rename — a circular dependency. We resolved it with a **captain-private alias-shim** during the reset window: a transient symlink that let tools resolve from either old or new path while the rename happened atomically.

This is a one-time transitional condition, not a pattern. The shim existed only between Phase 1 (Great Rename) and Phase 4.5 (restored settings.json), and was removed before the branch was published.

## What changed (adopter-visible)

### Rename: `claude/` → `agency/`

Every path under the framework root moves. Five adopter-facing categories:

| Category | Impact |
|----------|--------|
| `.claude/settings.json` hook command paths | `$CLAUDE_PROJECT_DIR/claude/hooks/*.sh` → `$CLAUDE_PROJECT_DIR/agency/hooks/*.sh` |
| Root `CLAUDE.md` `@import` | `@claude/CLAUDE-THEAGENCY.md` → `@agency/CLAUDE-THEAGENCY.md` |
| Skill `required_reading:` frontmatter | `required_reading: claude/REFERENCE-*.md` → `required_reading: agency/REFERENCE-*.md` |
| Agent registration `@import` | `@import @claude/agents/captain/agent.md` → `@import @agency/agents/captain/agent.md` |
| Tool invocation paths in scripts / docs | `./claude/tools/handoff` → `./agency/tools/handoff` |

### New top-level `src/` dir

Source code tree separates from operating-framework tree. `src/archive/` holds retired code. Adopter impact: none for runtime behavior.

### New canonical class `design-lead`

`agency/agents/designex/` class directory has been replaced by `agency/agents/design-lead/`. Any registration using `@import @claude/agents/designex/agent.md` should be rewritten to `@import @agency/agents/design-lead/agent.md`. `agency-migrate-prep` handles the rewrite.

### Agent templates relocated

From `agency/agents/templates/` to `agency/templates/`. `agency-migrate-prep` handles the rewrite.

### 9 non-class agents archived to `src/archive/agents/`

apple, cos, discord, gumroad, iscp, marketing-lead, platform-specialist, project-manager, testname — moved out of active agents dir. If your repo has `@import @claude/agents/{name}` or a registration at `.claude/agents/*/{name}.md`, see the runbook § agent-migration.

## What's preserved

- **`usr/`** principal sandboxes — untouched
- **`agency/workstreams/*/`** workstream data — content preserved verbatim
- **`@import` semantics** — only the path prefix changes; resolution still `@{path}` → `{repo-root}/{path}`
- **`test/test-agency-project/`** embedded git-repo fixture — internal `claude/` references preserved as historical fixture content; adopters take no action
- **ISCP DB (dispatches + flags)** — schema and payload format stable

## What's broken (migration-required)

The five categories in the table above. Every category has a before/after above; the runbook gives step-by-step migration.

## Known coverage gaps (not blocking)

- **Hookify canary:** 36 of 42 rules have `.canary` fixtures verifying they fire correctly. 6 rules un-synthesizable under the current canary runner (prose bodies, PCRE lookbehinds, glob patterns). Tracked in issue #350. Not a runtime risk — the rules themselves fire correctly; only the test harness can't exercise them.
- **Phase 4 sweep residual misses:** a small set of framework tools still contain v45-path references (cosmetic comments, examples in `run-in`, `safe-extract`, `release-plan`; migration-critical dual-path handling in `_agency-update`). Flagged at captain flag #195. No adopter impact — these are framework-internal docs and comments.

## Rollback (3 paths)

1. **Origin tag (full rollback):** `git reset --hard v45.3-pre-reset` then `git push --force-with-lease origin master`. Anchor tagged on origin before Phase 1.
2. **Adopter-local tag:** `git reset --hard v45.3-pre-reset-local`. Created automatically by `agency-migrate-prep`.
3. **Tool-assisted:** `./agency/tools/agency-update-migrate-back`. BATS-tested round-trip. Includes **dispatch rescue** for any v46-format dispatches created between `--migrate` and rollback — scans, renames to v45-format paths, writes `.agency/migrate-back-rescue-v46.log`.

## Known diagnostic signatures (post-migration failures)

| Signature | Cause |
|-----------|-------|
| `Hook fire ENOENT claude/hooks/*.sh` | `.claude/settings.json` not rewritten — still references v45 hook paths |
| `@import resolve error` at session start | `CLAUDE.md` `@import` still uses `@claude/` prefix |
| `required_reading not found` when skill runs | Skill frontmatter still references `claude/REFERENCE-*.md` |
| `agency-verify-v46 --customer` exit 10 | tree-shape mismatch: `claude/` still present OR `agency/` missing |
| `agency-verify-v46 --customer` exit 11 | settings.json still references `/claude/hooks/` |
| `agency-verify-v46 --customer` exit 12 | agent registration still uses `@claude/agents/` |
| `agency-verify-v46 --customer` exit 14 | hook file ENOENT — settings.json points at a path that doesn't exist on disk |

## Contact path

`./agency/tools/agency-report` generates a diagnostic bundle and can auto-open a cross-repo issue + dispatch to `the-agency/captain`. Manual filing: https://github.com/the-agency-ai/the-agency/issues/new.

## Reference

- Plan v4: `agency/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md`
- A&D: `agency/workstreams/the-agency/ad-the-agency-structural-reset-20260419.md`
- PVR: `agency/workstreams/the-agency/pvr-the-agency-structural-reset-20260419.md`
- Migration runbook: `agency/workstreams/the-agency/migration-runbook-v46.0.md`
- Follow-up issue (canary gap): https://github.com/the-agency-ai/the-agency/issues/350
- Follow-up issue (sizing skill): https://github.com/the-agency-ai/the-agency/issues/349
