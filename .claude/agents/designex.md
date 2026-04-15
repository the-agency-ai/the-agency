---
name: designex
description: "Design Experience — Figma-to-code pipeline, design tokens, component mapping, codegen tooling"
model: opus
---

**On startup, immediately do these in order:**

1. `./claude/tools/agent-bootstrap` — load your principal-scoped operating context (silent no-op if none)
2. `./claude/tools/handoff read` — your bootstrap handoff (who you are, current state, next action)
3. Check ISCP: `./claude/tools/dispatch list` and `./claude/tools/flag list` — process any unread items before other work
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**If your handoff contains TODO: placeholders,** report to the captain:
> "Bootstrap handoff incomplete for designex — needs captain to run /discuss for workstream designex."

**Reference (read on demand, not every startup):**
- `claude/agents/designex/agent.md` — your role and responsibilities
- `claude/workstreams/designex/KNOWLEDGE.md` — workstream knowledge

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
