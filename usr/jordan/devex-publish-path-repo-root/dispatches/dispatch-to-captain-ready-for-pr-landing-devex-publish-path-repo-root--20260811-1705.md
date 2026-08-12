---
type: dispatch
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency-ai/jordan/captain
date: 2026-08-11T09:05
status: created
priority: normal
subject: "Ready for PR landing: devex-publish-path-repo-root — -C repo-root targeting so pr-captain-land's publish path signs and gates the scratch worktree, not the captain checkout; plus first test coverage of steps 4-9"
in_reply_to: null
---

# Ready for PR landing: devex-publish-path-repo-root — -C repo-root targeting so pr-captain-land's publish path signs and gates the scratch worktree, not the captain checkout; plus first test coverage of steps 4-9

# Ready for PR landing — -C repo-root targeting so pr-captain-land's publish path signs and gates the scratch worktree, not the captain checkout; plus first test coverage of steps 4-9

## Branch ready

- **Branch:** `devex-publish-path-repo-root`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/devex-publish-path-repo-root
- **HEAD:** `acc733acdac59e77cf9da3c382aeaa6f5260ad99` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `8f81cef`

## QGR receipt

- **Path:** `agency/workstreams/devex/qgr/the-agency-jordan-devex-devex-publish-path-repo-root-qgr-pr-prep-20260811-1704-8f81cef.md`
- **Verified:** local receipt file matches current state

## Scope summary

-C repo-root targeting so pr-captain-land's publish path signs and gates the scratch worktree, not the captain checkout; plus first test coverage of steps 4-9

## Captain action requested

Run /pr-captain-land on branch `devex-publish-path-repo-root` (local-first):

1. Cut a scratch worktree `_land-devex-publish-path-repo-root` at `origin/devex-publish-path-repo-root` — my branch is never checked out
2. Verify this QGR receipt against that tree, BEFORE any mutation
3. Validate locally in the scratch (build + tests + commit-precheck) — this is the gate
4. Bump `agency_version` in the scratch (serialized — single writer)
5. Sign a captain landing receipt chained to this one
6. Push the scratch branch and open the PR
7. Wait on the aggregate status check rollup, merge when green
8. Create GitHub release v{agency_version}, dispatch back with confirmation

If local validation fails, nothing is published and I get a dispatch naming the
failing step.

## What I (agent) will NOT do

- Create the PR myself
- Bump `agency_version` myself
- Merge myself
- Create the release myself

Captain owns the PR lifecycle. I stand by to /pr-respond if review comments come.

Over.

-- the-agency-ai/jordan/the-agency/jordan/devex-publish-path-repo-root
