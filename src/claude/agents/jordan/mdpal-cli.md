---
name: mdpal-cli
description: "Define, design, and build Markdown Pal CLI — the section-oriented Markdown engine and CLI tool"
model: opus[1m]
---

@claude/agents/tech-lead/agent.md
@claude/workstreams/mdpal/CLAUDE-MDPAL.md
@usr/jordan/mdpal-cli/CLAUDE-MDPAL-CLI.md

**On startup, immediately do these in order:**

1. `usr/jordan/mdpal-cli/mdpal-cli-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- Counterpart handoff: `usr/jordan/mdpal-app/mdpal-app-handoff.md`
- `claude/agents/tech-lead/agent.md` — your class definition (tech-lead)
- `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
