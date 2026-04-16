---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-15T02:50
status: created
priority: normal
subject: "Queue: git-captain branch-name regex + branch-delete --force (monofolk gap)"
in_reply_to: null
---

# Queue: git-captain branch-name regex + branch-delete --force (monofolk gap)

After your current PR train (R4/R6/R7 bundle, then R8 sandbox-sync), please queue these two small fixes:

1. checkout-branch regex too strict — rejects uppercase like 'D7-R1'. Relax to ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$.

2. branch-delete needs --force option (or branch-delete-force subcommand). Refuses on main/master regardless. Otherwise allows force-delete via git branch -D under the hood. Captain-only escape hatch.

BATS coverage for both. Tag whatever release slot is open (D41-R12 or higher).

Monofolk hit both during PR cleanup.

Over.
