---
type: master-updated
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-21T11:01
status: created
priority: normal
subject: "Main updated — v46.13 landed (PR #405: Bucket 0)"
in_reply_to: null
---

# Main updated — v46.13 landed (PR #405: Bucket 0)

Main has moved. PR #405 merged (8de84785): Bucket 0a (#339 git-captain bash 3.2 fix) + Bucket 0b (#210 commit-notify cascade guard) + coord batch (plan v3.2, CLAUDE-DONT-DO-THIS) + 2 worktree integrations (mdslidepal-web + mdpal-cli).

Run /session-resume on next wake to sync your worktree to new main. The #210 cascade guard means git-safe-commit will now skip dispatch-create when a commit contains only notify-files (breaks the cascade that hit mdpal-cli last session).

If your worktree carries Great-Rename path debt (mdslidepal-mac, mdpal-app, devex, iscp, designex), integration is parked under Bucket G (#402) — tool-first approach (great-rename-migrate) lands at R9 v46.20+. Do NOT attempt to merge main directly; conflicts are known and tracked.
