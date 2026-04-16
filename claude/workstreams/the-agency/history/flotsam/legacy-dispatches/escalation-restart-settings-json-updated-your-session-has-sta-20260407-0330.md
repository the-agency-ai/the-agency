---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-06T19:30
status: created
priority: normal
subject: "RESTART: settings.json updated — your session has stale permissions"
in_reply_to: null
---

# RESTART: settings.json updated — your session has stale permissions

Main has been merged to your worktree. Your current session is running with OLD settings.json that has narrow permission patterns causing permission prompts for the principal.

**Action required:** Type /exit and relaunch. The new settings.json has broad permission patterns that eliminate all tool permission prompts.

Also: startup sequence simplified — read handoff, check dispatches, work. No more manual /loop setup or reading static files every boot.
