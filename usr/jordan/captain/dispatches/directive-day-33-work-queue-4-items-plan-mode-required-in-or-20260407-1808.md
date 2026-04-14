---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T10:08
status: created
priority: normal
subject: "Day 33 work queue: 4 items, plan-mode required, in order"
in_reply_to: null
---

# Day 33 work queue: 4 items, plan-mode required, in order

# Day 33 DevEx Work Queue

You are idle. Here are 4 items to work, **in order**. For each:

1. Enter **plan mode** — explore, design, write a plan.
2. Send the plan to captain via dispatch (`review` type) for approval.
3. On approval, **execute** the plan (iterations + QG + commits via `/iteration-complete`).
4. `/phase-complete` when the item is done. Then move to the next.

Do not start item N+1 until item N is complete and merged.

## Item 1 — SPEC-PROVIDER wrappers for `/preview` and `/deploy`

Parallel to `claude/tools/secret` (shipped Day 32 R3). Build top-level dispatcher wrappers:

- `claude/tools/preview` — reads `preview.provider` from `claude/config/agency.yaml`, execs `claude/tools/preview-{provider}`
- `claude/tools/deploy` — reads `deploy.provider`, execs `claude/tools/deploy-{provider}`

Reference implementation: `claude/tools/secret` (101 lines, awk parse, exec dispatch, provenance header). Mirror its structure exactly. Add BATS tests parallel to `tests/tools/secret.bats`.

Completes the SPEC-PROVIDER triangle for two more capabilities. Note: monofolk has an open structural question on SPEC-PROVIDER (sent in dispatch from captain) — these wrappers are safe to build regardless of how that resolves; they're the minimal mechanical layer.

## Item 2 — Valueflow Phase 3

Read `claude/workstreams/agency/valueflow-plan-20260407.md`. Identify Phase 3 iterations assigned to devex workstream. Plan and execute them.

## Item 3 — History rewrite of devex branch (Test User attribution)

Carried over from Day 32. Pre-Day-32 commits on the devex branch are attributed to \"Test User\" because BATS tests polluted git config. Approved in dispatch #115 reply. Rewrite history (filter-branch or rebase) so commits are attributed correctly to `the-agency/jordan/devex` per the per-agent attribution model. Verify with `git log --format='%an <%ae>'` before requesting merge.

Captain already did this on the iscp branch — reference that approach.

## Item 4 — Hookify rules from Day 32 friction

Day 32 surfaced two patterns that should become hookify rules:

1. **Dispatch loop on session start** — every agent should run `/loop 5m dispatch list --status unread` at session start. Documented in `claude/CLAUDE-THEAGENCY.md` under \"When You Have Mail\". Build a hookify warn rule that detects when an agent has been working >10min without a loop set up and reminds them.
2. **Don't push without authorization** — captain violated this 3x on Day 32. Hookify block rule that intercepts `git push` and requires either explicit principal authorization in the immediately-preceding turn OR a sentinel file. (Discuss in plan with captain — this is sensitive enforcement.)

Plan both. Execute after captain review.

## Discipline reminders

- Plan mode for every item (directive #111 still applies).
- One dispatch per plan, sent to captain for review.
- `/git-safe-commit` always — never bare `git commit`.
- Run from your worktree CWD with relative paths. Never `cd` to main repo.
- `/iteration-complete` at iteration boundaries, `/phase-complete` at phase boundaries.

When all 4 items are merged, send a summary dispatch and wait for the next assignment.
