---
description: Run a command in a target directory without touching the parent shell's CWD. Use any time you would write "cd foo && bar" — that pattern is blocked by the block-compound-bash hookify rule.
---

# run-in

Run a command in a target directory via a subshell. The parent shell's CWD
is never touched. Exit code is propagated. Standard Agency telemetry.

## When to use

- You would otherwise write `cd foo && bar && cd -` — don't. Use `run-in`.
- You need to run an Agency tool on another repo (e.g., `agency verify` on
  a downstream installation).
- You need to run a git command on another worktree without leaving your
  shell parked in that worktree.
- You want observability on the directory-scoped execution (log_start /
  log_end are built in).

## Signature

```
run-in <target-dir> -- <command> [args...]
```

The `--` separator is required and distinguishes the target directory from
the command and its argv.

## Examples

```bash
# Run a command on another repo without leaking CWD
./claude/tools/run-in ~/code/presence-detect -- ./claude/tools/agency verify

# Run a git command in a worktree from your captain shell
./claude/tools/run-in .claude/worktrees/devex -- git status

# Run a test suite in a sandbox dir
./claude/tools/run-in "$BATS_TEST_TMPDIR/mock" -- bats mock.bats
```

## What NOT to do

```bash
# ❌ BLOCKED by hookify.block-compound-bash
cd ~/code/presence-detect && agency verify

# ❌ BLOCKED (parent shell CWD leaks)
cd .claude/worktrees/devex && git status && cd -

# ✅ Use run-in instead
./claude/tools/run-in ~/code/presence-detect -- agency verify
./claude/tools/run-in .claude/worktrees/devex -- git status
```

## Why subshell isolation matters

Agent identity resolution uses the current working directory to determine
which agent is running (via `agent-identity`). If a worktree agent `cd`s to
the main checkout and forgets to `cd -`, subsequent commands resolve the
wrong identity, handoffs write to the wrong file, and dispatches go to the
wrong agent. `run-in` runs the command in a subshell — the parent shell's
CWD is untouchable by construction, so identity resolution stays correct.

## Related

- Hookify rule: `claude/hookify/hookify.block-compound-bash.md`
- Tool: `claude/tools/run-in`
- Companion seed: telemetry-mining for compound command patterns (flag #54)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
