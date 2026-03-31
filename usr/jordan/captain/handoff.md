# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 8)

## Current State

On `feat/tool-refactor` branch. All 3 commits landed, quality gates passing. Branch ready for PR.

## Session 8: Tool Refactor + QG Hardening + Computer Use Feedback

### Dispatch 5: Tool Refactor (COMPLETE)

Three commits on `feat/tool-refactor`:

1. **489ddb6** — Delete 24 deprecated tools, clean agency-service refs from hooks/settings
2. **9dee22b** — Move ~95 tools from `tools/` → `claude/tools/`, rename (git-commit, git-tag, git-sync, agency-whoami, tool-create), new tools (git-fetch, telemetry), standardize JSONL logging, fix all paths/refs, fix code-review false positive on subshell secret assignments
3. **d6e7a6b** — Update TOOL.sh/PROVIDER.sh templates, CLAUDE.md, all test files, add missing permissions (agent-define, handoff, icloud-setup, plan-capture, starter-release, starter-update)

### Dispatch 6: QG Hardening (COMPLETE)
Verified all 17 QG fixes from PR #16 are integrated.

### Computer Use MCP (COMPLETE)
Filed 3 feedback issues with Anthropic about permissions UX, version-pinned binary paths, and Safari browser restrictions.

## Next Steps

1. **Create PR** for `feat/tool-refactor` → `main`
2. **Fetch new dispatch from origin** — user said "pull from origin. You have a dispatch. It is for us to /discuss and then you to plan."
3. **Remaining dispatches**: 3 (ISCP Design, /discuss) and 4 (Browser Protocol, /discuss)

## Dispatch Queue

| # | Dispatch | Status | Branch/PR |
|---|----------|--------|-----------|
| 1 | Plugin Provider Framework | MERGED | PR #9 + PR #12 |
| 2 | Agency 2.0 Bootstrap | MERGED | PR #14 |
| — | Workstream Bootstrap | MERGED | PR #15 |
| 3 | ISCP Design | NOT STARTED | `/discuss` session |
| 4 | Browser Protocol | NOT STARTED | `/discuss` session |
| 5 | Tool Refactor | DONE | `feat/tool-refactor` (needs PR) |
| 6 | QG Hardening | DONE | Verified |
| NEW | (on origin) | NOT FETCHED | `/discuss` + plan |

## Open Issues

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

## Git State

- Branch: `feat/tool-refactor` (3 commits ahead of main)
- HEAD: d6e7a6b
- Working tree: clean (except handoff)
