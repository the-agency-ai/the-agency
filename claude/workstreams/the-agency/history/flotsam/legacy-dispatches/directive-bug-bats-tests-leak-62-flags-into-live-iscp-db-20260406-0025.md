---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T16:25
status: created
priority: normal
subject: "Bug: BATS tests leak ~62 flags into live ISCP DB"
in_reply_to: null
---

# Bug: BATS tests leak ~62 flags into live ISCP DB

## Context

When BATS tests run (`bats tests/tools/flag.bats`, `dispatch.bats`, etc.), they insert flags and dispatches into the **live** ISCP database at `~/.agency/the-agency/iscp.db`. The tests use `setup()` / `teardown()` to create and delete test records, but between test execution and teardown, any `iscp-check` invocation (e.g., from a SessionStart or UserPromptSubmit hook in another agent session) sees the test data as real unread items.

Observed: captain session showed "You have 62 flag(s)" immediately after ISCP agent ran its test suite. The flags were test artifacts that hadn't been cleaned up yet.

Root cause: BATS tests operate on the shared production database. There is no test isolation — no separate test DB, no transaction rollback, no `ISCP_DB_PATH` override.

## Directive

### Fix: Test database isolation

The ISCP tools already respect environment variables for path resolution. Add support for `ISCP_TEST_DB` or `ISCP_DB_PATH` override in `_iscp-db` (the library that opens the database):

1. In `_iscp-db`, check for `ISCP_DB_PATH` env var. If set, use that path instead of `~/.agency/{repo}/iscp.db`.
2. In BATS test `setup()`, create a temp DB: `export ISCP_DB_PATH=$(mktemp /tmp/iscp-test-XXXXXX.db)`
3. In BATS test `teardown()`, remove the temp DB: `rm -f "$ISCP_DB_PATH"`
4. Update all ISCP BATS test files to use this pattern.

This ensures test data never touches the live DB. The temp file is created fresh per test (or per test file — your call on granularity).

### Verify

Run the full ISCP test suite, then immediately run `iscp-check` — should show 0 unread items (assuming no real dispatches are pending).

## Acceptance Criteria

- [ ] `_iscp-db` respects `ISCP_DB_PATH` environment variable
- [ ] All BATS test files set `ISCP_DB_PATH` to a temp file in setup
- [ ] All BATS test files clean up the temp DB in teardown
- [ ] Running `bats tests/tools/` does NOT create any records in `~/.agency/the-agency/iscp.db`
- [ ] All 142+ existing tests still pass
- [ ] `iscp-check` returns 0 unread items after a full test run (no leakage)
