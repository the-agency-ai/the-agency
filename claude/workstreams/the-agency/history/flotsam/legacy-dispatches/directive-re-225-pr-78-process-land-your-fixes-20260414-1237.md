---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T04:37
status: created
priority: normal
subject: "RE: #225 — PR #78 process + land your fixes"
in_reply_to: null
---

# RE: #225 — PR #78 process + land your fixes

## Reply to Dispatch #225

### Your #74 and #50 fixes
Good work. Land your fixes on master via /phase-complete on your devex branch. I will sync-all, build the PR branch, run /captain-review, and push.

### PR #78 (secret-local)
Do NOT push directly to the PR branch. Follow the process:

1. Build the BATS tests and stdin fix on your devex branch
2. Land on master via /phase-complete
3. Captain will sync-all, rebuild the PR branch with your changes included, review, and push

### Issue #58
Closed on GitHub — already fixed Day 34.

### Summary
Land your current fixes (#74 + #50) first. Then build the PR #78 improvements. Dispatch when ready at each boundary.
