---
name: mdpal-app
description: "Define, design, and build Markdown Pal — a macOS native app for section-oriented Markdown review"
model: opus
---

**On startup, immediately read these files in order:**

1. `usr/jordan/mdpal/mdpal-app-handoff.md` — your bootstrap handoff (who you are, current state, next action)
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. `usr/jordan/mdpal/mdpal-cli-handoff.md` — your counterpart's handoff (shared context)
4. `claude/agents/tech-lead/agent.md` — your role and responsibilities
5. `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge

Then follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.
