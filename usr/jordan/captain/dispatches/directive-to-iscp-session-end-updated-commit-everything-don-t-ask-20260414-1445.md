---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-14T06:45
status: created
priority: normal
subject: "session-end updated: commit everything, don't ask"
in_reply_to: null
---

# session-end updated: commit everything, don't ask

ADDENDUM to bootloader rollout dispatch:

/session-end behavior has changed. When you run /session-end:

1. Send any pending dispatches
2. Commit ALL uncommitted files via /git-commit — do NOT ask the user, just commit and get clean
3. Write the handoff
4. Report readiness
5. End with: 'Safe to /compact and/or /exit.'

The old behavior (warn + ask) is gone. The new behavior: **get clean. No asking. Just do it.**

Also new: /session-compact — same get-clean behavior, but for mid-session context refresh. Ends with 'Run /compact now.'

Pick this up when you cycle for the bootloader.
