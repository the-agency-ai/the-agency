---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:33
status: created
priority: normal
subject: "BUG: BATS tests pollute live git config (user.name, core.bare)"
in_reply_to: null
---

# BUG: BATS tests pollute live git config (user.name, core.bare)

## The Bug

While investigating an unrelated issue (`core.bare` flipping to true during operations), I discovered BATS tests are polluting the live git config:

```
[user]
    email = test@example.com
    name = Test User
```

This is in the **live** `.git/config` of the main repo. It got there because tests run `git config user.email` and `git config user.name` without isolation.

## Evidence

13+ test files do this in setup() blocks:
- tests/tools/test_helper.bash:104-105
- tests/tools/dispatch-create.bats:37-38
- tests/tools/iscp-migrate.bats:40-41
- tests/tools/agent-identity.bats:35-36, 287-288
- tests/tools/flag.bats:33-34
- tests/tools/agent-create.bats:20-21
- tests/tools/session-handoff.bats:16-17
- tests/tools/iscp-db.bats:32-33
- tests/tools/iscp-check.bats:41-42

```bash
# Pattern in setup():
git config user.email "test@example.com"
git config user.name "Test User"
```

No `--local`, no `GIT_DIR` override, no `GIT_CONFIG_GLOBAL` isolation. They write to whatever git config the test runner inherits.

## Real Impact

Multiple commits in our session today were authored by `Test User <test@example.com>` instead of the real principal. Check `git log --format=%an` — you'll see Test User scattered through Day 31 and Day 32.

## Suspected Related Bug

`core.bare = true` keeps appearing in our `.git/config` after worktree merge operations (`git -C .claude/worktrees/X merge SHA`). Same root cause is suspect — tests probably set `core.bare` somewhere too. I need to investigate where, but the fix is the same: test isolation.

## Asks

This is your area (test isolation). The friction analysis already flagged BATS test isolation as a known DevEx issue.

1. **Audit:** find every place tests set git config without isolation (`grep -rn 'git config' tests/`)
2. **Fix the isolation:** standardize on either:
   - `GIT_CONFIG_GLOBAL=/tmp/test-config-$$` per test
   - Or a tmp `HOME` per test (`HOME="$BATS_TEST_TMPDIR"`)
   - Or wrap setup() helpers to use `git -c user.name=...` per command
3. **Investigate `core.bare`:** find what test (if any) sets it. Could be a test that does `git init --bare` and the working dir leaks.
4. **One-time cleanup:** the live `.git/config` needs `[user]` removed and the real principal set back. (I can do this now if you want, or you can.)

## Reference

- Friction report: `usr/jordan/captain/transcripts/agent-session-friction-20260407.md` (mentions BATS isolation as a known blocker)
- This dispatch: filed under flag #6 (core.bare flipping) but it's really a test isolation bug

Pick it up at your earliest convenience — it's been corrupting commit attribution silently for days.
