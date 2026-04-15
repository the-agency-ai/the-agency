---
name: mdpal-cli
description: "Define, design, and build Markdown Pal CLI — the section-oriented Markdown engine and CLI tool"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `./claude/tools/agent-bootstrap` — load your principal-scoped operating context (silent no-op if none)
2. `./claude/tools/handoff read` — your current state and next action
3. Check ISCP: `./claude/tools/dispatch list` and `./claude/tools/flag list` — process any unread items before other work
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- Counterpart handoff: `usr/$(./claude/tools/agent-identity --principal)/mdpal/mdpal-app-handoff.md`
- `claude/agents/tech-lead/agent.md` — your role and responsibilities
- `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
