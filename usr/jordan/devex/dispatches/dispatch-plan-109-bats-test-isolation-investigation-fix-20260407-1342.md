---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-07T05:42
status: created
priority: normal
subject: "PLAN #109: BATS test isolation — investigation + fix"
in_reply_to: 109
---

# PLAN #109: BATS test isolation — investigation + fix

## Investigation Findings

### Root cause confirmed
Tests call `git config user.email/name` in setup() blocks. When tests run inside a pre-commit hook context (git-safe-commit triggers commit-precheck which can run scoped BATS tests), they inherit `GIT_DIR` from the parent. The `git config` calls then write to the OUTER repo's local config, polluting it with [user] section.

### Evidence
- All commits in this devex session show `Test User <test@example.com>` as author (8c739d0, 047291f, b976409, 435dad1, 3ad7993, c2b6bf2, aa04513, plus older Day 31/32 commits)
- I just made a fresh test commit: it shows Jordan Dea-Mattson correctly
- This means [user] section was in .git/config during those commits, then got removed by some cleanup (likely my `git reset --soft` during Phase 1.4)
- Live .git/config currently has NO [user] section but commits remain frozen with Test User attribution

### Universal isolation gap (Phase 1.1)
`test_helper.bash` sets `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_SYSTEM=/dev/null` but does NOT unset `GIT_DIR`, `GIT_INDEX_FILE`, or `GIT_WORK_TREE`. Inside a hook context, those vars point to the outer repo. `git config` then writes to the outer repo despite the "isolation".

### core.bare investigation
- Live config currently shows `core.bare=false`. Not currently broken.
- No `init --bare` calls in tests/. No `core.bare=true` writes anywhere I could grep.
- Hypothesis: `git -C .claude/worktrees/X merge SHA` from main checkout might be the culprit (worktree merge mechanics), NOT test code. Different bug.
- Recommendation: defer core.bare investigation until we observe it again. The test isolation fix won't address it.

## Proposed Fix

### Step 1: Extend test_isolation_setup to clean git env vars
Add to `test_helper.bash` at the start of `test_isolation_setup`:
```bash
# Clean leaked git env vars (critical when running inside a pre-commit hook)
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE
unset GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE
```

### Step 2: Add a teardown guard for [user] section
Extend `test_isolation_teardown` to specifically check that no [user] section was added to the live .git/config (the existing md5 hash check catches it but the error is generic).

### Step 3: Audit and fix tests that bypass isolation
Found 11 test files that call `git config user.`:
- tests/tools/commit-precheck.bats (mine — newly added)
- tests/tools/session-handoff.bats
- tests/tools/agent-create.bats
- tests/tools/iscp-check.bats
- tests/tools/flag.bats
- tests/tools/dispatch-create.bats
- tests/tools/dispatch.bats
- tests/tools/agent-identity.bats
- tests/tools/iscp-migrate.bats
- tests/tools/iscp-db.bats
- tests/tools/test_helper.bash itself

For each: verify they call `test_isolation_setup` first (most should, after Phase 1.1). The Step 1 fix protects the config calls regardless of where they write to.

### Step 4: One-time cleanup
Live .git/config currently clean. No cleanup needed there. But the COMMITS in git history remain attributed to Test User. Options:
- (a) Leave the historical commits as-is (cheapest)
- (b) Rebase + amend each polluted commit to fix author (history rewrite — needs principal approval, only safe before push)
- (c) Add a script to rewrite author for un-pushed commits only

I recommend (a) for already-merged commits and (b) for commits on devex branch that haven't been merged to main. **Need your decision before doing (b).**

### Step 5: Verify
- Run all 36 BATS files with the fix applied
- Make a real commit on devex and verify author is Jordan
- Add a test to test_helper.bats (or create one) that explicitly verifies GIT_DIR is unset after test_isolation_setup

## Estimated work
- Step 1: 5 min (3-line edit to test_helper.bash)
- Step 2: 10 min
- Step 3: 30 min audit + verification
- Step 4: depends on your decision
- Step 5: 15 min
- **Total: ~1 hour, plus history rewrite if approved**

## Open questions for you
1. **History rewrite for devex branch?** It's not pushed to origin yet. Safe to rebase and fix author attribution. Want me to do it?
2. **Should I add a hookify rule** that blocks raw `git config user.*` calls in test files? (Would prevent regression.)
3. **Defer core.bare?** Or do you want me to dig into worktree merge mechanics now?

Awaiting approval to implement.
