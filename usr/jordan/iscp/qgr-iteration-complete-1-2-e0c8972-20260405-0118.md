# Quality Gate Report — Iteration 1.2

**Boundary:** iteration-complete
**Phase.Iteration:** 1.2
**What:** `_iscp-db` library — shared SQLite abstraction for all ISCP tools
**Stage hash:** `e0c8972`
**Date:** 2026-04-05 01:18 UTC
**Agent:** the-agency/jordan/iscp

---

## Issues Found and Fixed

| ID | Severity | Category | File | Description | Status |
|----|----------|----------|------|-------------|--------|
| 1 | High | injection | `_iscp-db` | Newlines in param values break `.param set` dot-command and allow sqlite3 dot-command injection (`.shell`). Added `\n`, `\r`, `\t` escaping to `_iscp_escape_param`. | Fixed ✓ |
| 2 | High | injection | `_iscp-db` | Parameter name validation only checked `:` prefix. Names with spaces/special chars could break `.param set`. Tightened to `^:[a-zA-Z_][a-zA-Z0-9_]*$`. | Fixed ✓ |
| 3 | Medium | logic-error | `_iscp-db` | Odd parameter count silently dropped at two levels. Added explicit check in `_iscp_build_params` and changed caller guard from `$# -ge 2` to `$# -gt 0`. | Fixed ✓ |
| 4 | Medium | data-exposure | `_iscp-db` | DB file created with default umask (potentially world-readable). Added `umask 077` around schema creation. | Fixed ✓ |
| 5 | Medium | convention | `_iscp-db` | Pipe chains (`sed | sed | sed`) violate bash convention. Replaced with bash parameter expansion where possible; remaining uses consolidated to single `sed` invocations. | Fixed ✓ |
| 6 | Medium | documentation | `_iscp-db` | `$table` and `$ts_col` interpolated as SQL identifiers without comment explaining the exception to "never interpolate." Added comment documenting whitelist protection. | Fixed ✓ |
| 7 | Medium | test | `iscp-db.bats` | No test for double-quote escaping — core injection defense with zero coverage. Added test. | Fixed ✓ |
| 8 | Medium | test | `iscp-db.bats` | No test for backslash escaping. Added test. | Fixed ✓ |
| 9 | Medium | test | `iscp-db.bats` | No test for `iscp_db_exec` success path. Added INSERT and UPDATE tests. | Fixed ✓ |
| 10 | Medium | test | `iscp-db.bats` | Weak assertion in "stores all fields" — substring match couldn't distinguish columns. Added exact-match test with unique branch value. | Fixed ✓ |
| 11 | Medium | test | `iscp-db.bats` | `iscp_db_update_status` only tested for flags. Added dispatch status update test. | Fixed ✓ |
| 12 | Medium | test | `iscp-db.bats` | `iscp_db_count_unread` only tested flags. Added test with dispatches + dropbox items. | Fixed ✓ |

## Quality Gate Accountability

| Agent | Findings | Passed Threshold (≥50) | Fixed |
|-------|----------|----------------------|-------|
| reviewer-code | 13 | 7 | 7 |
| reviewer-security | 7 | 5 | 5 |
| reviewer-design | 14 | 8 | 8 |
| reviewer-test | 22 | 10 | 10 |
| reviewer-scorer | scored 17 findings, 12 passed threshold (≥50) | — | — |
| Own review | 3 | 3 | 3 |

(Many findings were duplicates across agents — deduplicated to 12 unique issues.)

## Coverage Health

| Area | Before QG | After QG |
|------|-----------|----------|
| Total BATS tests | 38 | 51 |
| Functions with direct tests | 6/8 public | 8/8 public |
| Escape/injection tests | 2 (single-quote, SQL injection) | 6 (+double-quote, backslash, newline, strict param name) |
| Multi-table tests | 0 (flags only) | 3 (dispatches, dropbox, notifications) |
| Error path tests | 3 | 5 |

## Checks

| Check | Status |
|-------|--------|
| BATS tests (51) | ✅ All pass |
| Format/lint | ✅ N/A (bash library) |
| Typecheck | ✅ N/A (bash) |

## Quality Gate Summary

**Stage 1 — Parallel Review**
- reviewer-code: 13 findings (newlines, odd params, weak assertions, YAML trimming, double-semicolon)
- reviewer-security: 7 findings (newline injection, param name injection, DB file permissions, heredoc expansion)
- reviewer-design: 14 findings (convention compliance, API consistency, YAML duplication, identifier interpolation)
- reviewer-test: 22 findings (escape coverage, exec coverage, multi-table coverage, agency.yaml resolution)
- reviewer-scorer: scored 17 unique findings, 12 passed threshold (≥50)
- Own review: 3 findings (newline same as agents, insert_flag API bypass, partial schema handling)

**Stage 2 — Consolidate**
12 unique findings after deduplication and scoring.

**Stage 3 — Bug-exposing tests**
7 red tests written: newline handling, double-quote escaping, backslash escaping, strict param name, odd param count, insert_flag without init, DB file permissions.

**Stage 4 — Fix**
All 12 findings fixed. Key fixes: newline/CR/tab escaping in `_iscp_escape_param`, strict regex for param names, odd-count rejection, `umask 077` for DB creation, pipe chain elimination, identifier interpolation documentation.

**Stage 5-6 — Coverage tests**
13 additional tests added covering: `iscp_db_exec` success paths, exact field matching, dispatch status updates, multi-table count_unread, agency.yaml resolution.

**Stage 7 — Fix new issues**
Error message update in test 24 (assertion matched old message text).

**Stage 8 — Confirm clean**
51/51 tests pass. No regressions.

## What Was Found and Fixed

The most critical finding was **newline injection in parameter values** (Finding 1) — a literal newline in a flag message or dispatch subject would break the sqlite3 `.param set` dot-command and could allow arbitrary command execution via `.shell`. This was a real security vulnerability in the core parameter handling. Fixed by escaping newlines, carriage returns, and tabs in `_iscp_escape_param`.

The second critical finding was **loose parameter name validation** (Finding 2) — only checking for a `:` prefix allowed names with spaces or embedded newlines that could break the `.param set` command. Fixed with strict `^:[a-zA-Z_][a-zA-Z0-9_]*$` regex.

Testing coverage improved substantially: from 38 to 51 tests, with all 8 public functions now directly tested, multi-table operations validated, and the core escaping logic covered for all character classes.

## Proposed Commit

**Message:**
```
Phase 1.2: _iscp-db library — shared SQLite abstraction for ISCP

Create claude/tools/lib/_iscp-db with: DB path resolution, idempotent
schema creation (6 tables), named parameter handling via .param set,
WAL mode, busy_timeout, foreign_keys, schema versioning. Includes
newline/CR/tab escaping for injection safety, strict param name
validation, and restrictive file permissions.

51 BATS tests covering: init, schema, parameters, escaping, injection,
status updates, unread counts, agency.yaml resolution, permissions.
```

**Files:**
- `claude/tools/lib/_iscp-db` (new)
- `tests/tools/iscp-db.bats` (new)
- `usr/jordan/iscp/qgr-iteration-complete-1-2-e0c8972-20260405-0118.md` (new — this receipt)
