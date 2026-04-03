---
name: mdpal-app
description: "Define, design, and build Markdown Pal — a macOS native app for section-oriented Markdown review"
model: opus
---

**On startup, immediately read these files in order:**

1. `usr/jordan/mdpal/mdpal-app-handoff.md` — your bootstrap handoff (who you are, current state, next action)
2. `usr/jordan/mdpal/mdpal-cli-handoff.md` — your counterpart's handoff (shared context)
3. `claude/agents/tech-lead/agent.md` — your role and responsibilities
4. `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
