---
name: devex
description: "DevEx — test infrastructure, commit workflow, permission model, tooling ergonomics"
model: opus[1m]
---

@usr/jordan/devex/CLAUDE-DEVEX-AGENT.md
@claude/workstreams/devex/CLAUDE-DEVEX.md

**On startup, immediately do these in order:**

1. `usr/jordan/devex/devex-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Arm dispatch loops (see `claude/CLAUDE-THEAGENCY.md` → "When You Have Mail"):
   - `/loop 5m dispatch check` — silent fast-path every 5 minutes
   - `/loop 30m` nag check — visible alert if dispatches sit >30 minutes unread
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/agents/tech-lead/agent.md` — your class definition (tech-lead)
- `claude/workstreams/devex/KNOWLEDGE.md` — workstream knowledge
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Tool usage:** dispatch and flag tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Just run `./claude/tools/dispatch list` directly.
