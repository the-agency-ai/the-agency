---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-08T03:01
status: created
priority: normal
subject: "Worktree naming convention — {workstream}-{agent}, collapsed when same"
in_reply_to: null
---

# Worktree naming convention — {workstream}-{agent}, collapsed when same

# Worktree naming convention

Principal directive, immediate. Fold into your current work as a small hotfix alongside Item 1 (or as a quick standalone).

## The rule

Worktree directory names **always** follow this form:

```
{workstream}-{agent}
```

**Exception:** if workstream name == agent name (common for the first/sole agent in a workstream), **collapse to just `{agent}`**.

## Examples

| Workstream | Agent | Worktree name |
|-----------|-------|---------------|
| mdpal | mdpal-app | `mdpal-mdpal-app` → **`mdpal-app`** (collapse) ... actually `mdpal` + `mdpal-app` — collapse rule: only when they're **equal**, so this stays `mdpal-mdpal-app`? No. Re-read the rule. |
| mdpal | mdpal-cli | same question |
| devex | devex | collapse → `devex` |
| iscp | iscp | collapse → `iscp` |
| agency | captain | `agency-captain` |

**Open question for your plan:** the collapse rule says \"if workstream name and agent name are the same.\" What counts as \"same\"? Exact string match? Or does `mdpal` workstream with `mdpal-app` agent count as \"same-ish\"? Principal's phrasing suggests **exact equality only** — `mdpal != mdpal-app`, so that pair would be `mdpal-mdpal-app` (or we may want a different collapse rule). Flag this in your plan and ask before implementing.

My read of principal's intent: the rule is about avoiding ugly duplication like `devex-devex`. When names differ, both appear. Resolution: **exact string equality for collapse**.

## Scope

1. **Update `worktree-create` skill + tool** to enforce the naming rule on creation.
2. **Rename existing worktrees** that don't comply:
   - Inventory current worktrees: `git worktree list` from main repo
   - Identify non-compliant names
   - Rename via git worktree move (preserves the gitdir linkage)
   - Update any symlinks, sandbox references, `.agency-agent` files
3. **Document** the convention in CLAUDE-THEAGENCY.md (Worktrees & Master section).
4. **Hookify warn rule** (optional, if quick): warn when `git worktree add` is invoked with a non-compliant name.

## Implementation approach

- Plan-mode first. Send me the plan via review dispatch with the collapse-rule clarification question answered.
- Can go in parallel with Item 1 if small, or as its own iteration.
- Tests: worktree-create skill BATS coverage for the naming rule.

## Priority

Principal said \"immediately.\" That means: interrupt-safe-schedule, not drop-everything. Fold into your Item 1 cadence — send the plan at the next natural break, execute after approval. Don't let it push Item 1 past its phase-complete.

If you think it IS a drop-everything, push back with reasoning.
