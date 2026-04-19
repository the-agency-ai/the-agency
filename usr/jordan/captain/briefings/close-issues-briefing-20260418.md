---
type: briefing
workstream: housekeeping
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-18
trigger: 1B1 Close Issues — morning agenda item 1
total_flags: 73
themes: 7
---

# Close Issues Briefing — 1B1 Agenda

**Goal:** close out flag backlog across 7 themes in one 1B1 pass. No new issues filed in this pass — those all went through Workstream E last night (#229–#269). This is exclusively about closing flags that no longer need individual discussion.

**Rule going forward:** flag persistence = GitHub issue (ratified D44). Flags are short-lived. If something matters, it's an issue. If not, it's closed.

## Theme 1 — Fixed in a release (22 flags)

All items closed by a prior merge. No discussion needed; batch-close.

| Flag | Closed by |
|------|-----------|
| #1 | early release (baseline) |
| #2, #3 | agent-identity resolution fixes |
| #22 | hookify triangle rollout |
| #27 | dispatch tool subcommand fix |
| #51, #54 | worktree sandbox sync fixes |
| #83 | pre-commit hook fix |
| #93 | agent-create flow fix |
| #96, #97, #98, #99, #100, #101 | D40 tool fixes cluster |
| #104 | handoff tool idempotency |
| #112 | git-safe permission fix |
| #113 | release-tag-check workflow (D41-R20) |
| #116 | skill-verify false-positive fix |
| #133, #141, #147 | QG receipt infra / MAR polish |

**Recommendation:** batch `flag resolve` all 22.

## Theme 2 — Decided & locked (22 flags)

Items where a principal decision happened; no further action. Batch-close.

Flags: #11, #12, #13, #19, #23, #24, #25, #26, #36, #50, #60, #61, #63, #64, #68, #70, #72, #73, #76, #79, #84, #85

**Recommendation:** batch `flag resolve` all 22. If any need a doc reference (so the decision is preserved), note and file one enhancement issue for that doc update, then close.

## Theme 3 — Tracked externally (7 flags)

Anthropic feedback / cross-repo items. Not our queue to close via fix; close as "tracked upstream."

Flags: #9, #10, #52, #67, #74, #75, #82

**Recommendation:** batch-close. Keep an audit trail of the external tracking (comment on each before close with the external link / reference if known).

## Theme 4 — Superseded / rejected / cancelled (9 flags)

Items we explicitly chose not to pursue or that were replaced by a different direction.

Flags: #7, #16, #17, #18, #20, #57, #59, #77, #134

**Note:** Flag #134 — "audit bash tools for Python 3.12 rewrite" — was filed as HIP #223 during the D45 autonomous setup (with Python 3.13 in place of 3.12). Close the flag; issue #223 supersedes.

**Recommendation:** batch-close.

## Theme 5 — Time-bound event completed (3 flags)

Flags: #49, #66, #128

These captured attention for a specific event (meeting, window, release). Event passed; close.

**Recommendation:** batch-close.

## Theme 6 — Test noise / empty flag entries (6 flags)

Flags: #37, #38, #39, #69, #131, #132

Either one-word test captures or empty. Pollution from testing the flag tool itself.

**Recommendation:** batch `flag resolve`. Consider a hookify rule that warns on very-short flag text (<30 chars) to nudge toward either issue-filing or not-flagging.

## Theme 7 — Already a GH issue / absorbed (4 flags)

| Flag | Existing issue |
|------|----------------|
| #136 | → #177 (Agent duty register) |
| #35 | → existing captured in dispatch-monitor work |
| #42 | → existing observability issue |
| #41 | → existing captured in telemetry work |

**Recommendation:** close each flag with a comment pointing at the GH issue.

## Flags filed as NEW issues in Workstream E (for reference)

Not to be closed — moved to GH issue tracker last night. See issues #229–#269.

Pass 1 (defer→issue) and Pass 2 (was-seed) flags are now in the GH queue. Some were skipped as dupes of existing issues:
- #126 → #206 (sync-main)
- #118, #124, #125 → #210 (commit-dispatch loop)
- #107 → HIP #227 (receipt chain-verify)
- #47 → already dispatched to devex
- #43, #44, #45, #48, #80 → test noise (Theme 6)

## 1B1 proposal

Batch-close as one atomic 1B1 item per theme. Total time: <15 minutes if all batches are accepted as-is. Per-flag discussion only if principal wants to mark a specific flag for reopening / attention.

## Related agenda items for the same 1B1

0. Review + merge D45-R1 PR (#213) — Python 3.13 floor
1. 1B1 Close Issues (this briefing)
2. Ratify flag→issue rule (rewrite `/flag-triage` skill so outcomes are `close`, `do now`, or `file issue` — no "defer" state)
3. Install-vs-repo boundary discussion (flag #146/#165) — new issue TBD depending on outcome
4. HIP Sprint FIFO (epic #215, children #216–#228)
5. Release notes mechanism — `/define` (PVR) → issue #214

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
