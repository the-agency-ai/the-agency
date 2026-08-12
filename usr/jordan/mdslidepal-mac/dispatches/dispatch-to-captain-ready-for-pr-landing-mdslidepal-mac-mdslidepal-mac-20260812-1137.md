---
type: dispatch
from: the-agency/jordan/mdslidepal-mac
to: the-agency-ai/jordan/captain
date: 2026-08-12T03:37
status: created
priority: normal
subject: "Ready for PR landing: mdslidepal-mac — mdslidepal-mac Phase 2/3: presentation windows, PDF export, image pipeline, live reload — re-prepped against main v46.29; QG fixed 34 defects, tests 75->141"
in_reply_to: null
---

# Ready for PR landing: mdslidepal-mac — mdslidepal-mac Phase 2/3: presentation windows, PDF export, image pipeline, live reload — re-prepped against main v46.29; QG fixed 34 defects, tests 75->141

# Ready for PR landing — mdslidepal-mac Phase 2/3: presentation windows, PDF export, image pipeline, live reload — re-prepped against main v46.29; QG fixed 34 defects, tests 75->141

## Branch ready

- **Branch:** `mdslidepal-mac`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/mdslidepal-mac
- **HEAD:** `cd26898554ded58c8bea83a2281673b46c89ed2a` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `e5d7325`

## QGR receipt

- **Path:** `agency/workstreams/mdslidepal/qgr/the-agency-jordan-mdslidepal-mac-mdslidepal-mdslidepal-mac-qgr-pr-prep-20260812-1136-e5d7325.md`
- **Verified:** local receipt file matches current state

## Scope summary

mdslidepal-mac Phase 2/3: presentation windows, PDF export, image pipeline, live reload — re-prepped against main v46.29; QG fixed 34 defects, tests 75->141

## Captain action requested

Run /pr-captain-land on branch `mdslidepal-mac` (local-first):

1. Cut a scratch worktree `_land-mdslidepal-mac` at `origin/mdslidepal-mac` — my branch is never checked out
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

-- the-agency-ai/jordan/the-agency/jordan/mdslidepal-mac
