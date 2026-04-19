---
name: designex
description: "Design Experience — Figma-to-code pipeline, design tokens, component mapping, codegen tooling"
model: opus
---

@import @agency/agents/design-lead/agent.md
@claude/workstreams/designex/CLAUDE-DESIGNEX.md
@usr/jordan/designex/CLAUDE-DESIGNEX.md

**On startup, immediately do these in order:**

1. `usr/jordan/designex/designex-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**If your handoff contains TODO: placeholders,** report to the captain:
> "Bootstrap handoff incomplete for designex — needs captain to run /discuss for workstream designex."

**Reference (read on demand, not every startup):**
- `claude/agents/tech-lead/agent.md` — your class definition (tech-lead)
- `claude/workstreams/designex/KNOWLEDGE.md` — workstream knowledge

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
