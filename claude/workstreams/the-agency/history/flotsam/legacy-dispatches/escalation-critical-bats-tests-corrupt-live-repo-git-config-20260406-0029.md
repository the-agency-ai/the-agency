---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T16:29
status: created
priority: normal
subject: "CRITICAL: BATS tests corrupt live repo .git/config"
in_reply_to: null
---

# CRITICAL: BATS tests corrupt live repo .git/config

## Context

BATS tests in `tests/tools/agent-identity.bats` (and possibly others) modify the **live** `.git/config` during test runs. Specifically:

1. **`bare = true`** — tests set `core.bare = true` in `.git/config`, which breaks ALL git operations in the main checkout. `git status`, `git add`, `git commit` all fail with "fatal: this operation must be run in a work tree."

2. **User identity override** — tests set `user.email = test@example.com` and `user.name = Test User` in `.git/config`. Any commits made while this is in effect are attributed to the wrong author. This was discovered when captain's commits showed "Test User" as the author.

Both corruptions survived test teardown — meaning teardown either doesn't restore `.git/config` or the restore is incomplete/conditional.

This is a **CRITICAL** issue. It silently corrupts the working environment for ALL agents and the principal. It was only discovered by manual inspection of `.git/config` after noticing git commands failing.

## Directive

### 1. Diagnose the leak

Read `tests/tools/agent-identity.bats` and every other BATS file that touches `.git/config`. Find:
- Where `git config` is called with `--global` or without `--file`
- Where `core.bare` is set
- Where `user.email` / `user.name` is set
- Whether teardown restores original values

### 2. Fix: Complete git config isolation

BATS tests must NEVER modify the live `.git/config`. Options:

**Option A (preferred): Use `GIT_CONFIG_GLOBAL` and test-local config**
- Set `GIT_CONFIG_GLOBAL=/dev/null` in setup to prevent global config reads
- Use `git -C $TEST_REPO config ...` to only modify the test fixture's config
- Never run bare `git config` without `-C` or `--file`

**Option B: Snapshot and restore**
- In `setup()`: `cp .git/config .git/config.bak`
- In `teardown()`: `cp .git/config.bak .git/config && rm .git/config.bak`
- This is a safety net, not a fix — the tests should still not touch live config

**Do both** — Option A prevents the problem, Option B catches any regression.

### 3. Add a guard

Add a BATS helper that runs in `teardown()` of every test file:
```bash
# Verify live .git/config wasn't modified
assert_git_config_unchanged() {
    local current_bare=$(git config --get core.bare 2>/dev/null || echo "false")
    [[ "$current_bare" != "true" ]] || fail "CRITICAL: tests set core.bare=true in live .git/config"
}
```

## Acceptance Criteria

- [ ] No BATS test modifies the live `.git/config` (the one in the project root)
- [ ] `GIT_CONFIG_GLOBAL=/dev/null` is set in all ISCP test setups
- [ ] Test-specific git config uses `--file` or `-C` to target test fixtures only
- [ ] A guard in teardown detects and fails loudly if live `.git/config` was corrupted
- [ ] All 142+ tests still pass after the fix
- [ ] Running the full test suite leaves `.git/config` byte-identical to its pre-test state
