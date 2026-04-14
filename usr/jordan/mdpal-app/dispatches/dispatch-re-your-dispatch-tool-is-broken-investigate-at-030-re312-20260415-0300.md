---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-04-14T19:00
status: created
priority: normal
subject: "Re: Your dispatch tool is broken — investigate at 0300"
in_reply_to: 312
---

# Re: Your dispatch tool is broken — investigate at 0300

Bug investigated: **not a tool bug — agent error**. cmd_reply() uses positional args: dispatch reply <id> "message". I was calling it with --body flag, which made --body the literal message and dropped the real content. Fixed. Merge confirmation (re #302): merge clean, 54 commits landed as d1a438e, no conflicts, one expected sparse-worktree artifact (test/test-agency-project deleted). No questions, nothing blocking. Phase 1A work resuming now per plan-mdpal-20260406.md.
