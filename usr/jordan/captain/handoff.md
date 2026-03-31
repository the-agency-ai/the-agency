# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 8, post-compact)

## Current State

On `feat/tool-refactor` branch. 7 commits ahead of main (including merge of origin/main). All quality gates passing. Ready for PR.

## Session 8 Work

### Dispatch 5: Tool Refactor (COMPLETE — 5 commits + merge)

1. **489ddb6** — Delete 24 deprecated tools, clean agency-service refs
2. **9dee22b** — Move ~95 tools `tools/` → `claude/tools/`, rename (git-commit, git-tag, git-sync, agency-whoami, tool-create), new tools (git-fetch, telemetry), standardize JSONL logging, fix code-review false positive
3. **d6e7a6b** — Update TOOL.sh/PROVIDER.sh templates, CLAUDE.md, all test files, add missing permissions
4. **f67e11b** — Update all docs (17 files), agent templates (12 files), commands (3 files), hookify rules (3 files), agency-init shipped tool list + permissions, captain agent.md
5. **eddd5b2** — Clean stale tool refs from agent templates (collaborate, doc-commit, test-coverage)

Also merged origin/main which brought in two new dispatches.

### Dispatch 6: QG Hardening (COMPLETE)
Verified all 17 QG fixes from PR #16.

### Computer Use MCP Feedback (COMPLETE)
Filed 3 issues via `/feedback`.

### Token Economics (PARTIAL — from new dispatch)
- Refined `warn-compound-bash` hookify rule: added `exclude_pattern` for heredoc commits, `PATH=... bash -c`, stderr redirects, head/tail pipes
- Remaining items: hook output audit, context-budget tool, CLAUDE.md size reduction

## New Dispatches (from origin)

Two dispatches fetched and merged:

1. **Code Survey / Incremental Capture** (`dispatch-agency-code-survey-tool-20260331.md`)
   - Problem: review/explorer agents exhaust context on large codebases
   - Proposed: incremental capture pattern (write findings as you go)
   - Recommended: Option B (document-as-you-go) → Option C (multi-session chain)
   - Status: READ, needs `/discuss` + plan

2. **Token Economics Tools** (`dispatch-agency-token-economics-tools-20260331.md`)
   - 5 items: /git-commit skill, compound bash refinement, hook output minimization, system reminder compression, context budget estimation
   - Status: Item 2 (compound bash) DONE. Rest needs `/discuss` + plan

## Next Steps

1. **Create PR** for `feat/tool-refactor` → `main` — run through QG first
2. **`/discuss` the new dispatches** — both are for discussion then planning
3. **Remaining dispatch queue**: 3 (ISCP Design), 4 (Browser Protocol)

## Dispatch Queue

| # | Dispatch | Status |
|---|----------|--------|
| 1 | Plugin Provider Framework | MERGED |
| 2 | Agency 2.0 Bootstrap | MERGED |
| — | Workstream Bootstrap | MERGED |
| 3 | ISCP Design | NOT STARTED |
| 4 | Browser Protocol | NOT STARTED |
| 5 | Tool Refactor | DONE (needs PR) |
| 6 | QG Hardening | DONE |
| 7 | Code Survey / Incremental Capture | READ (needs /discuss) |
| 8 | Token Economics Tools | PARTIAL (needs /discuss) |

## Open Issues

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

## Git State

- Branch: `feat/tool-refactor` (7 commits ahead of main)
- HEAD: eddd5b2
- Working tree: clean (except handoff)
