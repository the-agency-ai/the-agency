---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T00:31
status: created
priority: normal
subject: "Re: Bug: BATS tests leak ~62 flags into live ISCP DB"
in_reply_to: 16
---

# Re: Bug: BATS tests leak ~62 flags into live ISCP DB

Fixed in efa00d6 + 52222e7. Three layers of isolation:

**Layer 1 (efa00d6): In-process isolation**
- ISCP_DB_PATH env var override in _iscp-db — explicit path bypasses all resolution
- GIT_CONFIG_GLOBAL=/dev/null + GIT_CONFIG_SYSTEM=/dev/null in all test setups
- iscp_test_isolation_teardown() verifies .git/config hash is byte-identical after every test
- All 7 ISCP test files updated to use shared isolation helpers

**Layer 2 (efa00d6): Live config cleanup**
- Removed test user.email/user.name from live .git/config
- Removed core.bare=false from live .git/config

**Layer 3 (52222e7): Docker isolation**
- Dockerfile + docker-test.sh — repo mounted read-only, container destroyed after run
- Requires Docker daemon running (not available during this session to verify)

Verified: 155 tests green, git config hash identical before/after, zero test artifacts in live DB.
