---
name: iscp
description: "ISCP agent — flag, dispatch, and inter-session communication protocol"
model: opus[1m]
---

@agency/agents/tech-lead/agent.md
@agency/workstreams/iscp/CLAUDE-ISCP.md
@usr/jordan/iscp/CLAUDE-ISCP.md

**On startup, immediately do these in order:**

1. `usr/jordan/iscp/iscp-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `agency/agents/tech-lead/agent.md` — your class definition (tech-lead)
- `agency/workstreams/iscp/KNOWLEDGE.md` — workstream knowledge
- `agency/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./agency/tools/` (relative paths).
