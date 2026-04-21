---
type: session
agent: the-agency/jordan/captain
date: 2026-04-21T05:03:00Z
trigger: session-end
branch: main
mode: resumption
next-action: Start a fresh session and decide whether to begin Plan v5 Phase 4+ work (Stage D — start with issue #374 install-surface manifest schema) or pick up one of the stabilization items (#55 CI build-out, #384 BATS Docker, #387 _test-isolation leak, #385 commit-precheck hang). Principal already approved the staging layout; next session can just execute the chosen lane. Before starting, run /session-resume which will sync + surface any new dispatches.
pause_commit_sha: none
---

# Captain handoff — session end 2026-04-21

## Session headline

6-hour day-shift session. Two PRs merged, two releases cut, eleven GitHub issues filed, one adopter repo brought current, two cross-repo dispatches sent, dispatch queue fully drained.

## Shipped this session

### PRs merged + releases

| PR | Content | Release |
|---|---|---|
| **#386** | v46 sweep-miss — 162 files, final claude/ → agency/ pass + smoke.yml CI stub | **v46.10** |
| **#391** | Purge test-pollution from main + .gitignore guards | **v46.11** |

### Adopter sync

- **andrew-demo**: bootstrap-rsync'd to v46.11 (local commit 1b7ddc7); manifest bumped; `agency verify` now 10/12 (2 deferred figma warnings unrelated). Not yet pushed to andrew-demo's GitHub remote.

### Cross-repo (monofolk)

- Dispatch: **monitor-register re-implementation** — asked for review / adoption / joint contract
- Dispatch: **designex Phase 1.5 diff report + asks (2)(3) reply** — closes the-agency task #19, unblocks designex agent
- Dispatch: **the-agency#342 ETA — state-report (not estimate)** per monofolk's "stop-estimating" directive — 6 deferred cleanups reported as "parked in queue, not forgotten"

### Issues filed (session-wide)

| # | Subject |
|---|---|
| #382 | v46 sweep-miss umbrella (CLOSED by #386) |
| #383 | presence-detect status line missing framework version |
| #384 | BATS tests must run in Docker (test isolation) |
| #385 | commit-precheck scoped-bats hangs on large PRs |
| #387 | `_test-isolation` leaks into real tree |
| #388 | `git-safe add` rejects directory paths (DX) |
| #389 | `git-safe unstage` shell-meta path gap |
| #390 | Post-mortem: #386 merge baked pathological files (CLOSED by #391) |
| #392 | agency update chicken-egg (v46 adopters can't sync agency/ tree) |

Plus internal task #55: **CI build-out** — real `smoke` battery + lint + typecheck + vitest.

### Dispatch queue processed

- **107 commit-notify dispatches** bulk-resolved (Python loop over `dispatch resolve`)
- **4 stale dispatches** resolved (Python friction, iscp FYI, superseded PR notification, old master-sync request)
- **3 live dispatches acted on** — designex Phase 1.5 relayed, #342 ETA state-reported, monofolk routing-check cleared
- **0 unread** at session end

## Key decisions captured

1. **`--no-verify` is acceptable for mechanical sweeps** when foreground tests are already green AND the scoped-bats timeout would block (#385). Principal authorized for today's #386; should remain rare.

2. **`smoke.yml` placeholder is fine short-term** as long as CI build-out (#55) lands soon. Real battery replaces the stub.

3. **Plan v5 Phase 4+ staging confirmed** — principal approved the C/A/B/D layout:
   - **C** Andrew-demo update ✅
   - **A** Monofolk monitor-register dispatch ✅
   - **B** Dispatch backlog ✅
   - **D** Plan v5 Phase 4+ — not started, is the next session's open lane

4. **"Stop estimating" directive internalized** (from monofolk/jordan). Captain reports state (planned/parked/in-flight) — never estimates timelines.

5. **Dispatch discipline reminder**: principal noted "when a dispatch sits, it blocks someone." Commit to `/monitor-dispatches` at every session-start next time.

## Right-now state

- **Branch:** `main`
- **Last commit:** `c77fce0c` (merge PR #391)
- **Tree:** clean
- **HEAD on origin:** `c77fce0c` (synced)
- **v46.11 released on GitHub:** ✅ https://github.com/the-agency-ai/the-agency/releases/tag/v46.11
- **0 unread dispatches, 0 new flags this session** (flag queue has 157 pre-existing items — seed/observation items tagged for later triage)
- **andrew-demo** on v46.11 locally; GitHub remote still at v46.1 pending push

## Plan v5 status (Track M / Track S separation)

Per principal's correction last session: Phase 4 (src/ split) is **Track S**, NOT required for Track M. Track M = manifest-driven installer, can ship independently.

**Track M (manifest-driven installer):**
- **#374** install-surface manifest schema + populate ← FIRST (gate)
- #375 init manifest-driven (depends #374)
- #376 update manifest-driven (depends #374)
- #377 drift detection (depends #374, closes #329)
- #372 release automation (after #375+#376)

**Track S (src/ split, deferred):**
- #378 Phase 4 — establish `src/agency/` + `src/claude/` sources
- #379 Phase 5 — Python build tool at `src/tools/build`
- #380 Phase 6 — first build + dual-tracked output commit
- #381 Phase 8 — post-refactor full verification

**Task #39** (Phase 4 src/ split) remains pending under Track S.

## Stabilization backlog (not blocking next session)

- **#55** CI build-out (replace smoke.yml placeholder with real battery)
- **#384** BATS Docker isolation (structural fix for test pollution)
- **#387** `_test-isolation` leak (immediate companion to #384)
- **#385** commit-precheck scoped-bats hang
- **#383** presence-detect status line
- **#388** git-safe add DX
- **#389** git-safe unstage gap
- **#392** agency update chicken-egg (NEW — high severity for v46 adopters)

## Open coordination items

- andrew-demo push to GitHub (local commit 1b7ddc7 hasn't been pushed to `https://github.com/the-agency-ai/andrew-demo.git`) — principal to decide whether to push or keep local
- Flag backlog (157 items) — periodic triage via `/flag-triage` skill (not urgent)

## Recovery next session

1. `/session-resume` — syncs master, reads this handoff, checks dispatches. Includes `session-preflight`.
2. Start `/monitor-dispatches` **at session-start** (commitment from this session — don't let them pile up again).
3. Review `next-action` — decide D lane vs stabilization item.
4. Execute.

## Related transcripts / receipts

- v46.10 QGR: `agency/workstreams/agency/qgr/the-agency-jordan-captain-agency-v46-claude-path-sweep-qgr-pr-prep-20260421-1230-e43a182.md`
- v46.11 QGR: `agency/workstreams/agency/qgr/the-agency-jordan-captain-agency-purge-test-pollution-qgr-pr-prep-20260421-1244-bfa9fb9.md`
- Sweep manifest: `usr/jordan/captain/sweep-manifest-v46-claude-paths.yaml`

— captain, session-end, 2026-04-21T05:03 UTC (13:03 SGT)
