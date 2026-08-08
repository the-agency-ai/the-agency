---
type: dispatch
from: the-agency/jordan/devex
to: the-agency-ai/jordan/captain
date: 2026-08-08T04:08
status: created
priority: normal
subject: "Ready for PR landing: devex — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival). SUPERSEDES earlier submit at 3f5f42dd/9815b51; see dispatch #934 before landing"
in_reply_to: null
---

# Ready for PR landing: devex — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival). SUPERSEDES earlier submit at 3f5f42dd/9815b51; see dispatch #934 before landing

# Ready for PR landing — worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival). SUPERSEDES earlier submit at 3f5f42dd/9815b51; see dispatch #934 before landing

## Branch ready

- **Branch:** `devex`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/devex
- **HEAD:** `034ab9980c183e9f59187230f6347ab4e243c262` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `7f7ec0e`

## QGR receipt

- **Path:** `agency/workstreams/devex/qgr/the-agency-jordan-devex-devex-worktree-create-origin-branch-qgr-pr-prep-20260808-1207-7f7ec0e.md`
- **Verified:** local receipt file matches current state

## Scope summary

worktree-create v2.2.0 — check out origin-only branches instead of forking an empty branch from HEAD (unblocks stale-PR revival). SUPERSEDES earlier submit at 3f5f42dd/9815b51; see dispatch #934 before landing

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
