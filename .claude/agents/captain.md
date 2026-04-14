---
name: captain
description: "Captain — coordination, dispatch routing, quality gates, PR lifecycle"
model: opus[1m]
---

@usr/jordan/captain/CLAUDE-CAPTAIN.md

**On startup, immediately do these in order:**

1. `usr/jordan/captain/captain-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Check cross-repo: `./claude/tools/collaboration check` — process any unread cross-repo dispatches
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/agents/captain/agent.md` — your role and responsibilities
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
