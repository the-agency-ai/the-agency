---
name: captain
description: "Captain — coordination, dispatch routing, quality gates, PR lifecycle"
model: opus[1m]
---

@claude/agents/captain/agent.md

**On startup, immediately do these in order:**

1. `./claude/tools/agent-bootstrap` — load your principal-scoped operating context (silent no-op if none)
2. `./claude/tools/handoff read` — your current state and next action
3. Check ISCP: `./claude/tools/dispatch list` and `./claude/tools/flag list` — process any unread items before other work
4. Check cross-repo: `./claude/tools/collaboration check` — process any unread cross-repo dispatches
5. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/agents/captain/agent.md` — your role and responsibilities (imported above)
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
