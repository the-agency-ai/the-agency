---
type: seed
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-06T05:11
status: created
priority: high
subject: "Seed: permission model overhaul — eliminate permission fatigue"
in_reply_to: null
---

# Seed: permission model overhaul — eliminate permission fatigue

From valueflow MARFI triage. Principal mandate: 95% of permission prompts are not needed. Getting prompted when not needed, not asked when should be. Three work items: (1) Audit all tools in claude/tools/ — ensure correct permissions in settings-template.json. (2) Mine session transcripts for common tool usage patterns — build tools for common jobs, ensure permissions. (3) Wire PermissionDenied hook to auto-retry known safe patterns that get wrongly blocked. Goal: prompt only when human judgment adds value. Reference: usr/jordan/captain/friction-points-20260405.md (P1-P6), claude/config/settings-template.json.
