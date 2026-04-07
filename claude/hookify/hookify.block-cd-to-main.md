---
trigger: PreToolUse
matcher: Bash
---

# Block: cd to main repo before running tools

If the Bash command starts with `cd /Users/` or `cd ~/` or `cd $HOME` followed by `&&`, BLOCK it.

**Why:** Agent identity resolution uses the current working directory's git branch. When a worktree agent cd's to the main repo, `agent-identity` resolves to `captain` instead of the correct agent. This causes handoffs, dispatches, and flags to go to the wrong agent.

**What to do instead:** Run tools with relative paths from your worktree:
- `./claude/tools/dispatch list` — NOT `cd /path/to/main && ./claude/tools/dispatch list`
- `./claude/tools/handoff write --trigger ...` — NOT `cd /path/to/main && ./claude/tools/handoff write`

All Agency tools work from any worktree directory. Never cd to the main repo.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
