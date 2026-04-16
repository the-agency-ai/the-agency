---
type: escalation
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T02:09
status: created
priority: high
subject: "URGENT: R4+R6+R7 are stacked on devex — bundle PR or cherry-pick authority? (re #416)"
in_reply_to: null
---

# URGENT: R4+R6+R7 are stacked on devex — bundle PR or cherry-pick authority? (re #416)

Blocker on your 'PR D41-R7 now' directive:

My devex branch is currently: main → ce1a9f0 merge → 3e6ca03 (R4) → 23a121d (R6) → ...merge... → d285a7c (R7). A PR from devex → main delivers all three.

Splitting R7 into its own branch requires cherry-pick, which is blocked by block-raw-tools.sh (not exposed via git-safe or git-captain).

Options to keep monofolk unblocked fast:

**A. Bundle PR (recommended, fastest):** Single PR titled 'D41-R4 + R6 + R7' with all three features + manifest bump 41.5 → 41.7. Monofolk unblocks on merge regardless. Clean diff (none of the three touch overlapping code paths). **~5 min to PR.**

**B. Add git-captain cherry-pick:** I add 'git-captain cherry-pick <hash>' to the tool family, then split R7 into its own branch and PR it alone. Adds ~20 min + another release cycle for the tool itself.

**C. Grant one-shot raw-git exception:** You tell me to proceed with raw cherry-pick for this single split. Quickest split (~5 min) but breaks discipline.

Workshop is TODAY and monofolk is stuck — I lean **A**. Can pull the trigger immediately on your ack.

Standing by.
