---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-09T05:58
status: created
priority: normal
subject: "DONE Item 1 (#149): SPEC-PROVIDER preview/deploy wrappers shipped"
in_reply_to: 149
---

# DONE Item 1 (#149): SPEC-PROVIDER preview/deploy wrappers shipped

## Item 1 complete

SPEC-PROVIDER preview/deploy wrapper work from Day 33 directive #149 is done and has been in git since commit `82a52c8` (prior session). All tests green as of today's sanity check: 78/78 on preview+deploy+secret+enforcement-audit combined.

## Why dispatch-direct instead of formal /phase-complete

The implementation + QG fixes landed several sessions ago (commit `82a52c8`, 'Phase 1 (Day 33 Item 1): SPEC-PROVIDER preview/deploy + QG fixes'). The /phase-complete ritual on already-committed-and-tested work doesn't add value — it would just regenerate a QGR receipt for code that has been through QG already. Your autonomy directive #174 is the justification for going direct.

If you WANT the formal ritual (QGR receipt file, sprint-review format), tell me and I'll run /phase-complete against the existing commit. Otherwise consider this the completion record.

## What's in `82a52c8`

- `claude/tools/preview` — SPEC-PROVIDER wrapper for preview.provider (default docker-compose)
- `claude/tools/deploy` — SPEC-PROVIDER wrapper for deploy.provider (default fly)
- `claude/tools/secret` — slug validation backport (security fix from QG)
- `tests/tools/preview.bats` — 20 tests (was 12 at the first commit, +8 from QG)
- `tests/tools/deploy.bats` — 20 tests (same shape)
- `claude/config/enforcement.yaml` — 3 new SPEC-PROVIDER dispatcher entries
- Hookify guards remain in place

## QG findings addressed (from the in-session QG run)

From the multi-agent review that session:
- Cluster A (security): provider name slug validation `^[a-z0-9][a-z0-9_-]*$` across all 3 wrappers — prevents path traversal via `provider: '../../tmp/evil'` or shell injection via `provider: 'foo;rm'`
- Cluster B: awk parser section-exit hardening (`/^[a-z]/` → `/^[^ \t#]/`)
- Cluster F: enforcement.yaml integrity (consistent naming + correct doc references)
- Cluster G: dead-code cleanup in test fixtures
- +8 coverage tests per file

Deferred per your prior decisions:
- _provider-resolve lib extraction (mirror-secret-exactly approach preferred)
- Reference provider stubs (no stubs per #153 Q3)
- Verb contract enforcement (architectural, separate)

## Queue status

Task #8 (Item 1) → done now
Task #15 (#174 docker-heal / GH #58) → done earlier this session, dispatch #178
Task #16 (test isolation extraction) → paused pending monofolk/devex RFI #176 (lib extraction committed as `ba4e499`, adopter-facing extensions parked)

Unblocked next:
- Task #9 (Plan #166 worktree naming) — I have the rule from #169 already
- Task #10 (Plan #167 hookify rename)
- Task #11 (Plan #168 agent-create dispatch loops)
- Task #12 (Item 2 Valueflow Phase 3)
- Task #13 (Item 4 Hookify rules) — blocked on #12

Will proceed through these in order under autonomy unless you redirect. Next up: task #9.
