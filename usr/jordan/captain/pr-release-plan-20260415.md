---
type: plan
date: 2026-04-15
author: the-agency/jordan/captain
horizon: next 24-48h
---

# PR / Release Plan — D41-R3 onward

Snapshot taken 2026-04-15 ~0834 local. Covers all 7 workstreams.

## Sequencing — landing order

| Slot | Release | Source | Status | Owner |
|------|---------|--------|--------|-------|
| 1 | D41-R2 / v41.2 | PR #90 (jordan-captain-d41-r2) | Open, awaiting principal review + smoke CI | captain |
| 2 | D41-R3 / v41.3 | PR #87 (contrib/claude-tools-collaboration) | Open, awaiting principal review | captain (cleanup of contrib) |
| 3 | D41-R4 / v41.4 | devex branch (3e6ca03) | Devex shipped, ready to PR | devex |
| 4 | D41-R5 / v41.5 | NEW — devex Phase 2 receipt-QG integration + iscp design bundle docs | Proposed | captain to dispatch |
| 5 | D41-R6 / v41.6 | NEW — coord-commit skill stale-instructions fix + collaboration path-traversal hardening + git pull --ff-only (monofolk QG followups) | Proposed | captain |

**Why this order:** D41-R2 unlocks captain workflow (sync-main / --remote merge), which unblocks every subsequent post-merge step. D41-R3 finishes adopting PR #87. Devex's R4 is ready and small. R5 bundles two ready artifacts (Phase 2 receipt QG integration is committed on devex branch but never released; iscp design bundle is a 9k-word artifact set that should be pushed to main as the milestone marker). R6 closes the monofolk QG findings loop in one cohesive release.

## Per-workstream status

### devex
- **Released:** through commit 3e6ca03 (D41-R4 large-file blocker, ready)
- **Unreleased on branch:**
  - Phase 2.1 — BATS coverage for git-safe (30) + git-captain (35) [a8b4f76, e6b2c07]
  - Phase 2.2 — receipt infrastructure Phase 2 QG integration [a8b4f76]
  - Phase 2.3 — scaffold PVR [5e81385]
  - Phase 2.4 — end-to-end receipt verification [2e5fec6]
  - Phase 2.5 — large-file blocker [3e6ca03]
- **Recommendation:** D41-R4 covers the large-file blocker; bundle Phase 2.1-2.4 into D41-R5 (Receipt Phase 2 release). Devex's PR for D41-R4 should NOT include Phase 2.1-2.4 — keep R4 minimal so it can land fast.
- **Open queue:** scaffold PVR continues, awaiting monofolk pnpm/vitest/monorepo confirmations.

### iscp
- **Released:** main is at d756796 (D41-R1)
- **Unreleased on branch:** Dispatch Service PVR + A&D + Plan complete (8/8 plan iterations, 8 weeks, GA Week-8) [ec13922]
- **Status:** Awaiting principal sign-off before Iter 1 (per Plan §8). Session ended.
- **Recommendation:** Sign off the design bundle, PR docs as part of D41-R5, then iscp picks up Iter 1.

### mdpal-cli
- **Released:** main is at d756796 (D41-R1) — no mdpal-cli content on main yet (app workstream)
- **Unreleased on branch:** Phase 1 complete (175 tests, 51 bundle tests) [1a18718]
- **Status:** Idle, awaiting phase-complete direction.
- **Open question for principal:** does mdpal-cli (Reference Source License app workstream) follow the framework's PR-per-release discipline, or does it have its own release cadence to landing-on-main? **NEEDS DECISION.**

### mdpal-app
- **Released:** main has nothing
- **Unreleased on branch:** Phase 1A complete — 5 iterations [80fbe37 → fe7cb37], 43/43 tests
- **Status:** Just approved /phase-complete 1A; Phase 1B (real-CLI integration) authorized.
- **Same open question as mdpal-cli** about app-workstream PR cadence.

### mdslidepal-mac
- **Released:** main has nothing
- **Unreleased on branch:** Phase 5.2 visual polish complete [fba18fc], 44/44 tests
- **Status:** Phase 5 wrapping; awaiting visual verification + overflow-policy decision.
- **Same app-workstream question.**

### mdslidepal-web
- **Released:** main has nothing
- **Unreleased on branch:** Phase 1.1 complete [a21fa59], idle awaiting direction
- **Same app-workstream question.**

### designex
- **Released:** at d756796 (just synced from main, no new work yet)
- **Status:** Idle, picking up after worktree sync. Phase 1.1 (figma-extract v2) uncommitted per #362.
- **Recommendation:** Continue autonomous; no PR until first iteration boundary.

## App-workstream PR cadence — open question

The framework's "PR = release" discipline is canonical for `claude/`, `tests/`, `usr/jordan/` framework code. App workstreams (mdpal-cli, mdpal-app, mdslidepal-mac, mdslidepal-web) live at `claude/workstreams/<name>/` (Reference Source License) and their code lives in their own dirs.

**Three possible disciplines:**
1. **Same as framework:** every iteration → PR → release tag. High cadence, may not match app-feature shape.
2. **Phase boundary only:** PR per phase boundary, multi-iteration changes batched. Lower cadence, more meaningful releases. Aligns with "phase-complete" semantics.
3. **No PR / direct merge:** app workstreams skip PR review for solo development; integration happens via worktree merge to main on demand. Lowest overhead, weakest quality gate.

**Captain recommendation:** Option 2 (PR per phase). Provides a real release boundary, surfaces the app to the rest of the fleet at meaningful chunks, doesn't drown the PR queue. But this needs principal decision — affects mdpal-cli, mdpal-app, mdslidepal-mac, mdslidepal-web simultaneously.

## Action queue for principal

1. **Approve PR #90** (D41-R2) — unblocks subsequent flow
2. **Approve PR #87** (D41-R3) — adopts contrib + cleanup
3. **Decide app-workstream PR cadence** — Option 1, 2, or 3 above
4. **Sign off ISCP Dispatch Service bundle** (PVR + A&D + Plan) — see separate ISCP memo
5. **Direct iscp on Iter 1 start** after sign-off

## Action queue for captain (autonomous)

1. After PR #90 lands → run /post-merge 90 (now possible with sync-main tool)
2. After PR #87 lands → run /post-merge 87, GitHub release v41.3
3. Dispatch devex to PR D41-R4
4. Bundle D41-R5 (Phase 2 receipt + ISCP docs)
5. Address monofolk QG findings as D41-R6 (path traversal, ff-only, secret-local hardening, agency update --delete investigation, coord-commit skill instructions)

## Captain notes

- Tool gaps surfaced this session: git-captain sync-main (FIXED in R2), git-safe merge-from-master --remote (FIXED in R2), git-safe unstage (FLAGGED #130), git-safe-commit pre-stage QGR paradox (FLAGGED #131).
- Receipt-infrastructure (D40-R3 Phase 1, devex Phase 2 unreleased) is foundational — landing R5 unblocks proper boundary signing for app workstreams when they cut PRs.
- Monofolk QG was substantive — 4 fixed in R3, 6 to address in R4-R6.
