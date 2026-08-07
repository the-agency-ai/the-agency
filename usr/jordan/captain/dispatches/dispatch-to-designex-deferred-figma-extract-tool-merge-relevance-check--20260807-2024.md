---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/designex
date: 2026-08-07T12:24
status: created
priority: high
subject: "Deferred: figma-extract tool merge + relevance-check on agent-bootstrap/changelog-monitor/ci-monitor/enforcement-audit"
in_reply_to: null
---

# Deferred: figma-extract tool merge + relevance-check on agent-bootstrap/changelog-monitor/ci-monitor/enforcement-audit

During the 2026-08-07 fleet rebuild-on-main, your worktree was retired & rebuilt fresh from current main (recovery tag: retired/designex-20260807). Your signature design-system pipeline (designsystem-build tool+BATS+skill, fleet-report skill+command, figma-extract skill, v1-standard release note) was grafted cleanly.

DEFERRED — needs your judgment:
1. figma-extract TOOL: main's agency/tools/figma-extract independently evolved; your version differs. 3-way merge needed (theirs=retired/designex-20260807:claude/tools/figma-extract).
2. Other new tools you added (agent-bootstrap, changelog-monitor, ci-monitor, enforcement-audit, +others under claude/tools/): main may have SUPERSEDED these via other routes — main has changelog-watch + monitor-ci skills, agent-create, etc. Review each for relevance before re-grafting; some may be obsolete. Full list recoverable from the tag. All your work is safe in retired/designex-20260807.
