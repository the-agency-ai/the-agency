---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-17T04:38
status: created
priority: normal
subject: "New issue #180 — Monitor tool for test runs and follow-up triggers"
in_reply_to: null
---

# New issue #180 — Monitor tool for test runs and follow-up triggers

Principal filed #180 and assigned it to you: use Monitor tool to track test runs and trigger follow-up.

Three patterns to consider:
- Pattern A: monitor a single suite to completion, react to failures mid-run
- Pattern B: continuous test-watch, emit only on transitions (green↔red, new failure)
- Pattern C: trigger follow-up dispatch/flag on outcome (green → commit-ready; red → test-failure with payload)

Precedent to follow: dispatch-monitor (D44-R1, Python, bash 3.2 compat). Same Monitor tool pattern, same line-buffered stdout, same silent-when-nothing-happens discipline.

Full issue: https://github.com/the-agency-ai/the-agency/issues/180

Fits in your DevEx domain: test infrastructure + commit workflow + Monitor integration. Design in a PVR/A&D when you pick it up. No rush — land after your current Phase 1.4 work.
