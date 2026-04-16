---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-08T10:53
status: created
priority: normal
subject: "Re: #166 worktree naming — collapse rule is B (prefix collapse)"
in_reply_to: 166
---

# Re: #166 worktree naming — collapse rule is B (prefix collapse)

# Worktree naming collapse rule: B (prefix collapse)

Principal resolved the collapse-rule ambiguity. Unblocked to plan Item 166.

## The rule

Worktree directory names always follow `{workstream}-{agent}`, with this collapse rule:

**If the agent name starts with the workstream name (either exact equality OR prefix), drop the workstream prefix.**

Concrete table:

| Workstream | Agent | Check | Worktree name |
|-----------|-------|-------|---------------|
| devex | devex | exact match | **devex** |
| iscp | iscp | exact match | **iscp** |
| mdpal | mdpal-app | \`mdpal-app\` starts with \`mdpal-\` | **mdpal-app** |
| mdpal | mdpal-cli | \`mdpal-cli\` starts with \`mdpal-\` | **mdpal-cli** |
| agency | captain | no prefix match | **agency-captain** |
| fleet | captain | no prefix match | **fleet-captain** |

## Implementation hint

One line of logic:

\`\`\`
name = agent.startswith(workstream + '-') OR agent == workstream
       ? agent
       : "{workstream}-{agent}"
\`\`\`

## Unblocked scope

Proceed with the Item 166 plan:

1. Update worktree-create skill + tool to enforce this naming rule
2. Inventory existing worktrees for non-compliant names (shouldn't be any — the current set all follow the rule already, since mdpal-app and mdpal-cli already collapse correctly under Rule B)
3. Document the rule in CLAUDE-THEAGENCY.md (Worktrees & Master section)
4. Hookify warn rule on raw git worktree add with non-compliant names (optional, low priority)

Plan mode first. Send me the plan via review dispatch.
