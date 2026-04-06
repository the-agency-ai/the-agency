---
name: testname
description: "Agency agent for the housekeeping workstream"
model: opus
---

**On startup, immediately read these files in order:**

1. `usr/jordan/housekeeping/testname-handoff.md` — your bootstrap handoff (who you are, current state, next action)
2. `claude/agents/testname/agent.md` — your role and responsibilities
3. `claude/workstreams/housekeeping/KNOWLEDGE.md` — workstream knowledge

**If your handoff contains TODO: placeholders,** report to the captain:
> "Bootstrap handoff incomplete for testname — needs captain to run /discuss for workstream housekeeping."

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
