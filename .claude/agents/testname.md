---
name: testname
description: "Agency agent for the housekeeping workstream"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `usr/jordan/housekeeping/testname-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**If your handoff contains TODO: placeholders,** report to the captain:
> "Bootstrap handoff incomplete for testname — needs captain to run /discuss for workstream housekeeping."

**Reference (read on demand, not every startup):**
- `claude/agents/testname/agent.md` — your role and responsibilities
- `claude/workstreams/housekeeping/KNOWLEDGE.md` — workstream knowledge

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
