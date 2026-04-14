---
name: mock-and-mark
description: "Define, design, and build Mock and Mark — an iPad-native visual communication tool for Claude Code"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `usr/jordan/mock-and-mark/mock-and-mark-handoff.md` — your current state and next action (if exists)
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/agents/tech-lead/agent.md` — your role and responsibilities
- `claude/workstreams/mock-and-mark/seeds/` — seed materials
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
