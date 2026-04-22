---
trigger: PreToolUse
matcher: Bash
---

# Block: raw handoff tool — use /handoff skill

If the Bash command contains `agency/tools/handoff` (with or without path prefix, with or without `bash` prefix), BLOCK it.

**Why:** The `/handoff` skill handles archiving, path resolution, and content guidance. The raw tool bypasses skill orchestration and agents consistently misuse it (wrong CWD, wrong flags, writing files manually after).

**What to do instead:**
- `/handoff` — invokes the skill, which calls the tool correctly
- `/session-end` — for session teardown (includes handoff)

The skill calls the tool. You don't.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
