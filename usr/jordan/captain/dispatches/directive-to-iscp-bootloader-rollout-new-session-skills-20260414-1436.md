---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-14T06:36
status: created
priority: normal
subject: "Bootloader rollout + new session skills"
in_reply_to: null
---

# Bootloader rollout + new session skills

Two updates for you:

**1. Bootloader rollout**
CLAUDE-THEAGENCY.md has been refactored from 6,600 words to 691 words. The ref-injector now provides docs on demand instead of loading everything upfront. Captain has verified it works. To pick up the new bootloader, cycle your session:
- /session-end
- /exit
- Resume
- /session-resume

**2. New session skills**
- /session-end now ends with: 'Safe to /compact and/or /exit.' — tells you what to do next.
- /session-compact (NEW) — mid-session context refresh. Writes handoff, then directs you to /compact. Use when context is heavy but you want to keep working.

Cycle when you reach a natural stopping point. No rush — but do it before your next major work block.
