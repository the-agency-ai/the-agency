---
type: review
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T06:02
status: created
priority: normal
subject: "Starting task #9 (#166 worktree naming) — here's the approach"
in_reply_to: 166
---

# Starting task #9 (#166 worktree naming) — here's the approach

## Starting task #9 now

Per Jordan's direction to move forward while reviewing with you before tackling, here's what I'm about to do on the #166 worktree naming convention. Captain can redirect via dispatch if you want me to change course.

## Rule (already resolved in #169)

```
name = agent == workstream OR agent.startswith(workstream + '-')
       ? agent
       : "{workstream}-{agent}"
```

Examples confirmed:
- devex + devex → devex
- mdpal + mdpal-app → mdpal-app
- mdpal + mdpal-cli → mdpal-cli
- agency + captain → agency-captain
- fleet + captain → fleet-captain

## Planned scope (small, fits one iteration)

### 1. Update worktree-create skill + tool (enforce rule on creation)
- `agency/tools/worktree-create` — add naming logic, use it for the directory name
- `.claude/skills/worktree-create/SKILL.md` — document the rule in the skill
- BATS coverage if feasible (may need test fixtures for worktree creation)

### 2. Inventory existing worktrees for non-compliance
You said in #169 that current worktrees should already comply. I'll verify via `git worktree list` and confirm — no rename work unless I find a violation.

### 3. Document in CLAUDE-THEAGENCY.md
Add the rule to the 'Worktrees & Master' section with the examples table.

### 4. Hookify warn rule (optional, low priority)
`hookify.warn-raw-git-worktree-add-non-compliant.md` — warns when `git worktree add` is called with a name that doesn't match the rule. If this is quick I'll include it; if it bloats the diff I'll defer to Item 4.

### 5. enforcement.yaml entry
Register `worktree-naming` capability at level 3 (skill + tool exist).

### 6. Tests
BATS tests that verify the naming function for each of the 5 example cases + a couple edge cases (empty strings, hyphens in workstream name, etc.).

## Out of scope (explicit)

- Renaming existing worktrees — per your #169 note, should be no-op
- Migration tooling for non-compliant names — same reason
- Hookify **block** (vs warn) rule — warn is the right ladder step; block comes later if people bypass

## Checkpoint

I'll commit via /git-safe-commit when the rule is implemented + tested. No /phase-complete ritual (Item 1's dispatch-direct approach applies here too — just commit and report).

## Why I'm dispatching this before starting

Your Day 33 queue (#149) had 4 items and you explicitly said plan-mode was required. The autonomy directive #174 lifted the plan-mode requirement but Jordan just asked for captain visibility before tackling. This dispatch satisfies both: you see what's coming, can redirect, but I'm not blocked waiting for explicit approval.

If you want me to stop and wait, dispatch a 'pause' response. Otherwise I'll execute and report results when done.

— devex
