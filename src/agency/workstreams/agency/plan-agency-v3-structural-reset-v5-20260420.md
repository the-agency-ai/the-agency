> **Captured to repo 2026-04-22** from `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` (user-local plan-mode output). Plan artifacts belong in-repo under the relevant workstream; the user-local path was ephemeral.
>
> **Execution status (2026-04-22):** This plan was authored 2026-04-20 and targeted `D46.R1` as the first agency-v3 release. In practice, phases landed incrementally through v46.1–v46.21 on main rather than a single agency-v3 PR:
> - **v46.15** — shipped `great-rename-migrate` tool (unblocks fleet worktree integration)
> - **v46.19** — Phase 4 src/ split (910 files, `src/agency/` + `src/claude/` = source-of-truth; `agency/` + `.claude/` = build products) + Phase 5a Python build tool + 18 BATS
> - **v46.20** — README restructure (Quick Start / What you Get / Staying Up to Date / This Repo Structure)
> - **v46.21** — README stay-current framing + joint copyright (Jordan Dea-Mattson and TheAgencyGroup) + trademark footer across 8 LICENSE files
>
> **Not-yet-landed per this plan:** `agency-v3` symbolic tag; adopter-migration runbook; daily-release cron (replaced in practice by `auto-release.yml` PR-triggered releases + Fix B/D around C#372); Phase 5b (YAML frontmatter + schema-aware versioning); several reference sweeps.
>
> Plan preserved verbatim below for historical reference. Future plans live in-repo from the start.

---

# AgencyV3 — Structural Reset + Build Boundary + Installer

**Plan version:** v5 (supersedes plan v4 at `agency/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md` + draft v5 at `plan-the-agency-structural-reset-v5-20260420.md`)

**Release target:** **D46.R1** (today 2026-04-20 = Day 46; first release of the day). Plus a symbolic tag **`agency-v3`** marking arrival of true installer.

**Project name:** AgencyV3. (V1 = the-agency-starter; V2 = what we've been working on through v45.x; V3 = this.)

## Context

Plan v4's overnight execution on the `v46.0-structural-reset` branch was a captain-solo shortcut, not a plan execution. Phase 4 ran as combined-manifest captain-solo instead of 5-subagent parallel (the specified shape), which cascaded into missed subdir reorganization, unresolved PVR §9 open questions, and over-aggressive meta-file damage. Branch is 54 commits behind origin/main with massive conflict surface. That branch is being abandoned.

Today's extensive 1B1 session surfaced the real north star: **"a structure to the repo that allows us to make a true installer and updater for `agency init` and `agency update`. No more `git clone` shallow."** Plan v5 incorporates today's structural decisions and re-specifies the reset as the path to AgencyV3.

Full decision record: `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md` — this plan references that transcript rather than re-justifying each decision.

## Target end state

### Customer install (`my-agency-repo/`)

```
my-agency-repo/
├── .agency/                      # install-state metadata (migrate-prep markers, install records)
├── .agency-setup-complete        # init-completion sentinel
├── .claude/                      # built Claude Code artifacts
│   ├── agents/{FIRST_PRINCIPAL}/captain.md
│   ├── commands/
│   ├── hooks/
│   ├── settings.json
│   ├── skills/
│   └── subagents/
├── CLAUDE.md                     # bootloader
├── agency/                       # built framework install
│   ├── CLAUDE-THEAGENCY.md
│   ├── LICENSE.md                # MIT (moved into agency/, not at customer root)
│   ├── README-GETTINGSTARTED.md
│   ├── README-THEAGENCY.md
│   ├── README/                   # {ENFORCEMENT, RECEIPT-INFRASTRUCTURE, SAFE-TOOLS}
│   ├── REFERENCE/                # ~32 customer-facing REFERENCE docs
│   ├── agents/                   # 10 canonical classes
│   ├── config/                   # templates + runtime state (absorbs current data/)
│   ├── hooks/                    # framework hooks (.sh)
│   ├── hookify/                  # rule .md (canaries stay in framework repo)
│   ├── templates/                # scaffold templates
│   ├── tools/                    # customer-runtime tools only
│   └── workstreams/
│       └── my-agency-repo/       # default repo-level workstream
└── usr/
    └── {FIRST_PRINCIPAL}/
        └── captain/              # only; nothing more at init
```

### Framework-dev repo (`the-agency/`)

Same shape PLUS source + dev artifacts:

```
the-agency/
├── .agency/ .agency-setup-complete
├── .claude/                      # dual-tracked build output
├── agency/                       # dual-tracked build output
├── src/                          # framework-dev sources
│   ├── claude/                   # → builds to .claude/
│   │   ├── commands/ hooks/ skills/ subagents/
│   ├── agency/                   # → builds to agency/
│   │   ├── CLAUDE-THEAGENCY.md LICENSE.md README-*.md README/ REFERENCE/
│   │   ├── agents/ config/ hooks/ hookify/ templates/ tools/
│   ├── apps/                     # {mdpal, mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark}
│   ├── archive/                  # retired code (9 non-class agents, dead tests, old tools)
│   ├── assets/                   # framework brand (not shipped)
│   ├── integrations/             # claude-desktop (not shipped)
│   ├── REFERENCE/                # framework-dev REFERENCE docs (not shipped)
│   ├── tests/                    # fixtures/ + hookify/ + schemas/ + skills/ + tools/
│   └── tools/                    # framework-dev-only tools (agency-sweep, git-rename-tree, etc.)
├── CLAUDE.md CODE_OF_CONDUCT.md CONTRIBUTING.md LICENSE README.md CHANGELOG.md
├── package.json .gitignore .github/
└── usr/
    └── jordan/                   # all principal's agent sandboxes
        ├── captain/ devex/ designex/ iscp/ mdpal-app/ mdpal-cli/
        ├── mdslidepal-mac/ mdslidepal-web/ mock-and-mark/
```

### Build + distribution

- **Build tool:** Python 3.13+ stdlib at `src/tools/build`. Reads `src/claude/` + `src/agency/` + per-file YAML frontmatter. Produces `.claude/` + `agency/` + regenerates `agency/config/manifest.json`. Dual-tracked (output committed).
- **Versioning:** per-artifact D.R in YAML frontmatter; manifest is derived index. Build detects source changes (checksum) and bumps to current D.R automatically.
- **Release cadence:** daily cron at 2300 SGT (15:00 UTC). Empty days skip. Override supported: manual mid-day cut (normal release flow, triggered earlier) + scheduled-skip via `agency/workstreams/the-agency/releases/Release-Skip-{YYYYMMDD}.md` file.
- **Distribution:** "rails init" model. `agency` tool (single binary, installed via `curl | bash`) fetches from the-agency repo at the release tag (GitHub default; `--source` flag overrides to local clone for contributors). `agency init` = first-time scaffold; `agency update` = self-updates tool + pulls delta from manifest. No packaged tarballs.

## Salvage from abandoned v46.0-structural-reset branch

**Tag for history:** `abandoned/v46.0-overnight-shortcut-20260420` on the current branch head.

**Cherry-pick onto new branch:**

| Commit | Content |
|--------|---------|
| `5f6f5cf2` | agent-identity main-checkout detection + `block-raw-tools.sh --agent` flag fix (flag #194) |
| `0cb4fc73` | 36 hookify `.canary` fixtures (subagent-generated) + `test-scoper` src/archive/** exclude |
| `0401f768`, `a4808493`, `044823f8` | Phase 0 reset tools: `git-rename-tree`, `agency-sweep`, `ref-inventory-gen`, `gate-check`, `subagent-*-check`, allowlist, etc. (useful for re-executing per proper 5-subagent approach) |
| `1880c40e` (partial) | `commit-precheck` framework-file regex + `handoff` impl-file regex + `icloud-setup` agent-dir check (take these three; drop the verification-tool "repairs" which will be redone) |
| pr-create receipt-search v46 path fix (from `5f6f5cf2`'s file scope) | extend pr-create to search `agency/workstreams/*/qgr/` |

**Do NOT cherry-pick:** Phase 1-4.5 rename commits (replaced by a clean re-execution per plan v5), release-notes + runbook + manifest-bump commits (will be rewritten at Phase 10), synthetic QGR (79c1f1a6 — invalid for new execution).

## Phase plan

### Phase -1: Pre-reset inventory + open-question 1B1s

**Before any execution.** Principal + captain 1B1 on residual open questions. Most settled today; listing residuals:

- `integrations/claude-desktop/` purpose + fate (settled: → `src/integrations/`)
- `tools/{service-add.ts, ui-add.ts, lib/}` at current repo root — these are monofolk ports; destination in `src/apps/{app}/` TBD (1B1 required)
- `usr/test/` fixture — move to `src/tests/fixtures/` or delete? (1B1)
- `agency/data/{bug.db, bugs.db}` if still present — delete or archive? (1B1 — principal's Open Q #6)
- `agency/logs/reviews/` — delete + .gitignore (settled today but verify)
- `agency/receipts/` — move to `agency/workstreams/the-agency/rgr/` (settled today)

Plus **latent-tool-reference audit**: grep tree for `./agency/tools/X` where `X` doesn't exist (catches the whoami-class bug — `agency-whoami` deleted in `bdeb09b6` but still referenced by `session-backup`, `restore`, `project-create`, `_agency-init`, `context-save`, `context-review`, `config`, `commit-prefix`, `bug-report`, `agent-create`). Produce fix-plan or carve-out per reference.

**Gate -1 exit:** all open questions resolved in writing at `research/open-questions-resolutions-20260420.md`. Latent-tool-reference audit report committed. Principal final approval on plan v5 before Phase 0.

### Phase 0: Branch prep + tool cherry-pick + baseline

1. Tag `abandoned/v46.0-overnight-shortcut-20260420` on current branch.
2. Captain cuts fresh branch from current `origin/main` HEAD: `agency-v3-reset` (reflects project name, not version).
3. Cherry-pick salvage commits per table above (in order).
4. Resolve any conflicts from cherry-pick against new base.
5. Run cherry-picked Phase 0 reset tools against current tree (`ref-inventory-gen --pre`, baseline snapshot, audit log init).
6. **Subagent-delegable:** `tests/` consolidation — move `test/test-agency-project/` → `src/tests/fixtures/test-agency-project/`, move `tests/{hookify, schemas, skills, tools}/` → `src/tests/{same}/`, update `test-scoper` TESTS_DIR, update `commit-precheck` BATS paths, update `package.json`/vitest config, verify BATS suite + vitest green.
7. **Subagent-delegable:** latent-tool-reference audit (grep all `./agency/tools/X` references, classify exist/missing, produce report).

**Gate 0 exit:** fresh branch off origin/main; salvage applied; baseline audit report.

### Phase 1: Great Rename `claude/` → `agency/`

Per plan v4 Phase 1 spec. Atomic `git mv claude agency` with history preservation. Single commit.

Before: disable hooks via `.claude/settings.json` empty-hooks overlay (per plan v4 §principle 10 + today's learning from v46.0 execution). Restore in Phase 4.5.

**Note:** current origin/main may already have some claude/ → agency/ migration via the 54-commit advance (monofolk v2-package, mdpal-cli Phase 3, etc. — confirm at cherry-pick time). If yes, this phase is shorter; if no, full rename.

**Gate 1 exit:** `agency/` present, `claude/` absent at root (except `.claude/` which is Claude Code dir). BATS green on new paths.

### Phase 2: Subdir reorg within agency/ (including REFERENCE/ + README/ subdirs)

Per plan v4 Phase 2 (sub-phases 2a-2f) + today's additions:

- 2a. Establish `src/` tree (if not already there from salvage)
- 2b. Starter-packs → `src/spec-provider/starter-packs/`
- 2c. Dead artifacts → `src/archive/`
- 2d. 9 non-class agents → `src/archive/agents/`
- 2e. Templates move (`agency/agents/templates/` → `agency/templates/`)
- 2f. designex → design-lead refactor
- **2g. REFERENCE/ subdir:** `mkdir agency/REFERENCE`, `git mv agency/REFERENCE-*.md agency/REFERENCE/` for the ~32 customer-facing REFERENCE docs
- **2h. README/ subdir:** `mkdir agency/README`, move {ENFORCEMENT, RECEIPT-INFRASTRUCTURE, SAFE-TOOLS} into it; GETTINGSTARTED + THEAGENCY stay at agency/ root
- **2i. data/ → config/:** move `agency/data/{issue-monitor.last, tool-build-number}` to `agency/config/`; remove empty `data/`
- **2j. LICENSE.md move:** copy repo-root `LICENSE` to `agency/LICENSE.md` (keep at repo root too for framework-dev)
- **2k. `apps/` → `src/apps/`:** git-rename-tree each app
- **2l. Receipts move:** `agency/receipts/` (legacy RGRs) → `agency/workstreams/the-agency/rgr/`

**Gate 2 exit:** PVR §7 criteria #2, #3, #8 satisfied. `ls agency/` shows only the target shape. No flat REFERENCE-* or stranded dirs.

### Phase 3: Archive + cruft removal (per Phase -1 1B1 resolutions)

Execute resolutions from Phase -1:

- `agency/docs/` → the-agency-group cross-repo (via collab push)
- `agency/integrations/claude-desktop/` → `src/integrations/claude-desktop/`
- `agency/assets/` → `src/assets/`
- `agency/logs/reviews/` → DELETE + `.gitignore`
- Latent-tool-reference fixes — restore `agency-whoami` as stub wrapping `lib/_agency-whoami` (or update 10 callers to source the lib directly — pick per principal)
- `usr/test/` → `src/tests/fixtures/test-user/` (if kept) or DELETE
- `tools/{service-add.ts, ui-add.ts, lib/}` at repo root → `src/apps/{app}/` per 1B1

**Gate 3 exit:** PVR §4.3 cruft removal complete. All 13 Phase -1 open questions resolved to land state.

### Phase 3.5/3.6: Workstream consolidation

Per plan v4. Consolidate duplicate workstream dirs (`captain/`, `housekeeping/`, `agency/`) into `the-agency/` workstream. Retire `KNOWLEDGE.md` from all workstreams per today's decision.

**Gate 3.5 exit:** single `the-agency/` workstream; legacy workstreams flotsam'd.

### Phase 4: src/ source reorganization

With the build boundary decision, content in `agency/` and `.claude/` needs a source at `src/agency/` and `src/claude/`. Two approaches:

- **4a (preferred):** `git mv agency/ src/agency/` and `git mv .claude/{shippable-subset} src/claude/`. Then build regenerates `agency/` + `.claude/` from `src/`. This makes src/ the single source of truth from this phase forward.
- **4b (alternative):** keep agency/ + .claude/ as both source AND build output until build tool lands, then split later. Postpones the hard cut.

**Recommend 4a.** Clean break. Build tool (Phase 5) then regenerates agency/ + .claude/ identically (validated by checksum).

**Gate 4 exit:** `src/agency/` and `src/claude/` contain source-of-truth; `agency/` and `.claude/` regenerated from them via build tool (Phase 5).

### Phase 5: Build tool (Python)

Build `src/tools/build` — Python 3.13+ stdlib only. Responsibilities:

1. Read each source file under `src/claude/` and `src/agency/`
2. Parse YAML frontmatter (minimal regex parser for version field)
3. Compute checksum of source content
4. Compare to prior-release checksum in `agency/config/manifest.json.prev` (or previous manifest)
5. If changed → bump version frontmatter to current D.R; record version_history entry
6. Write/copy source file to target: `src/claude/X → .claude/X`, `src/agency/X → agency/X`
7. Regenerate `agency/config/manifest.json` as flat index (component path → version)
8. Emit build report: changed artifacts, new versions, skipped (unchanged) artifacts

BATS coverage for build tool. `src/tests/tools/build.bats`.

**Gate 5 exit:** `src/tools/build` produces agency/ + .claude/ identical (modulo version stamps) to what was in place pre-Phase-4. Checksum-verified.

### Phase 6: First build + commit dual-tracked output

Run `src/tools/build`. First build stamps ALL artifacts to D46.R1 (initial release under new scheme). Commit build output. Dual-tracked repo now has src/ (sources) + agency/ + .claude/ (build output).

**Gate 6 exit:** manifest.json reflects all artifacts at D46.R1; agency/ + .claude/ regenerated; commit includes both src/ changes and build output.

### Phase 7: Reference sweep — 5 subagents (per plan v4 §Phase 4 proper)

Now sources are in src/, we can run the reference sweep properly:

- Subagent A: tools (src/agency/tools/**, tests/tools/**)
- Subagent B: framework docs (src/agency/REFERENCE/, src/agency/README/, src/agency/CLAUDE-THEAGENCY.md)
- Subagent C: skills + commands + subagents (src/claude/**)
- Subagent D: agents (src/agency/agents/**, .claude/agents/**)
- Subagent E: hooks + hookify + config + package.json + .gitignore (src/agency/{hooks, hookify, config}/, src/claude/hooks/)

Each subagent in dedicated worktree (`.reset-wt/subagent-{A..E}`) with scoped manifest (existing manifests from abandoned branch). Returns structured patch. Captain applies serially, verifies scope.

**Gate 7 exit:** `ref-inventory-gen --post --strict` returns zero unknown paths. `import-link-check` clean.

### Phase 8: Rebuild + hookify canary fill + verification

1. Rebuild via `src/tools/build` (picks up sweep changes)
2. Ensure hookify canaries complete (already have 36/42 from salvage; address remaining 6 per issue #350)
3. Run `agency/tools/agency-verify-v46 --customer` — expect exit 0
4. Run `agency/tools/agency-health-v46` — expect clean
5. Run `bats src/tests/` — full suite green
6. Run `commit-precheck --dry-run` — clean

**Gate 8 exit:** all verification green.

### Phase 9: Release cadence infrastructure

1. GitHub Actions workflow: `.github/workflows/daily-release.yml` — cron `0 15 * * *`
2. Release script: `src/tools/release-cut` — reads skip file check, runs build, tags, `gh release create`, writes Release-Dxx-Rx-YYYYMMDD.md
3. `agency-update` self-update logic (manifest-driven, per today's decision)
4. `agency/tools/agency` (the installed tool) knows: `--source` default GitHub, override to local clone

**Gate 9 exit:** cron workflow committed; release-cut tool tested against a dry-run tag; self-update pattern validated.

### Phase 10: Release notes + migration runbook + manifest

1. Write `agency/workstreams/the-agency/releases/Release-D46-R1-20260420.md` — release notes, PR list, migration guide
2. Update `agency/config/manifest.json` final — all artifacts at D46.R1
3. Write adopter migration runbook into the release file — how to move from v45.x (AgencyV2) to D46.R1 (AgencyV3)

**Gate 10 exit:** Release-D46-R1-20260420.md complete; manifest locked.

### Phase 11: PR creation + principal approval

1. Captain pushes `agency-v3-reset` branch
2. `pr-create` from branch → `agency-v3-reset` → `main`
3. Principal reviews PR
4. Resolve any review findings (MAR? QGR at plan-complete? Per plan v4 principle 7)

**Gate 11 exit:** PR approved.

### Phase 12: Merge + release v46.1 + tag agency-v3

1. `pr-merge` — real merge commit (never squash, never rebase, per framework discipline)
2. `git-captain sync-main` to update local main
3. Run release-cut manually for D46.R1 (first release under new scheme)
4. Add symbolic tag `agency-v3` at the same commit — marking arrival of true installer
5. `gh release create v46.1` + `gh release create agency-v3` (or one release with both tags)

**Gate 12 exit:** v46.1 released on GitHub; agency-v3 tag visible; first build output live on main.

### Phase 13: andrew-demo cleanup (adopter sync)

**Subagent-delegable.** Clean up andrew-demo adopter repo:

1. Pull latest `agency-v3` / v46.1
2. Run `agency update --migrate` to apply v45 → v46 migration
3. Verify `agency verify` exits 0
4. Resolve any per-adopter customization conflicts
5. Commit + push
6. Report state

**Gate 13 exit:** andrew-demo on v46.1 (AgencyV3); clean verify; dispatches to fleet notifying the release.

## Subagent delegation points

| Work | Subagent | Suitability |
|------|----------|-------------|
| Phase 0: `tests/` consolidation | general-purpose | S, Easy, yes |
| Phase 0: latent-tool-reference audit | general-purpose | S, Easy, yes |
| Phase 2: mechanical file moves (REFERENCE, README, apps, data) | general-purpose per scope | S, Easy, yes |
| Phase 5: build tool BATS tests | general-purpose | M, Moderate, yes |
| Phase 7: 5 subagents (A-E) for reference sweep | general-purpose × 5 (parallel, worktree-isolated) | Core plan structure — mandatory |
| Phase 8: fill remaining 6 hookify canaries | general-purpose | S, Easy, yes |
| Phase 10: release notes draft | general-purpose | S, Easy, yes |
| Phase 13: andrew-demo cleanup | general-purpose | M, Moderate, yes |

## MAR and approval

- **Before Phase 0 execution:** principal 1B1 on residual open questions (Phase -1), plan v5 final approval
- **At each Gate exit:** MAR checkpoint per plan v4 principle 7 (3 reviewers)
- **At Phase 11:** PR review with principal

## Verification

- `agency/tools/agency-verify-v46 --customer` → exit 0
- `agency/tools/agency-health-v46` → no broken state
- `hookify-rule-canary --all agency/hookify/` → 42/42 passing (or documented 36/42 gap)
- `bats src/tests/tools/` → full pass
- `bats src/tests/skills/` → full pass
- `vitest run` → full pass
- `src/tools/build` → deterministic rebuild (run twice, checksums match)
- `agency init` in fresh empty repo → produces Tree 1 shape
- `agency update` from a v45-scaffolded repo → migrates to v46 cleanly
- `curl | bash` one-liner install on clean machine → produces working `agency` tool
- andrew-demo on v46.1 → `agency verify` exits 0

## Critical files

- This plan (captured 2026-04-22): `agency/workstreams/agency/plan-agency-v3-structural-reset-v5-20260420.md` (source: `src/agency/workstreams/agency/plan-agency-v3-structural-reset-v5-20260420.md`)
- Original user-local authoring path: `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` (retained as historical artifact)
- Live transcript of today's 1B1: `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
- Plan v4 (reference for retained principles): `agency/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md`
- Plan v5 draft (earlier today, this plan supersedes): `agency/workstreams/the-agency/plan-the-agency-structural-reset-v5-20260420.md`
- Salvage source (abandoned branch): `v46.0-structural-reset` → to be tagged `abandoned/v46.0-overnight-shortcut-20260420`
