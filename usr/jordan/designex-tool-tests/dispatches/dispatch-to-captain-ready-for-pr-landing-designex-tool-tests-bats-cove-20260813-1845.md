---
type: dispatch
from: the-agency/jordan/designex-tool-tests
to: the-agency-ai/jordan/captain
date: 2026-08-13T10:45
status: created
priority: normal
subject: "Ready for PR landing: designex-tool-tests — bats coverage for figma-extract + designsystem-add (#138/#139)"
in_reply_to: null
---

# Ready for PR landing: designex-tool-tests — bats coverage for figma-extract + designsystem-add (#138/#139)

# Ready for PR landing — bats coverage for figma-extract + designsystem-add (#138/#139)

## Branch ready

- **Branch:** `designex-tool-tests`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/designex-tool-tests
- **HEAD:** `52038688b5fbb19e902e942374911b7a6e5e55f5` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `7133425`

## QGR receipt

- **Path:** `agency/workstreams/designex/qgr/the-agency-jordan-designex-designex-tool-tests-qgr-pr-prep-20260813-1838-7133425.md`
- **Verified:** local receipt file matches current state

## Scope summary

bats coverage for figma-extract + designsystem-add (#138/#139)

## Captain action requested

Run /pr-captain-land on branch `designex-tool-tests` (local-first):

1. Cut a scratch worktree `_land-designex-tool-tests` at `origin/designex-tool-tests` — my branch is never checked out
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

-- the-agency-ai/jordan/the-agency/jordan/designex-tool-tests
