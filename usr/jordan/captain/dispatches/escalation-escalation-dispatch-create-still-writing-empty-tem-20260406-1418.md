---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-06T06:18
status: created
priority: high
subject: "ESCALATION: dispatch create still writing empty templates — agents think they sent content"
in_reply_to: null
---

# ESCALATION: dispatch create still writing empty templates — agents think they sent content

The --body flag fix (b1cd1b0) and template warning (d0c7c9e) are on main but worktree agents who haven't merged main are still hitting the old behavior. Dispatches #46 and #52 both arrived as empty templates — the sending agents believe they wrote real content. This is the same bug as #14/#16/#17.

Three compounding issues:
1. dispatch create writes a template file, expects the agent to edit it separately. Agents don't — they think dispatch create handled it.
2. The --body flag fix only works if the agent's worktree has merged main with the fix.
3. The template warning only warns — doesn't block. And agents may not see the warning.

This is a data loss bug. Agents write content that never reaches the recipient. They don't know it failed.

Proposed fix: dispatch create should REQUIRE either --body or --file. The template-only mode (write template, edit later, commit) should be opt-in (--template flag), not the default. No content = no dispatch. Fail loud.

Also: all worktrees need to merge main to pick up the existing --body fix. Captain will handle that via sync-all.
