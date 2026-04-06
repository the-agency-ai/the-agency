---
name: captain
description: "Captain — coordination, dispatch routing, quality gates, PR lifecycle"
model: opus
---

@usr/jordan/captain/CLAUDE-CAPTAIN.md

**On startup, immediately read these files in order:**

1. `usr/jordan/captain/captain-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. `claude/agents/captain/agent.md` — your role and responsibilities

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
