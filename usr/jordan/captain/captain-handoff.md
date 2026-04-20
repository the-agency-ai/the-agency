---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-20
trigger: mid-session-checkpoint
mode: agency-v3-reset-phases-1-2-3-landed-continuing
---

# Captain handoff — agency-v3-reset, Phases 1/2/3 + salvage landed, continuing

Mid-session checkpoint. Principal said "plenty of context" — continuing execution after this handoff.

## Branch: `agency-v3-reset` (10 commits, all pushed)

```
1683bc73 feat(v46.1): Phase 3 + salvage — cruft removal + Phase 0 reset tools + canaries + 4 tool fixes
9fa5fbe2 feat(v46.1): Phase 2f — designex→design-lead (directory rename; content refactor deferred)
9c73b22f feat(v46.1): Phase 2c — dead artifacts archived to src/archive/
76029e0d feat(v46.1): Phase 2 more — apps→src/apps + starter-packs→src/spec-provider + 9 non-class agents archived
8278ded6 session-end(v46.1): agency-v3-reset Phase 1 + Phase 2 partial landed
7460fb1f feat(v46.1): Phase 2 partial — REFERENCE/ + README/ subdirs + data→config + receipts-to-workstream + LICENSE
4c7d00e6 fix(v46.1): captain identity resolution (salvaged from abandoned branch)
37091dc5 feat(v46.1): Phase 1 — Great Rename claude/ -> agency/
af5d26ff chore(v46.1): disable hooks for Phase 1-4.5 rename window
ed3af9ad [base origin/main] Merge pull request #346 contrib/claude-skills-transcript-SKILL-md
```

## Completed phases

| Phase | Status |
|-------|--------|
| Pre-plan (plan v5, plan mode + ExitPlanMode approval) | ✓ |
| Phase -1 (latent tool-ref audit) | ⚠ partial — subagent timed out; report not written; gap accepted for Phase 7 to catch |
| Phase 0 (branch prep + cherry-pick-strategy) | ✓ agency-v3-reset cut from origin/main; abandoned branch tagged |
| Phase 1 (Great Rename) | ✓ commit `37091dc5` — 944 files, atomic |
| Phase 2 (subdir reorg) | ✓ 11/12 — only 2e templates consolidation deferred |
| Phase 3 (cruft removal) | ✓ commit `1683bc73` — docs/integrations/assets/logs/tools/usr-test handled |
| **Salvage from abandoned tag** | ✓ 53 files — 35 canaries + 14 Phase 0 reset tools + 4 tool fixes |

## Pending phases

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 2e (templates merge) | pending | `agency/agents/templates/` + `agency/templates/` have different content; non-trivial merge |
| Phase 3.5/3.6 | **IN FLIGHT** | Consolidate `workstreams/{agency, captain, housekeeping}` into `the-agency/`; retire KNOWLEDGE.md across designex/devex/iscp/mdpal |
| Phase 4 | pending | **BIG**: `git mv agency/ src/agency/` and `.claude/shippable → src/claude/` — single source of truth |
| Phase 5 | pending | **SUBSTANTIAL**: Python build tool at `src/tools/build` — ~500 lines + BATS tests |
| Phase 6 | pending | First build run; stamps all at D46.R1 |
| Phase 7 | pending | **5-subagent reference sweep** — per plan v4 proper |
| Phase 8 | pending | Verification (canaries, agency-verify-v46, BATS, vitest) |
| Phase 9 | pending | Release cadence infra (cron, release-cut tool, self-update) |
| Phase 10 | pending | Release notes + migration runbook |
| Phase 11 | pending | PR create |
| Phase 12 | pending | Merge + release v46.1 + tag agency-v3 |
| Phase 13 | pending | andrew-demo cleanup (subagent-delegable) |

## Workstream consolidation targets (Phase 3.5/3.6 in flight)

`agency/workstreams/` currently contains:
- `agency/` — legacy duplicate, consolidate into `the-agency/`
- `captain/` — legacy duplicate, consolidate into `the-agency/`
- `housekeeping/` — legacy duplicate, consolidate into `the-agency/`
- `designex/`, `devex/`, `iscp/`, `mdpal/`, `mdslidepal/`, `mock-and-mark/` — keep (per-app/per-workstream)
- `gtm/` — keep but mark TODO-MOVE-TO-THE-AGENCY-GROUP
- `test; rm -rf ` — **DELETE** (injection artifact from PVR §4.3)
- `the-agency/` — target workstream (keep + absorb consolidations)

KNOWLEDGE.md files to retire (subsumed into REFERENCE): designex, devex, iscp, mdpal.

## Critical files

- Plan v5: `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`
- Today's transcript: `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
- Abandoned branch: tag `abandoned/v46.0-overnight-shortcut-20260420` on origin
- Current branch: `agency-v3-reset` on origin

## Next concrete actions

1. Phase 3.5/3.6: consolidate workstreams + retire KNOWLEDGE.md
2. Phase 2e: templates merge
3. Phase 4: src/ source reorg (`git mv agency/ src/agency/`)
4. Phase 5: Python build tool — should be its own subagent delegation
5. Phase 6: first build
6. Phase 7: 5-subagent sweep — parallel subagents, worktree-isolated
7. Phase 8: verification
8. Phase 9-12: release
9. Phase 13: andrew-demo cleanup — subagent

## If context runs out

This handoff is the continuation anchor. Next session reads this + plan v5 + today's transcript to resume from current commit `1683bc73`.

— captain, 2026-04-20 mid-session
