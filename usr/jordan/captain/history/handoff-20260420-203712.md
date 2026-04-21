---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-20
trigger: session-end
mode: v46.1-shipped-cleanup-PR-358-open
---

# Captain handoff — v46.1 SHIPPED + post-ship cleanup PR #358 open

## NEXT SESSION PRIORITY (principal directive at session-end)

**After /compact:**
1. **Merge PR #358** (v46.1 post-ship cleanup — 11 commits, clean)
2. **Re-migrate andrew-demo against final state** (subagent task):
   - Abandoned branch `agency-v3-migration-20260420` (push but no PR) gets overwritten or abandoned
   - Subagent regenerates full v45→v46.1+cleanup migration from andrew-demo's main
   - Opens one clean PR against `the-agency-ai/andrew-demo`

## TL;DR

**v46.1 AgencyV3 foundation shipped.** Tag `agency-v3` live. 16 commits merged to main as PR #356 (`c2e31da0`). GitHub release: https://github.com/the-agency-ai/the-agency/releases/tag/v46.1

**Post-ship cleanup PR #358 open** (`v46.1-post-ship-cleanup` branch): 11 commits addressing 10 items + permissions + CLAUDE-the-agency.md.

## Session shape

~14 hours spanning:
- Overnight autonomous execution failure post-mortem (v46.0-structural-reset abandoned)
- Plan v5 rework via extended 1B1 (full decision record in transcript)
- ExitPlanMode approval → AgencyV3 v46.1 execution (new branch from origin/main)
- Ship (PR #356 → main + tags v46.1 + agency-v3 + GitHub release)
- Post-ship cleanup (10 items on PR #358)

## Key artifacts

- **Plan v5 approved:** `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` + `docs/plans/20260420-agencyv3-structural-reset-build-boundary-installer.md`
- **Today's 1B1 transcript:** `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
- **Release notes:** `agency/workstreams/the-agency/releases/Release-D46-R1-20260420.md`
- **Workstream class doc:** `agency/workstreams/the-agency/CLAUDE-the-agency.md` (created today)

## What shipped in v46.1 (PR #356, merged, tag agency-v3)

- Great Rename `claude/` → `agency/` (944 files, atomic, history preserved)
- Subdir organization: `agency/REFERENCE/`, `agency/README/`, `agency/LICENSE.md`
- Sprawl cleanup: docs/, integrations/, assets/, logs/, receipts/, injection artifact
- Tree reorg: apps→src/apps, starter-packs→src/spec-provider, 9 non-class agents archived, designex→design-lead
- Workstream consolidation: legacy agency/captain/housekeeping → the-agency history/flotsam; KNOWLEDGE.md retired
- Identity + tool fixes: agent-identity main-checkout, block-raw-tools.sh `--agent` flag, commit-precheck/handoff/icloud-setup/test-scoper/pr-create fixes
- Salvage from abandoned: 35 canaries + 14 Phase 0 reset tools
- Content reference sweep: ~265 files
- Hook settings restoration with agency/ paths
- Manifest 45.2 → 46.1; symbolic tag `agency-v3`

## Post-ship cleanup on PR #358 (11 commits, pushed, open)

| # | Item | State |
|---|------|-------|
| 1 | agency/principals/ → flotsam | ✓ |
| 2 | agency/reviews/ → flotsam | ✓ |
| 3 | agency/proposals/ → the-agency-group (cross-repo) | ✓ |
| 4 | agency/agents/ class-dirs cleanup (sessions, notes, backups, logs) | ✓ |
| — | Permissions: additionalDirectories + Read/Edit/Write for the-agency-group, collaboration-monofolk, andrew-demo | ✓ |
| 5 | 28 framework-dev tools → src/tools-developer/ | ✓ |
| 6 | 35 canaries → src/tests/hookify/canaries/ + runner updated | ✓ |
| 7 | Test files repositioned | ✓ |
| 8 | CLAUDE-the-agency.md created | ✓ |
| 9 | Unwired commit-msg hook → flotsam; recipes/ DELETED | ✓ |
| 10 | 5 dead tools DELETED (nit-add/resolve, hello, hi, welcomeback); opportunities→dev; requests→flotsam | ✓ |

## Naming convention established

`src/{artifact}-{audience}/` — audience ∈ {`platform`, `developer`}:
- `-platform` = sources that build/ship to customer
- `-developer` = framework-dev only

Currently populated: `src/tools-developer/` (28 tools). Others populate as Phase 4 source split happens (v46.2+).

## Follow-up issues filed

- **#349** — t-shirt sizing + complexity + subagent-suitability skill
- **#350** — hookify canary coverage gap (6 un-synthesizable rules)
- **#357** — noun-verb naming enforcement + rename update-config → config-update

## Principal directives crystallized today (permanent decisions)

- Stop estimating (agents have no training data for AI-augmented delivery; estimation is principal-owned)
- Sizing via t-shirts (XS/S/M/L/XL) + complexity (Trivial/Easy/Moderate/Complex) + subagent-suitability (yes/no)
- Release versioning = D.R; today = D46
- Daily release cadence 2300 SGT with override A (manual cut) + B (skip via Release-Skip file)
- RGR = Review Gate Receipt (docs); QGR = Quality Gate Receipt (implementation)
- Seed = single document (Model A); supporting material in research/
- KNOWLEDGE.md retired (subsumed into REFERENCE docs)
- Build boundary: src/ → build → agency/ + .claude/ (dual-tracked, Python 3.13+ stdlib, per-artifact D.R versioning with frontmatter authoritative + derived manifest)
- Distribution: rails init model (agency tool is single entry point; agency init + agency update; default GitHub source + --source local override; no tarballs)
- agency-v3 symbolic tag = installer threshold

## andrew-demo adopter status

- **Branch:** `agency-v3-migration-20260420` pushed to origin (commit `1a76a1e`)
- **PR:** **NOT CREATED** (subagent pushed branch; gh pr create never invoked)
- **Main:** still at pre-migration state
- **Action next session:** re-migrate against final v46.1+cleanup state after PR #358 merges; open one clean PR; existing branch gets overwritten or abandoned (per principal directive)

## Branch + tag state at session end

- **Current branch:** `v46.1-post-ship-cleanup` (all 11 commits pushed, PR #358 open)
- **Main:** `c2e31da0` (v46.1 merge commit)
- **Tags live on origin:** `v46.1`, `agency-v3`, `v45.2` (pre-shipping anchor), `abandoned/v46.0-overnight-shortcut-20260420` (historical)
- **Working tree:** clean

## Next session priorities (ordered)

1. Merge PR #358 (cleanup ships as D46.R2 today or D47.R1 tomorrow)
2. Re-migrate andrew-demo against final state (subagent task)
3. **v46.2 planning** — deferred Phase 4-9 from Plan v5:
   - Phase 4: src/claude/ + src/agency/ source split
   - Phase 5: Python 3.13+ stdlib build tool at src/tools-platform/build
   - Phase 6: first dual-tracked build
   - Phase 9: release cadence cron (GitHub Actions at 2300 SGT)
   - Phase 7: proper 5-subagent reference sweep (upgrade from today's single-pass)
4. Follow-ups: issues #349, #350, #357; receipt-sign sweep miss; the-agency-group collab config
5. Principal + Matt multi-principal setup (designed in today's transcript)
6. Flag triage (5 unread accumulated)
7. Dispatch review (114 accumulated notifications — triage on next session)

## Known gaps at session end

- `agency/tools/agency-verify-v46` moved to `src/tools-developer/` in Item 5 — any caller still pointing at agency/tools/ path will ENOENT
- Bulk sweep (Phase 7 single-pass) left 67 files with legitimate `.claude/` references — acceptable
- 6 hookify rules still un-synthesizable for canary (issue #350)
- receipt-sign writes to hardcoded `claude/workstreams/` path (sweep miss; noted in release notes)
- andrew-demo migration outdated vs today's cleanup work

— captain, 2026-04-20 session-end (v46.1 shipped + cleanup PR #358 open)
