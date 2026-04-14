---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-09T06:52
status: created
priority: normal
subject: "Fleet health learning note: 8 Test User commits on your branch + testing discipline reminder"
in_reply_to: null
---

# Fleet health learning note: 8 Test User commits on your branch + testing discipline reminder

## Fleet Health Finding — Test User Attribution

Captain ran `agency-health` on 2026-04-09 and detected **8 commits in your last 20 attributed to `Test User <test@example.com>`** on your branch.

### What happened

BATS tests running inside a pre-commit hook context inherited `GIT_DIR`/`GIT_INDEX_FILE`/`GIT_WORK_TREE` from the parent commit operation. Calls to `git config user.email/name` inside the test then wrote to the OUTER repo's `.git/config`, polluting it with a `[user]` section. Every subsequent commit in that session was attributed to Test User instead of the principal.

### What was fixed

Two fixes shipped in Day 34.2 (PR #63):

1. **Gate 0 in `commit-precheck`** (commit `2a62f8d`) — hard-blocks any commit with Test User attribution. Prints cleanup instructions on failure. Belt + suspenders alongside the test_helper fix.
2. **`test_helper.bash` env-var isolation** (already on your branch from dispatch #109) — unsets `GIT_DIR`/`GIT_INDEX_FILE`/`GIT_WORK_TREE`/`GIT_AUTHOR_*`/`GIT_COMMITTER_*` in `test_isolation_setup()`.

### What is NOT being done

The 8 Test User commits on your branch are **not being rewritten**. No filter-branch, no force-push, no history rewrite. They are permanent evidence of the bug we fixed. When your branch lands via a future PR, the commits travel as-is.

### How to avoid this going forward

1. **Always use `test_isolation_setup()`** in your BATS test `setup()` function. If you have a custom setup, call it explicitly.
2. **Never run BATS tests outside of the isolation harness** — no raw `bats tests/tools/foo.bats` without the test_helper loaded.
3. **After ANY BATS run, check** `git config user.name` — if it says Test User, clean immediately: `git config --local --unset user.email && git config --local --unset user.name`.

### WARNING

**Anyone doing local, non-isolated testing will be fed to the — CUTE — ATTACK KITTENS.** This is not negotiable. The isolation harness exists for a reason. Bypassing it corrupts the audit trail for every commit in the session. Gate 0 will block you at commit time, but by then the damage to `.git/config` is already done and needs manual cleanup.

Use the harness. Always. No exceptions.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

— the-agency/jordan/captain
