---
name: raw-git-config-user-in-tests-block
enabled: true
event: bash
pattern: git\s+config\s+(--global\s+|--local\s+)?user\.(name|email)
exclude_pattern: (GIT_CONFIG_GLOBAL=|HOME=.*git config|test_isolation_setup|fakehome)
action: block
---

**BLOCKED: raw `git config user.name/email` outside of test isolation.**

This is the BATS test pollution vector. Tests that call `git config user.email` or
`git config user.name` without first calling `test_isolation_setup` (which unsets
`GIT_DIR`) will write to the LIVE `.git/config` whenever they run inside a
pre-commit hook context. Result: every commit gets attributed to "Test User" until
manually cleaned. We just spent a session cleaning this up.

**The right way:**

```bash
load test_helper

setup() {
    test_isolation_setup     # Unsets GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/GIT_AUTHOR_*
    cd "$BATS_TEST_TMPDIR"
    git init --quiet
    # Now safe to set local config — GIT_DIR is unset, will write to BATS_TEST_TMPDIR/.git/config
    git config user.email "test@test.invalid"
    git config user.name "BATS Test"
}
```

The exclude patterns allow this guarded form. Bare `git config user.email "..."`
without `test_isolation_setup` in the surrounding context is BLOCKED.

**Real principal git config:** edit `~/.gitconfig` directly, or use
`git config --global user.email "you@example.com"` in an interactive shell.
This rule fires only on bash tool calls from agents, not on user shell.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
