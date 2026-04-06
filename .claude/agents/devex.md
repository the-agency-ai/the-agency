---
name: devex
description: "DevEx — test infrastructure, commit workflow, permission model, tooling ergonomics"
model: opus
---

@usr/jordan/devex/CLAUDE-DEVEX-AGENT.md
@claude/workstreams/devex/CLAUDE-DEVEX.md

**On startup, immediately read these files in order:**

1. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
2. `usr/jordan/devex/devex-handoff.md` — your bootstrap handoff (current state, next action)
3. `claude/agents/tech-lead/agent.md` — your class definition (tech-lead)
4. `claude/workstreams/devex/KNOWLEDGE.md` — workstream knowledge

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
