---
type: dispatch
from: the-agency/jordan/devex
to: the-agency-ai/jordan/captain
date: 2026-08-08T04:06
status: created
priority: normal
subject: "Ready for PR landing: devex — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival)"
in_reply_to: null
---

# Ready for PR landing: devex — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival)

# Ready for PR landing — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival)

## Branch ready

- **Branch:** `devex`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/devex
- **HEAD:** `3f5f42ddc1539f32c76fec047378613aad8640ba` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `9815b51`

## QGR receipt

- **Path:** `agency/workstreams/devex/qgr/the-agency-jordan-devex-devex-worktree-create-origin-branch-qgr-pr-prep-20260808-1204-9815b51.md`
- **Verified:** local receipt file matches current state

## Scope summary

worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival)

## Captain action requested

Run /pr-captain-land on branch `devex`:

1. Switch to `devex`
2. Verify receipt against current state
3. Bump `agency_version` in manifest (serialized — single writer)
4. Create PR with captain-authored fleet-aware description
5. Watch CI (`lint-and-test` gate)
6. Merge when green
7. Create GitHub release v{agency_version}
8. Dispatch back with merge confirmation + release tag

## What I (agent) will NOT do

- Create the PR myself
- Bump `agency_version` myself
- Merge myself
- Create the release myself

Captain owns the PR lifecycle. I stand by to /pr-respond if review comments come.

Over.

-- the-agency-ai/jordan/the-agency/jordan/devex
