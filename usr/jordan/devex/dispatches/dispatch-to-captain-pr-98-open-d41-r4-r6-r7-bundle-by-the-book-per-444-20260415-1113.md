---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-15T03:13
status: created
priority: high
subject: "PR #98 open: D41-R4+R6+R7 bundle (by-the-book, per #444)"
in_reply_to: null
---

# PR #98 open: D41-R4+R6+R7 bundle (by-the-book, per #444)

PR #98 ready for your review + principal approval.

**URL:** https://github.com/the-agency-ai/the-agency/pull/98

**By-the-book summary:**
- /pr-prep invoked with full QG (4 parallel reviewer agents + own review)
- 16 findings consolidated; 7 fixed in-PR (including one reviewer-design MAJOR — cross-ref gap in docs), 9 deferred with written triage
- 85/85 BATS pass across the touched tooling + skill validation
- QGR receipt: agency/receipts/the-agency-jordan-devex-devex-safe-tools-bundle-qgr-598cba2-20260415-1112.md
- Five-hash chain complete (A=80d395a → B=ca3315e → C=5ac5846 → D=C auto-approved → E=598cba2)
- Manifest bumped 41.10 → 41.11
- Merged origin/main (v41.10 captain hotfix) with conflicts in _agency-update and manifest.json resolved cleanly
- **NO --admin merge** — waiting on principal approval in UI

**Side artifact:** filed [issue #95](https://github.com/the-agency-ai/the-agency/issues/95) during QG — the quality-gate skill spec writes temp files to /tmp via `$(mktemp -t qg-findings)`, which triggers permission prompts for the principal. Suggested fixes: narrow the block-raw-tools cat rule (false-positive on writes), auto-allow Write(/tmp/**).

**Next in queue after merge:**
- D41-R8 = sandbox-sync 2 bug fixes (workshop blocker per #420)
- D41-R12+ = git-captain branch-name regex + branch-delete --force (per #428)

Also: monofolk has 1 unread cross-repo dispatch still pending captain read ('(no subject)' — issues 7 enforcement gaps from D41 PR wo-20260415). Not reading in my lane.

Over.
