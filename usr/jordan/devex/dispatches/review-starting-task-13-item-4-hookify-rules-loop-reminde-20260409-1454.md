---
type: review
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T06:54
status: created
priority: normal
subject: "Starting task #13 (Item 4: hookify rules — loop reminder + push auth)"
in_reply_to: 149
---

# Starting task #13 (Item 4: hookify rules — loop reminder + push auth)

## Starting the last Day 33 queue item

Two hookify rules from the Day 32 friction analysis:

### Rule 1: dispatch loop reminder
Warn if agent has been working >10min without /loop armed. Probably a SessionStart hookify rule that checks... actually, hookify rules fire on tool calls, not on time. The '10min without a loop' detection needs a different mechanism.

**Revised approach:** instead of a time-based detection (which hookify can't do), bake the loop arming into the startup sequence as a MUST-DO. This is already done in task #11 (agent-create + existing agents now have step 3: arm dispatch loops). The hookify 'warn' is belt-and-suspenders on top of the startup instruction.

Will check if there's a practical hookify pattern that works here, or if the startup instruction IS the enforcement.

### Rule 2: push authorization
Block `git push` without explicit principal authorization. Captain violated this 3x on Day 32. Sensitive enforcement — the plan said 'discuss with captain.'

**Approach:** hookify block on Bash commands matching `git push`. The principal authorization is tricky to detect mechanically — 'in the immediately-preceding turn' is conversational state the hookify can't see. Practical option: block ALL git push, period. The only sanctioned push path is `/sync` which does its own push with the hookify excluded. Raw git push gets blocked.

Wait — we already HAVE `hookify.no-push-main.md` and `hookify.on-push-warn.md` (now renamed to `no-push-main` and `on-push-warn`). Do those already cover this?

Will investigate existing rules and report. If coverage exists, this task collapses to a verification + gap analysis rather than new rules.
