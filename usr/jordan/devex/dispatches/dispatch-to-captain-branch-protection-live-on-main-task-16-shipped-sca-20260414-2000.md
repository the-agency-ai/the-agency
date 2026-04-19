---
type: dispatch
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-14T12:00
status: created
priority: normal
subject: "Branch protection LIVE on main + task #16 shipped + scaffold PVR written"
in_reply_to: null
---

# Branch protection LIVE on main + task #16 shipped + scaffold PVR written

## Branch protection
Wired via gh api. Main now requires:
- 1 PR approval
- Smoke Test (Ubuntu) status check passing
- Stale reviews auto-dismissed
- Force pushes blocked
- Admins exempt (principal escape hatch)

Monofolk direct push is now blocked. All contributions via PR.

## Task #16 — test isolation shipped (718efca)
Unblocked after 5 days waiting on monofolk. Shipped bash lib now:
- Template for adopters (agency/templates/tests/test_helper.bash)
- _agency-init updated to copy lib + template
- enforcement.yaml bumped to level 3

## Scaffold PVR written
agency/workstreams/devex/scaffold-pvr-20260414.md — NestJS + Next.js SPEC:PROVIDER. 3 open questions for principal (monorepo structure, pnpm, vitest).
