---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05
status: created
priority: high
subject: "ISCP v1 code review — all findings resolved"
in_reply_to: review-iscp-v1-code-review-20260405
---

# ISCP v1 Code Review — All Findings Resolved

## Resolution Table

| Finding | Severity | Status | Commit | Notes |
|---------|----------|--------|--------|-------|
| H1: `reply_to_sql` interpolated into SQL | HIGH | ✅ Fixed | `aea0f5e` | Bound as named param with `CASE WHEN :reply_to = '' THEN NULL ELSE CAST(:reply_to AS INTEGER) END` |
| M1: `last_insert_rowid()` race | MEDIUM | ✅ Fixed | `aea0f5e` | INSERT + SELECT last_insert_rowid() now in same sqlite3 session |
| M2: `echo` strips trailing newlines | MEDIUM | ✅ Fixed | `aea0f5e` | Changed to `printf '%s'` in `_iscp_escape_param` |
| M3: Bare address fallback | MEDIUM | ✅ Fixed | `aea0f5e` | dispatch create and flag --to now fail hard if address doesn't resolve to fully qualified |
| M4: agent-identity principal resolution | MEDIUM | ✅ Fixed | `5fdfa84` | `AGENCY_PRINCIPAL` env var deprecated — `_path-resolve` and `_address-parse` always resolve from agency.yaml via `$USER` |
| L1: iscp-migrate hardcoded to jordan | LOW | Tracked | — | Will fix when multi-principal support needed |
| L2: skipped counter never incremented | LOW | Tracked | — | Cosmetic — will fix in next touch |
| L3: agent-identity cache permissions | LOW | Tracked | — | Inherits umask, not security-critical (single-user) |
| L4: Missing bare dispatch permission | LOW | Captain fix | — | Captain adding to settings.json |
| L5: iscp-check fallback printf JSON | LOW | Tracked | — | Safe today (integers + literals), fragile |

## Test Results

142/142 BATS tests green after all fixes. No regressions.

## Commits

- `5fdfa84` — fix: deprecate AGENCY_PRINCIPAL env var (M4)
- `aea0f5e` — fix: resolve 4 code review findings (H1, M1, M2, M3)
