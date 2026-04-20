---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-20
trigger: session-end
mode: agency-v3-reset-phase-1-and-2-partial-landed
---

# Captain handoff — agency-v3-reset branch, Phase 1 + Phase 2 partial landed

## Session summary

Today was a **post-failure review + rework + initial execution** session for the v46.0-structural-reset that was abandoned due to overnight captain-solo shortcut. Out of it emerged:

1. **AgencyV3 project branding** (V1 = the-agency-starter, V2 = v45.x, V3 = this — "true installer" threshold)
2. **Release versioning = D.R** (today = **D46.R1** = v46.1); symbolic tag `agency-v3` at first-true-installer release
3. **Plan v5** at `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` — approved via plan mode + ExitPlanMode
4. **Structural decisions** — comprehensive 1B1 covering everything in `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
5. **Abandoned branch** `v46.0-structural-reset` tagged as `abandoned/v46.0-overnight-shortcut-20260420` and pushed
6. **Fresh branch** `agency-v3-reset` cut from current `origin/main` HEAD (ed3af9ad)

## Branch state (agency-v3-reset)

```
7460fb1f feat(v46.1): Phase 2 partial — REFERENCE/ + README/ subdirs + data→config + receipts-to-workstream + LICENSE
4c7d00e6 fix(v46.1): captain identity resolution (salvaged from abandoned branch)
37091dc5 feat(v46.1): Phase 1 — Great Rename claude/ -> agency/ (atomic, history preserved)
af5d26ff chore(v46.1): disable hooks for Phase 1-4.5 rename window
ed3af9ad Merge pull request #346 from the-agency-ai/contrib/claude-skills-transcript-SKILL-md  [base = origin/main]
```

Pushed to origin. Branch clean.

## Phase completion

| Phase | Status | Notes |
|---|---|---|
| Pre-Phase: plan v5 drafted + approved + ExitPlanMode | ✓ DONE | `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` + `docs/plans/20260420-agencyv3-...` |
| Phase -1: latent-tool-reference audit | **IN FLIGHT** | Subagent launched in background; report at `/tmp/phase-minus-1-audit-report.md` when complete. Covers whoami-class bugs. |
| Phase 0: branch prep + tag abandoned + cut fresh | ✓ DONE | abandoned/v46.0-overnight-shortcut-20260420 tagged + pushed. agency-v3-reset cut from origin/main. |
| Phase 1: Great Rename | ✓ DONE | commit `37091dc5`. 944 files renamed atomic. History preserved. |
| Phase 2: Subdir reorg | **PARTIAL (2g, 2h, 2i, 2j, 2l done; 2a-f, 2k pending)** | commit `7460fb1f`. REFERENCE/, README/, data→config, receipts-to-workstream, LICENSE added. |
| Phase 3: Archive + cruft removal | PENDING | Executes Phase -1 1B1 resolutions (docs→the-agency-group, integrations→src, assets→src, logs→delete, latent-tool-reference fixes, usr/test, tools/*.ts). |
| Phase 3.5/3.6: Workstream consolidation + KNOWLEDGE.md retirement | PENDING | |
| Phase 4: src/ source reorg | PENDING | git mv agency/ → src/agency/; .claude/shippable → src/claude/. Biggest structural step. |
| Phase 5: Python build tool | PENDING | src/tools/build, Python 3.13+ stdlib. Full BATS coverage. |
| Phase 6: First build | PENDING | Produces dual-tracked agency/ + .claude/ from src/. Stamp all at D46.R1. |
| Phase 7: 5-subagent reference sweep | PENDING | Per plan v4 spec (properly this time). A=tools, B=docs, C=skills/commands/subagents, D=agents, E=hooks/hookify/config/.gitignore/package.json. Worktree-isolated. |
| Phase 8: Rebuild + canary fill + verification | PENDING | Post-sweep rebuild; canaries completed (36/42 salvageable from abandoned); all verify green. |
| Phase 9: Release cadence infrastructure | PENDING | .github/workflows/daily-release.yml cron (2300 SGT = 15:00 UTC). release-cut tool. agency-update self-update logic. |
| Phase 10: Release notes + runbook + manifest lock | PENDING | Release-D46-R1-20260420.md — release notes + adopter migration runbook v45→v46.1. |
| Phase 11: PR creation | PENDING | pr-create → PR → principal review. |
| Phase 12: Merge + release v46.1 + agency-v3 tag | PENDING | pr-merge, release-cut D46.R1, tag agency-v3 at same commit. |
| Phase 13: andrew-demo cleanup | PENDING | Subagent-delegable. agency update --migrate in andrew-demo repo. |

## Key decisions captured today

Full record: `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`. Highlights:

- **Build boundary:** `src/` (sources) → `src/tools/build` (Python 3.13+ stdlib) → `agency/` + `.claude/` (dual-tracked output)
- **`src/` layout:** destination-encoded. `src/claude/*` → `.claude/*`; `src/agency/*` → `agency/*`. Everything else in `src/` is dev-only.
- **Versioning:** per-artifact D.R in YAML frontmatter (authoritative); `agency/config/manifest.json` as derived index.
- **Release cadence:** daily cron at 2300 SGT (15:00 UTC). Empty days skip. Override A (manual mid-day cut via normal flow) + B (skip via `agency/workstreams/the-agency/releases/Release-Skip-{YYYYMMDD}.md` file).
- **Release history dir:** `agency/workstreams/the-agency/releases/` holds per-event files (`Release-D{N}-R{n}-{YYYYMMDD}.md` for shipped, `Release-Skip-{YYYYMMDD}.md` for skipped).
- **Distribution:** "rails init" model. `agency` tool single entry point. Default source = GitHub release tag; `--source` flag overrides to local clone.
- **No tarballs.** Repo content at release tag IS the distribution.
- **Decoupled PRs from releases.** PRs merge on QG pass; releases are a separate cadence.
- **RGR = Review Gate Receipt** (seed/PVR/A&D/plan document reviews). **QGR = Quality Gate Receipt** (iteration/phase/plan-execution/pr-prep implementation gates).
- **KNOWLEDGE.md retired** — subsumed into REFERENCE docs.
- **Seed = single document** (Model A); supporting material in workstream `research/`.

## Salvage strategy (from abandoned v46.0-structural-reset branch)

Only identity fix (agent-identity + block-raw-tools.sh) salvaged in commit `4c7d00e6`. Additional salvage pending:

| To salvage | Source | Location |
|---|---|---|
| 36 hookify `.canary` fixtures | abandoned @ commit `0cb4fc73`, paths `agency/hookify/*.canary` | Extract via `git show abandoned/...:path` |
| Phase 0 reset tools | abandoned @ commits `0401f768`, `a4808493`, `044823f8` | `agency/tools/{git-rename-tree, agency-sweep, ref-inventory-gen, gate-check, subagent-*, audit-log-*, reset-rollback, etc.}` |
| Test-scoper src/archive/** exclude | abandoned @ commit `0cb4fc73` | `agency/tools/test-scoper` |
| commit-precheck + handoff + icloud-setup path fixes | abandoned @ commit `1880c40e` partial | Respective files |
| pr-create receipt-search v46 path | abandoned @ `c554bb3b` | `agency/tools/pr-create` |

Use `git show abandoned/v46.0-overnight-shortcut-20260420:{path}` to extract each file content, write to current branch, commit. Don't cherry-pick commits directly — path differences cause conflicts.

## Phase -1 audit subagent

Background subagent launched for latent-tool-reference audit (task #33). Agent ID `af49156573260f89a`. Report expected at `/tmp/phase-minus-1-audit-report.md`. Will list latent tool-reference bugs (whoami class) with severity + fix options per each.

## Next session resume steps

1. `/session-resume` — sync, handoff read, dispatches check
2. Read this handoff + plan v5 at `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`
3. Read today's transcript at `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
4. Check for Phase -1 audit subagent report (at `/tmp/phase-minus-1-audit-report.md` or via notification)
5. **Decide execution chunk size** — plan v5 has 11 remaining phases; likely needs multiple sessions
6. **Next execution chunk (suggested):**
   - Phase 2 remainder: 2a establish src/ tree, 2b-f starter-packs/archives/agents/templates/designex, 2k apps→src/apps/
   - Salvage from abandoned: Phase 0 reset tools (needed for Phase 7 sweep), canaries (for Phase 8), test-scoper + commit-precheck + handoff + icloud-setup fixes
   - Phase 3: cruft removal (docs→the-agency-group, integrations→src, etc.)
7. Continuing executions: Phase 3.5/3.6 → Phase 4 (src/ split) → Phase 5 (build tool) → Phase 6 (first build) → Phase 7 (sweep) → Phase 8 (verify) → Phase 9 (release infra) → Phase 10 (release notes) → Phase 11 (PR) → Phase 12 (merge + v46.1 + agency-v3) → Phase 13 (andrew-demo)

## Pending ISCP items

- **Task #19** (pending) — Ship designex Phase 1.5 monofolk relay — SEPARATE from this reset; blocked on collab-monofolk wedge resolution.
- **Task #48** (pending) — andrew-demo cleanup — Phase 13 of this plan.
- **Issue #349** — t-shirt sizing / complexity / subagent-suitability skill (follow-up).
- **Issue #350** — canary coverage gap (6 un-synthesizable rules).

## What's working (captain can verify)

- `./agency/tools/agent-identity` → `the-agency/jordan/captain` ✓
- `./agency/tools/git-captain --help` → accessible ✓
- `./agency/tools/git-captain push origin agency-v3-reset` → pushes cleanly ✓
- Post-rename tree structure correct ✓
- PVR §7 Success Criteria #2 + #3 satisfied (REFERENCE/ + README/ subdirs) ✓

## What's broken / known gaps

- Hooks are DISABLED (empty settings.json hooks arrays) — by design for Phase 1-4.5 window. Will be restored at Phase 4.5 or equivalent with agency/ paths.
- `agency-whoami` still missing (latent bug, Phase -1 audit confirming scope)
- Sweep misses throughout tools (Phase 7 covers)
- No build tool yet (Phase 5)
- No release infrastructure yet (Phase 9)
- andrew-demo hasn't been touched yet (Phase 13)

## Handoff quality

This handoff is the authoritative continuation point. Plan v5 is the authoritative plan. Today's transcript is the authoritative decision record. Next session should be able to pick up Phase 2 remainder / salvage / Phase 3 with full context from these three documents.

— captain, 2026-04-20 session-end
