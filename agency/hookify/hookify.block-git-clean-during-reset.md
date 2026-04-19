---
id: hookify.block-git-clean-during-reset
type: hookify-rule
decision: block
severity: block
applies_to: [Bash]
written: 2026-04-19
version: 0.1.0
reset: v46.0
---

# Block `git clean -fd` During v46.0 Reset Execution

## What Problem

During the v46.0 structural reset, captain maintains an UNTRACKED, session-scoped
alias-shim at `usr/jordan/captain/reset-baseline-20260419/reset-shim.sh`
(Principle 12). A `git clean -fd` invocation without explicit `-e` exclusions
will destroy the shim, invalidating the captain's ability to invoke Phase-4.5
atomic-commit retries. The shim is NEVER committed (captain-private), so
`git clean -fd` treats it as deletable.

This rule is a **mechanical backstop** for Principle 12: defense in depth
(Principle + `reset-rollback.sh` wrapper + this hookify rule).

## How & Why

Detects the presence of `.git/RESET_IN_FLIGHT` sentinel file (created by
`reset-rollback.sh` at Phase 0 entry, removed at Gate 7 exit) combined with a
`git clean -fd` invocation that lacks the required `-e` exclusion coverage.

When the sentinel is present, ALL `git clean -fd` invocations are blocked
unless they include BOTH:
  - `-e usr/jordan/captain/reset-baseline-20260419`
  - `-e <shim-path>` (or the same baseline dir path when the shim lives under it)

Exit 2 (BLOCK) + points the user to `reset-rollback.sh` for safe cleanup
operations during the reset.

## Pattern

```regex
^git\s+clean\s+-[a-z]*[fd][a-z]*[fd]
```

The pattern matches `git clean` with any flag-group containing BOTH `f` and `d`
(in any order: `-fd`, `-df`, `-xfd`, `-dfx`, etc.). The hook handler runs a
second check for the required `-e usr/jordan/captain/reset-baseline-20260419`
exclusion before dispatching the block — if present, the hook permits the
invocation; otherwise, it blocks.

(Regex-engine note: the exclusion check is implemented in the hook handler,
not the pattern, because grep -E used by the canary harness does not support
PCRE negative-lookahead.)

## Behavior When Triggered

- Decision: `block`
- Exit code: 2
- Message: "🚫 BLOCKED: `git clean -fd` during v46.0 reset would destroy the
  Phase-1 alias-shim. Use `./agency/tools/reset-rollback` for safe rollback
  during reset. If you truly need `git clean -fd` pass
  `-e usr/jordan/captain/reset-baseline-20260419` to exclude the shim + baseline."

## Precondition

Only fires when `.git/RESET_IN_FLIGHT` exists. Outside of reset execution, the
rule is a no-op (returns exit 0).

## Related

- `agency/tools/reset-rollback` — safe rollback wrapper (ALWAYS use this during reset)
- Plan v4 Principle 12 — shim resilience
- Plan v4 §3 Phase 0b — this rule added
- Plan v4 v3 R-3 HIGH — shim-destruction via cleanup is the underlying risk
- Plan v4 v4 R-1 — mechanical backstop for Principle 12 defense-in-depth

## Canary

See `hookify.block-git-clean-during-reset.canary` for a synthetic payload
that exercises the block behavior.
