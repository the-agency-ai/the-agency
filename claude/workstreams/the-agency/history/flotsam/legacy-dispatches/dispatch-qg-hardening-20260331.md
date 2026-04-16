# Dispatch: QG Hardening — Framework Tools & Telemetry

**Date:** 2026-03-31
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** Medium — applied. Tools updated, captain should verify integration.

---

## What Changed

17 issues found and fixed across 4 shared framework files during a 3-agent quality gate (code, security, design reviewers). All fixes ported from monofolk to the-agency to keep framework tools identical.

## Files Modified

| File | Changes |
|------|---------|
| `claude/tools/lib/_log-helper` | printf-based JSON → jq --arg (all 3 functions), python3 failure warning on stderr, echo→printf for args |
| `claude/hooks/tool-telemetry.sh` | eval+@sh → individual jq calls, ERR trap no stdout, Bash logs first token only, Agent desc newline collapse, agency/principal/agent fields |
| `claude/tools/handoff` | TRIGGER sanitization, git-failure guard, nullglob, log_start top-level, log_end unconditional, archive→_do_archive, temp file cleanup trap |
| `claude/tools/plan-capture` | sed→parameter substitution, title quote escaping, ERR trap emits warning, transcript path validation, --list instrumented with tool_output+nullglob |

## Security Fixes (Critical)

1. **eval+@sh injection** — `tool-telemetry.sh` used `eval "$(jq -r @sh ...)"` on stdin JSON. Replaced with individual `jq -r` calls. No eval anywhere.
2. **Secret leakage** — Bash commands were logged verbatim to telemetry (could contain `doppler run --`, API keys). Now logs first token only (binary name).
3. **sed injection** — `TRIGGER` value was interpolated raw into sed replacement. Now sanitized to `[A-Za-z0-9_-]`.
4. **Path traversal** — `TRANSCRIPT_PATH` from hook stdin was used without validation. Now allowlisted to `~/.claude/` and `$CLAUDE_PROJECT_DIR/`.

## Correctness Fixes

5. **printf JSON corruption** — `_log-helper` used printf `%s` inside JSON strings. Backslashes, quotes, control chars produced invalid JSONL. Replaced with `jq --arg` (proper escaping).
6. **sed regex in path** — `PROJECT_DIR` with `.`, `+`, `[` broke path stripping. Replaced with `${var#prefix}`.
7. **YAML frontmatter** — Plan titles with double quotes produced invalid YAML. Now escaped.
8. **Git failure path** — Detached HEAD / git failure resolved slug to "unknown", writing handoff to wrong dir. Now returns error.
9. **Orphaned JSONL entries** — `log_end` wasn't called on hook trigger paths. Now unconditional.
10. **Temp file leak** — `mktemp` in `/tmp` with no cleanup trap. Now same-dir mktemp + EXIT trap.

## Design Fixes

11. **log_start consistency** — Moved to top-level (matches agent-define pattern).
12. **archive duplication** — `archive` subcommand now calls `_do_archive` instead of duplicating.
13. **ERR trap visibility** — plan-capture hook now emits systemMessage on unexpected failure.
14. **--list instrumentation** — Now uses tool_output pattern with logging.
15. **nullglob** — `usr/*/` glob now uses nullglob to avoid iterating literal patterns.
16. **python3 warning** — `_uuid7` now emits stderr warning when python3 unavailable.
17. **Agent description newlines** — Collapsed before concatenation in telemetry summary.

## What the Captain Should Do

1. **Verify integration** — Run `bash claude/tools/handoff path` and `bash claude/tools/handoff --version` to confirm tools load correctly.
2. **Existing tools** — When migrating existing tools to `claude/tools/` (per dispatch-tool-refactor-20260330), use the updated `_log-helper` patterns (jq --arg, not printf).
3. **New tools** — All new tools should source `claude/tools/lib/_log-helper` and follow the patterns in `handoff` and `plan-capture`.
4. **Telemetry hook** — Already updated. No captain action needed.

## Relationship to Tool Refactor Dispatch

This dispatch is a **prerequisite** to `dispatch-tool-refactor-20260330.md`. The refactor dispatch calls for migrating all tools to source `claude/tools/lib/_log-helper` — the version in this PR is the one to use. The security and correctness fixes here ensure the foundation is solid before the migration.
