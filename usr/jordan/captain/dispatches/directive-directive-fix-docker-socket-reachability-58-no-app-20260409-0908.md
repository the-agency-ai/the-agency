---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-09T01:08
status: created
priority: normal
subject: "DIRECTIVE: fix docker socket reachability (#58) — no approval needed, just do it"
in_reply_to: null
---

# DIRECTIVE: fix docker socket reachability (#58) — no approval needed, just do it

New work for your queue. Jordan explicit direction: do not wait for approval on this or the existing #171 items. Just do it.

## Task

Fix GitHub issue #58 — docker CLI cannot connect to daemon when Docker Desktop is running. Full context in the issue.

https://github.com/the-agency-ai/the-agency/issues/58

## Scope

- Investigate why `docker-test.sh` fails with unix:///var/run/docker.sock when Docker Desktop IS running
- Implement one of the three acceptance options (auto-detect, actionable error, or docker-heal tool)
- Write bug-exposing test — simulate 'Docker Desktop running but CLI can't reach' and verify the fix works
- Red → green, commit on devex branch, land via /phase-complete

## Authorization level

FULL AUTONOMY on this and all Day 33 queue items previously dispatched.
- Do NOT wait for captain or principal approval on per-step decisions.
- Execute the red-green cycle on your own.
- Commit and land on your own.
- Only escalate if you hit a true blocker (conflict, ambiguity about intent, missing permission).

## Context on process expectation

Jordan just said explicitly: 'Tell DevEx don't wait for approval to do it. Just do it.' This applies not just to #58 but to the entire open queue:
- #8 Item 1 /phase-complete (SPEC-PROVIDER preview/deploy) — just do it
- #9-#13 from dispatch #149 — just do them in order
- #171 unblock sequence (merge conflict resolve, handoff restore, stash cleanup) — just do it per the direction in #173
- #166, #167, #168 per previous dispatches — just do them

You have standing authorization to execute. Loop back only with results, not for permission.

## Report back

- Resolve each dispatch as you complete its item
- Send review-response on major milestones (e.g., 'issue #58 closed', 'Day 33 queue item N complete')
- Do NOT send 'blocked on approval' dispatches — there is no approval gate on your queue

## Current main commits you should merge in

- ac73ce9 run-in Triangle + #57 worktree-sync fix
- 2a62f8d #171 Gate 0 Test User block
- c746d04 #56 agency update yaml sections
- 118ae29 34.1 agency-version

Merge main first, then tackle #58.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
