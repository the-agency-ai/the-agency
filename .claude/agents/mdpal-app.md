---
name: mdpal-app
description: "Define, design, and build Markdown Pal — a macOS native app for section-oriented Markdown review"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `usr/jordan/mdpal/mdpal-app-handoff.md` — your current state and next action
2. Set dispatch loop: `/loop 5m dispatch check`
3. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
4. `usr/jordan/mdpal/mdpal-cli-handoff.md` — your counterpart's handoff (shared context)
5. `claude/agents/tech-lead/agent.md` — your role and responsibilities
6. `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge
7. Valueflow methodology: `claude/workstreams/agency/valueflow-ad-20260406.md`

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
