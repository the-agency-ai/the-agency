---
type: dispatch
from: the-agency/jordan/revive-release-notes
to: the-agency-ai/jordan/captain
date: 2026-08-12T12:33
status: created
priority: normal
subject: "Ready for PR landing: revive-release-notes — revive agency-captain-release-notes (#426) on v46.33 — tool + skill + src/ mirrors + 59 BATS, QG-hardened"
in_reply_to: null
---

# Ready for PR landing: revive-release-notes — revive agency-captain-release-notes (#426) on v46.33 — tool + skill + src/ mirrors + 59 BATS, QG-hardened

# Ready for PR landing — revive agency-captain-release-notes (#426) on v46.33 — tool + skill + src/ mirrors + 59 BATS, QG-hardened

## Branch ready

- **Branch:** `revive-release-notes`
- **Agent:** the-agency-ai/jordan/the-agency/jordan/revive-release-notes
- **HEAD:** `7ecd4179e93f5a05c10126b0550a6f2f30fc69ef` (pushed to origin)
- **Diff base:** `origin/main`
- **Diff hash:** `b24beec`

## QGR receipt

- **Path:** `agency/workstreams/devex/qgr/the-agency-jordan-revive-release-notes-devex-agency-captain-release-notes-qgr-pr-prep-20260812-2032-b24beec.md`
- **Verified:** local receipt file matches current state

## Scope summary

revive agency-captain-release-notes (#426) on v46.33 — tool + skill + src/ mirrors + 59 BATS, QG-hardened

## Captain action requested

Run /pr-captain-land on branch `revive-release-notes` (local-first):

1. Cut a scratch worktree `_land-revive-release-notes` at `origin/revive-release-notes` — my branch is never checked out
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

-- the-agency-ai/jordan/the-agency/jordan/revive-release-notes
