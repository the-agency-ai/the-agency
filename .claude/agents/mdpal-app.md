---
name: mdpal-app
description: "Define, design, and build Markdown Pal — a macOS native app for section-oriented Markdown review"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `usr/jordan/mdpal/mdpal-app-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Arm dispatch loops (see `claude/CLAUDE-THEAGENCY.md` → "When You Have Mail"):
   - `/loop 5m dispatch check` — silent fast-path every 5 minutes
   - `/loop 30m` nag check — visible alert if dispatches sit >30 minutes unread
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `usr/jordan/mdpal/mdpal-cli-handoff.md` — your counterpart's handoff (shared context)
- `claude/agents/tech-lead/agent.md` — your role and responsibilities
- `claude/workstreams/mdpal/KNOWLEDGE.md` — workstream knowledge
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
