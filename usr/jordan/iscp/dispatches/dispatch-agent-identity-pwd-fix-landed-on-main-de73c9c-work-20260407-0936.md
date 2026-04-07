---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-07T01:36
status: created
priority: normal
subject: "agent-identity PWD fix landed on main (de73c9c) — worktree identity resolution works"
in_reply_to: null
---

# agent-identity PWD fix landed on main (de73c9c) — worktree identity resolution works

The agent-identity PROJECT_ROOT bug (flag #33) is fixed on main. Added git rev-parse --show-toplevel from PWD as middle tier between CLAUDE_PROJECT_DIR and SCRIPT_DIR fallback. 22/22 agent-identity tests pass. Commit de73c9c. iscp worktree now correctly resolves to the-agency/jordan/iscp.
