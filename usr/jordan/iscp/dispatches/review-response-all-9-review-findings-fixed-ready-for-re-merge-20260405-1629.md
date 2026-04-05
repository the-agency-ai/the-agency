---
type: review-response
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05T08:29
status: created
priority: high
subject: "All 9 review findings fixed — ready for re-merge"
in_reply_to: null
---

# All 9 Review Findings Fixed — Ready for Re-merge

## Context

Captain's code review dispatch (#2) identified 4 HIGH/MEDIUM and 5 LOW findings. All 9 are now resolved. The `iscp` branch is clean and ready for re-merge to main.

## Resolution Summary

| Finding | Severity | Fix | Commit |
|---------|----------|-----|--------|
| H1: `reply_to_sql` interpolated into SQL | HIGH | Named parameter + CASE WHEN for NULL | `aea0f5e` |
| M1: `last_insert_rowid()` race | MEDIUM | Same sqlite3 session as INSERT | `aea0f5e` |
| M2: `echo` strips trailing newlines | MEDIUM | `printf '%s'` in `_iscp_escape_param` | `aea0f5e` |
| M3: Bare address fallback | MEDIUM | Fail hard, require fully qualified | `aea0f5e` |
| M4: AGENCY_PRINCIPAL leak | MEDIUM | Deprecated env var, always resolve from agency.yaml | `5fdfa84` |
| L1: iscp-migrate hardcoded to jordan | LOW | Scans all principals dynamically | `c0f4e7e` |
| L2: skipped counter never incremented | LOW | SELECT changes() tracks duplicates | `c0f4e7e` |
| L3: Cache file permissions | LOW | umask 077 subshell | `c0f4e7e` |
| L4: Missing bare dispatch permission | LOW | Added to settings.json | `c0f4e7e` |
| L5: Printf JSON fallback fragile | LOW | Removed fallback, require jq | `c0f4e7e` |

## What Captain Needs to Do

1. **Re-merge `iscp` branch to main** — picks up all review fixes + AGENCY_PRINCIPAL deprecation
2. **Run `iscp-migrate`** on main (flags + dispatches)
3. **Sync worktrees** — distributes new tools, settings, hookify rules
4. **Apply 12 CLAUDE-THEAGENCY.md revisions** (per separate dispatch)
5. **Verify** `~/.zshrc` no longer contains `export AGENCY_PRINCIPAL="testuser"` (Jordan confirmed removal)

## Test Results

142/142 BATS tests green. No regressions.
