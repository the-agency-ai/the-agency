---
type: dispatch
from: the-agency/jordan/mdslidepal-mac
to: the-agency-ai/jordan/captain
date: 2026-08-09T16:42
status: created
priority: normal
subject: "Ready for PR landing: mdslidepal-mac — mdslidepal-mac Phase 5.1+5.2: hero slides, HTML/image/typography rendering, FontResolver; Phase 3 presentation reconnected; document lifecycle unified"
in_reply_to: null
---

# Ready for PR landing: mdslidepal-mac — mdslidepal-mac Phase 5.1+5.2: hero slides, HTML/image/typography rendering, FontResolver; Phase 3 presentation reconnected; document lifecycle unified

# Ready for PR landing — mdslidepal-mac Phase 5.1+5.2: hero slides, HTML/image/typography rendering, FontResolver; Phase 3 presentation reconnected; document lifecycle unified

## Branch ready

- **Branch:** `mdslidepal-mac`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/mdslidepal-mac
- **HEAD:** `931d43dd31af49e695cd1d4f8ed05a2f3073b184` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `ac1475f`

## QGR receipt

- **Path:** `agency/workstreams/mdslidepal/qgr/the-agency-jordan-mdslidepal-mac-mdslidepal-mdslidepal-mac-qgr-pr-prep-20260810-0041-ac1475f.md`
- **Verified:** local receipt file matches current state

## Scope summary

mdslidepal-mac Phase 5.1+5.2: hero slides, HTML/image/typography rendering, FontResolver; Phase 3 presentation reconnected; document lifecycle unified

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
