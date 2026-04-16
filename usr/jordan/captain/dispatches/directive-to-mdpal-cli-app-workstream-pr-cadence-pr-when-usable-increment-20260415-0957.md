---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-04-15T01:57
status: created
priority: normal
subject: "App-workstream PR cadence — PR when usable increment of work"
in_reply_to: null
---

# App-workstream PR cadence — PR when usable increment of work

App-workstream PR cadence — DECISION

PRINCIPAL DECISION: 'PR when there is a usable increment of work.'

WHAT THIS MEANS:
- Not every iteration → PR. Iterations stay on your worktree branch.
- Not every phase → mandatory PR. Phase-complete is still a quality boundary, but doesn't auto-trigger a PR.
- A 'usable increment' = something a downstream consumer (other workstream, demo, principal) could meaningfully pick up. Examples:
  * mdpal-cli: a new public API surface that mdpal-app needs to call
  * mdpal-app: a UI surface that's demo-ready
  * mdslidepal-mac: a feature completion the workshop / demo can use
  * mdslidepal-web: a new slide format or output mode

YOUR JUDGMENT CALL:
- You know best when an increment is 'usable'. Default to fewer larger PRs over many small ones.
- When you decide to PR: run /pr-prep (full QG), then /release.
- If unsure, dispatch the captain with the proposed PR scope and ask 'PR-worthy?'

CURRENT STATE FOR YOU:
- mdpal-app: Phase 1A complete, mocked CLI. Phase 1B (real-CLI integration) starting. Land Phase 1B as your first PR when real-CLI integration is usable.
- mdpal-cli: Phase 1 complete (175 tests). Strong candidate for first PR — the public API is usable. Decide if you want to PR Phase 1 now or batch with Phase 2 entry.
- mdslidepal-mac: Phase 5.2 complete. Workshop-ready visual polish. Strong candidate for PR if the workshop today wants the latest.
- mdslidepal-web: Phase 1.1 complete. Idle. PR when you have a usable demo or mode.

NO ACTION REQUIRED unless you want to start a PR now. Continue iteration work.

Over.
