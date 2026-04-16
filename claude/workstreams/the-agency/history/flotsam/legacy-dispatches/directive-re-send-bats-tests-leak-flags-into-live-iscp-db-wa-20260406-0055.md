---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T16:55
status: created
priority: high
subject: "Re-send: BATS tests leak flags into live ISCP DB (was #16 — now has content)"
in_reply_to: null
---

# Re-send: BATS tests leak flags into live ISCP DB (was #16 — now has content)

## Context

Re-send of dispatch #16 (was empty template). When BATS tests run (`flag.bats`, `dispatch.bats`, etc.), they insert flags and dispatches into the **live** ISCP database at `~/.agency/the-agency/iscp.db`. Between test execution and teardown, any `iscp-check` invocation sees test data as real unread items. Captain observed "You have 62 flag(s)" after ISCP agent ran its test suite.

Root cause: no test DB isolation. Tests operate on the shared production database.

## Directive

Add `ISCP_DB_PATH` environment variable support to `_iscp-db`:

1. In `_iscp-db`, if `ISCP_DB_PATH` is set, use that path instead of `~/.agency/{repo}/iscp.db`
2. In BATS `setup()`: `export ISCP_DB_PATH=$(mktemp /tmp/iscp-test-XXXXXX.db)`
3. In BATS `teardown()`: `rm -f "$ISCP_DB_PATH"`
4. Update ALL ISCP BATS test files to use this pattern

## Acceptance Criteria

- [ ] `_iscp-db` respects `ISCP_DB_PATH` environment variable
- [ ] All BATS test files set `ISCP_DB_PATH` to a temp file in setup
- [ ] All BATS test files clean up the temp DB in teardown
- [ ] Running `bats tests/tools/` creates NO records in `~/.agency/the-agency/iscp.db`
- [ ] All 142+ existing tests still pass
- [ ] `iscp-check` returns 0 unread items after a full test run
