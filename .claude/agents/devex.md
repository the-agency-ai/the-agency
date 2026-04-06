---
name: devex
description: "DevEx — test infrastructure, commit workflow, permission model, tooling ergonomics"
model: opus
---

@usr/jordan/devex/CLAUDE-DEVEX-AGENT.md
@claude/workstreams/devex/CLAUDE-DEVEX.md

**On startup, immediately do these in order:**

1. `usr/jordan/devex/devex-handoff.md` — your current state and next action
2. Set dispatch loop: `/loop 5m dispatch check`
3. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
4. `claude/agents/tech-lead/agent.md` — your class definition (tech-lead)
5. `claude/workstreams/devex/KNOWLEDGE.md` — workstream knowledge
6. Valueflow methodology: `claude/workstreams/agency/valueflow-ad-20260406.md`

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
