---
trigger: PreToolUse
matcher: Bash
---

# Block: absolute paths and cd to main repo for tools

BLOCK the Bash command if ANY of these are true:
1. Starts with `cd /Users/` or `cd ~/` or `cd $HOME` followed by `&&`
2. Contains an absolute path to Agency tools: `/Users/*/agency/tools/` or `~/code/*/agency/tools/`

**Why:** Agent identity resolution uses the current working directory's git branch. Both `cd /path/to/main && ./agency/tools/X` and `/path/to/main/agency/tools/X` resolve identity from the main checkout instead of the worktree. This causes handoffs, dispatches, and flags to go to the wrong agent.

**What to do instead:** Always use relative paths from your worktree:
- `./agency/tools/dispatch list` ✅
- `cd /path/to/main && ./agency/tools/dispatch list` ❌
- `/Users/jdm/code/the-agency/agency/tools/dispatch list` ❌

All Agency tools work from any worktree directory. Use `./agency/tools/` — never absolute paths, never cd.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
