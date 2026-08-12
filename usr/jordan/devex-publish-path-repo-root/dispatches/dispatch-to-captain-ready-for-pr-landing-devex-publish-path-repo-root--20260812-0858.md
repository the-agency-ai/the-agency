---
type: dispatch
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency-ai/jordan/captain
date: 2026-08-12T00:58
status: created
priority: normal
subject: "Ready for PR landing: devex-publish-path-repo-root — -C repo-root targeting for the pr-captain-land publish path (steps 4-9) + git-sync default-branch guard and merge-not-rebase fix"
in_reply_to: null
---

# Ready for PR landing: devex-publish-path-repo-root — -C repo-root targeting for the pr-captain-land publish path (steps 4-9) + git-sync default-branch guard and merge-not-rebase fix

# Ready for PR landing — -C repo-root targeting for the pr-captain-land publish path (steps 4-9) + git-sync default-branch guard and merge-not-rebase fix

## Branch ready

- **Branch:** `devex-publish-path-repo-root`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/devex-publish-path-repo-root
- **HEAD:** `2a07f80a059945340dbc1419864802efe382cc0d` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `d60f4bd`

## QGR receipt

- **Path:** `agency/workstreams/devex/qgr/the-agency-jordan-devex-devex-publish-path-repo-root-qgr-pr-prep-20260812-0858-d60f4bd.md`
- **Verified:** local receipt file matches current state

## Scope summary

-C repo-root targeting for the pr-captain-land publish path (steps 4-9) + git-sync default-branch guard and merge-not-rebase fix

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
