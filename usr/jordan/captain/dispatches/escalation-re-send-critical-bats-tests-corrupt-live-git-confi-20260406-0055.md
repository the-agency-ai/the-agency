---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T16:55
status: created
priority: high
subject: "Re-send: CRITICAL — BATS tests corrupt live .git/config (was #17 — now has content)"
in_reply_to: null
---

# Re-send: CRITICAL — BATS tests corrupt live .git/config (was #17 — now has content)

## Context

Re-send of dispatch #17 (was empty template). BATS tests in `tests/tools/agent-identity.bats` modify the **live** `.git/config`:

1. **`bare = true`** — sets `core.bare = true`, breaking ALL git operations (`git status`, `git add`, `git commit` all fail)
2. **User identity override** — sets `user.email = test@example.com` and `user.name = Test User`, attributing commits to wrong author

Both corruptions survive teardown. This silently broke the entire working environment — discovered only by manual `.git/config` inspection.

## Directive

### 1. Diagnose
Read all BATS files that touch `.git/config`. Find where `git config` runs without `--file` or `-C`, where `core.bare` is set, where `user.email`/`user.name` is set.

### 2. Fix: Complete git config isolation
- Set `GIT_CONFIG_GLOBAL=/dev/null` in setup (prevent global config reads)
- Use `git -C $TEST_REPO config ...` to only modify test fixtures
- Never run bare `git config` without `-C` or `--file`
- Snapshot/restore as safety net: `cp .git/config .git/config.bak` in setup, restore in teardown

### 3. Add guard
BATS helper in teardown that fails loudly if `core.bare=true` or user identity changed in live `.git/config`.

## Acceptance Criteria

- [ ] No BATS test modifies the live `.git/config`
- [ ] `GIT_CONFIG_GLOBAL=/dev/null` set in all ISCP test setups
- [ ] Test git config uses `--file` or `-C` for test fixtures only
- [ ] Guard in teardown detects live `.git/config` corruption
- [ ] All 142+ tests still pass
- [ ] Full test suite leaves `.git/config` byte-identical to pre-test state
