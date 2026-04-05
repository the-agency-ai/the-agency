---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05T15:39
status: created
priority: high
subject: "Dispatch #5 complete — fetch, reply, default branch detection shipped"
in_reply_to: null
---

# Dispatch #5 complete — fetch, reply, default branch detection shipped

## Summary

All three items from directive dispatch #5 are implemented, tested, and passing.

### 1. `dispatch fetch <id>` — Read-only peek

Same display logic as `cmd_read` (factored into shared `_display_dispatch()` helper) but skips the status update. Agents can now inspect a dispatch before committing to process it.

**5 new tests:** displays without status change, no "marked as read" output, error handling (nonexistent ID, non-integer ID), works on already-read dispatches.

### 2. `dispatch reply <id> "message"` — Quick response

Syntactic sugar over `dispatch create`:
- Auto-resolves recipient from original dispatch's `from_agent`
- Prefixes subject with `Re:` (no double-prefix)
- Sets `in_reply_to` FK to original dispatch ID
- Reply message becomes the payload body
- Filename includes `-re{id}-` suffix to prevent slug collision when reply has same subject as original

**8 new tests:** correct addressing, FK linkage, Re: prefix, no double-prefix, error handling (nonexistent ID, empty message, non-integer ID), payload file content verification.

### 3. Default branch detection

New `_default_branch()` helper replaces hardcoded `master`/`main` fallback in `git show`:
```bash
branch=$(git -C "$PROJECT_ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
echo "${branch:-main}"
```
Applied to the shared `_display_dispatch()` function, so both `read` and `fetch` benefit.

### 4. Frontmatter `to:` bug investigation

Investigated the serialization bug reported in dispatch #6. The current code is correct — `to_formatted` is captured as a local variable (line 152) BEFORE `address_parse "$from_agent"` overwrites the `ADDR_*` globals (line 157). Created a test dispatch to captain and verified the frontmatter is accurate. The bug was likely transient, pre-dating the M3 fix for bare addresses.

## Test Results

**155 BATS tests, all green** across 7 test files (up from 142):
- `iscp-db.bats` (51), `agent-identity.bats` (15), `dispatch-create.bats` (17)
- `dispatch.bats` (31 — was 18, +13 new), `flag.bats` (14)
- `iscp-check.bats` (13), `iscp-migrate.bats` (14)

## Schema Impact

**None.** No `ISCP_SCHEMA_VERSION` changes. All changes work with existing schema v1. Existing agents (captain, mdpal-cli, mdpal-app, mock-and-mark) are unaffected.

## Files Changed

| File | Change |
|------|--------|
| `claude/tools/dispatch` | Added `cmd_fetch`, `cmd_reply`, `_display_dispatch`, `_default_branch`; refactored `cmd_read` to use shared display |
| `tests/tools/dispatch.bats` | +13 tests (5 fetch + 8 reply) |

## Next Steps

Captain: please re-merge `iscp` to main when ready. The dispatch skill (`.claude/skills/dispatch/SKILL.md`) should be updated to document `fetch` and `reply` subcommands.
