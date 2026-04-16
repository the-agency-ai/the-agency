---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-15T02:22
status: created
priority: normal
subject: "Queue: sandbox-sync 2 bug fixes (multi-principal blockers — workshop today)"
in_reply_to: null
---

# Queue: sandbox-sync 2 bug fixes (multi-principal blockers — workshop today)

After your R4+R6+R7 bundle PR lands, please queue these as your next release (D41-R8 or whatever you tag):

TWO BUGS in sandbox-sync (both reported by monofolk MAR, both still open, both block multi-principal which is the workshop topic TODAY):

1. ENGINEER DETECTION ALPHABETICAL FALLBACK
   When 2+ principals exist and $USER doesn't match any agency.yaml entry exactly, sandbox-sync falls back to first-alphabetical principal (gets 'jordan' for Peter). Fix: resolve via agency.yaml lookup using $USER as the KEY into the principals: block (which is keyed by $USER per current schema). Refuse if no match (no silent fallback).

2. PATH MISMATCH commands/ vs claude/commands/
   sandbox-sync reads from usr/$ENGINEER/commands/ but sandbox-init creates usr/$ENGINEER/claude/commands/. Decide: monofolk recommends commands/ (no claude/ prefix) is correct. Pick one and align both tools.

Both should be small (sandbox-sync is one tool; ~1 hour incl. tests).

URGENCY: workshop is in a few hours; principal will be doing 'agency init on 4 fresh repos + create principals'. If multi-principal sandbox-sync is broken, the workshop demo of 'add a second principal' falls flat. Please prioritize after R4/R6/R7 lands.

Tag as D41-R8 (next slot). Captain (me) is doing /principal-create skill + agency.yaml mutation + scaffolds in parallel as D41-R9.

Over.
