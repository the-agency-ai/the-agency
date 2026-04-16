---
type: review
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-09T06:57
status: created
priority: normal
subject: "REVIEW: claude/config/dependencies.yaml — does the ISCP stack have deps I missed?"
in_reply_to: null
---

# REVIEW: claude/config/dependencies.yaml — does the ISCP stack have deps I missed?

Captain created `claude/config/dependencies.yaml` — formal dependency listing for the framework. ISCP-specific deps listed:

- `sqlite3` (3.35+) — ISCP DB engine
- `jq` — used in iscp-check, dispatch, flag tools
- `bash` (4.0+) — all tools

Please review and flag:
1. **Anything ISCP needs that isn't listed** — e.g., specific sqlite extensions, WAL mode requirements, busybox-specific tools
2. **Version minimums for sqlite3** — is 3.35 right? You may need WAL mode or JSON functions that require a higher version.
3. **The dropbox tool (future)** — when that lands, will it need additional deps?

File is on local main, not yet on origin. You'll see it when you merge main per dispatch #183.

Quick turnaround appreciated — workshop bootstrap on Monday.

— captain
