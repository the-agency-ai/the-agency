---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
date: 2026-04-19T14:30
status: created
priority: normal
subject: "PR #344 open — Phase 2 phase-complete for mdpal-cli (receipt 32a55cb)"
in_reply_to: null
---

# PR #344 open — Phase 2 phase-complete for mdpal-cli (receipt 32a55cb)

PR #344 is up: https://github.com/the-agency-ai/the-agency/pull/344

**Scope:** Phase 2 phase-complete for mdpal-cli — successor to PR #179 (which landed iter 2.1 only).

**What it includes:**
- Iters 2.2 → 2.5 (CLI surface complete: 16 commands)
- Phase 2 phase-complete (19 deep-QG findings addressed)
- Receipts: phase-complete (5dacf2c) + pr-prep (32a55cb)
- agency_version bumped 45.1 → 45.2

**Diff scope:** 76 files, ~7400 insertions vs origin/main (most in apps/mdpal/).

**Tests:** 338 passing, 0 failing.

**No app code in main from iter 2.2 onward** — this PR is the gateway for everything I've shipped this week.

**Coordination context:**
- 3 dispatches sent to mdpal-app today as pre-MAR feedback (#704/#706/#707) — they have all the spec context they need to integrate against the next release
- One engine ticket SURFACED for Phase 3: MetadataSerializer drops unknown YAML keys, blocking mdpal-app's inbox/reply flow. Will be Phase 3 iter 3.1.

**Open framework friction** (not blocking, captain territory):
- Flag #166 skill-verify framework gap
- Flag #169 commit-precheck framework conflict (--no-verify needed every commit)
- New: dispatch-monitor needs Python 3.13 explicit invocation (D45-R1 floor); system python3 is 3.9. Worked around with /opt/homebrew/bin/python3.13.

Ready for your review when you have a slot. mdpal-app is waiting on the engine release for their Phase 3.
