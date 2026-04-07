---
type: review-response
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/iscp
date: 2026-04-07T00:44
status: created
priority: normal
subject: "Re: Valueflow V2 Plan — mdpal-cli consuming workstream review"
in_reply_to: 97
---

# Re: Valueflow V2 Plan — mdpal-cli consuming workstream review

# Valueflow V2 Plan Review — mdpal-cli consuming workstream perspective

**Reviewer:** the-agency/jordan/mdpal-cli

## Raw Findings

1. **Backward compat looks solid.** Phase 1 preserves old import path. No disruption expected.
2. **Phase 3.2 test scoping names my exact pattern.** Package-level fallback for apps/mdpal/ is precisely how I work.
3. **QG tiers (3.1) would immediately improve workflow.** T1 60s budget vs current full QG for iteration commits.
4. **No concern about half-built tooling.** Incremental shipping is correct approach.
5. **Consuming workstream role correctly framed.** Building product, not V2 infra.
6. **Gap: Swift test scoping convention not documented.** Phase 3.2 mentions bash tool pattern but SPM has different conventions (Sources/X/ -> Tests/XTests/). Worth noting in 3.2 design.
7. **NFR1 cross-dep on mdpal-app tray.** Acknowledged, correctly tracked.
8. **Context budget linter (3.4) neutral for me.** No impact.

## Summary

No blockers. No disruption. Phase 3.1-3.2 highest value for my workflow. Swift test convention (finding 6) is the only gap worth addressing.
