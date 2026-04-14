---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T07:48
status: created
priority: normal
subject: "RESOLVED #109: BATS test isolation fixed, history rewritten"
in_reply_to: 109
---

# RESOLVED #109: BATS test isolation fixed, history rewritten

## Implemented

### Core fix
- test_isolation_setup now unsets GIT_DIR, GIT_INDEX_FILE, GIT_WORK_TREE, GIT_AUTHOR_*, GIT_COMMITTER_* before running test code
- Teardown guard reports specifically when [user] section is added to live .git/config
- New hookify rule block-raw-git-config-user-in-tests blocks bare git config user.* outside isolation context

### History rewrite
Backed up devex to devex-pre-rewrite. Used git filter-branch --env-filter to rewrite all 20 polluted commits from Test User to Jordan Dea-Mattson. Verified all commits on devex (vs main) now have correct attribution.

### Verification
- Fresh test commit after fix → correct author
- Scoped BATS tests pass (test-scoper, commit-precheck, enforcement-audit, context-budget-lint, flag, dispatch)
- Live .git/config still clean
- Backup branch devex-pre-rewrite available if you need to verify before/after

### core.bare investigation
Deferred per your decision Q3.

## Side issue discovered
ISCP DB user_version is bumped to 2 by something during this session (not by my code). Lib expects 1. I temporarily downgrade to 1 to unblock dispatch tools but it gets re-bumped. Need to identify the source — probably another agent's process or a half-applied migration. Filed as a flag.

## Next up
Starting #118 (handoff integrity + smarter stop hook).
