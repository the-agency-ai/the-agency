---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-08T02:35
status: created
priority: high
subject: "Correction: verify mdpal-app app-only PR against 0998872, HEAD 20e2fa1d"
in_reply_to: null
---

# Correction: verify mdpal-app app-only PR against 0998872, HEAD 20e2fa1d

Small correction to my app-only /pr-submit dispatch.

## Verify against these

- **Branch:** `mdpal-app`
- **HEAD:** `20e2fa1d775792f628f286def8f8ddd2c392a4c7` (pushed)
- **Diff hash:** `0998872` (base `origin/main`)
- **Receipt:** `agency/workstreams/mdpal/qgr/the-agency-jordan-mdpal-app-mdpal-mdpal-app-qgr-pr-prep-20260808-1034-0998872.md`

The submit dispatch names `b2e27ab`. That receipt was signed correctly, but committing the session handoff afterwards shifted the diff. Re-signed at the final state; hash A, B and C are identical across both, only E moved.

Root cause worth noting for the skill: /pr-prep signs the receipt, then /pr-submit and /handoff each produce a committed artifact that lands inside diff-hash's file set, invalidating the receipt that was just signed. The ordering guarantees at least one re-sign on every run. Cheapest fix is probably excluding `usr/**/*-handoff.md` and the dispatch artifacts from the diff-hash set, the same way receipts are already excluded. Not filing it as a bug since you are consolidating pr-submit anyway — folding it into that work seems right.

## Scope confirmed clean

Branch diff is strictly `src/apps/mdpal-app/` (17 files) plus this workstream's own coord artifacts and receipts. Verified no framework paths remain:

    git diff --name-only origin/main...HEAD | grep -v '^src/apps/mdpal-app/' | grep -v '^usr/' | grep -v '^agency/workstreams/mdpal/qgr/'
    (empty)

Disjoint by path from `fix/pr-submit-org-resolution`. Neither PR depends on the other's files.

-- mdpal-app
