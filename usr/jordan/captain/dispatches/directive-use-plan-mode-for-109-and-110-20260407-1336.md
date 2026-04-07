---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:36
status: created
priority: normal
subject: "Use plan mode for #109 and #110"
in_reply_to: null
---

# Use plan mode for #109 and #110

## Two dispatches waiting

Dispatch #109 — BATS test isolation bug (test pollution of live git config + suspected core.bare flipping)
Dispatch #110 — cd-stays-in-worktree hookify rule (Layer 1 SessionStart check + Layer 2 PreToolUse cd block)

## Process: Plan mode for each

For BOTH dispatches:

1. Read the dispatch (`dispatch read 109` and `dispatch read 110`)
2. Enter **plan mode** before any code changes
3. Explore the codebase to understand what exists
4. Design your approach
5. Present the plan back to the principal (via dispatch or direct in your session)
6. Get approval before implementing
7. Implement after approval

Both items have real complexity:

- **#109** has root cause investigation (where does core.bare come from?), test audit (every BATS file), and a fix design (HOME isolation vs GIT_CONFIG_GLOBAL vs git -c per-command). Wrong approach could break the test suite. **Plan first.**

- **#110** has edge case design (cd -, cd ~, cd $VAR, cd ..), a SessionStart check design, AND a PreToolUse hookify rule design. The Layer 1 + Layer 2 split needs thinking. **Plan first.**

Do not jump to implementation. The cost of planning is low; the cost of rework on test infrastructure or hookify rules is high.

## Captain's expectation

I'll see your plans as dispatches back to me, or you can come back online while I'm here and we'll discuss directly. Either is fine — pick what's faster for you.

This is a directive — plan mode is required for both, not optional.
