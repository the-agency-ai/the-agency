---
type: ad
workstream: the-agency
slug: structural-reset
principal: jordan
agent: the-agency/jordan/captain
date_started: 2026-04-19
stage: design
status: in-progress
next_stage: plan
pvr: agency/workstreams/the-agency/pvr-the-agency-structural-reset-20260419.md
pvr_mar: agency/workstreams/the-agency/research/mar-pvr-structural-reset-20260419.md
related_issues: [270, 287, 332, 333, 334, 335, 336, 337]
---

# A&D — The-Agency Structural Reset (v46.0)

Design for the `claude/` → `agency/` structural reset. Incorporates all MAR findings from the PVR review. Captures architecture, migration strategy, validation gates, and rollback mechanics.

## 0. Architecture decisions (from MAR)

### 0.1. `agency/` is the installed tree; `src/` is the future source tree

Per MAR A2: this reset moves the framework's tree from `claude/` to `agency/`. `agency/` post-reset is the **installed** tree — the thing adopters see, the thing Claude Code reads, the thing hookify/settings.json references. The **source** tree (`src/`) is deferred to #337 (installer Valueflow pass).

Post-v46.0, mental model:
- **`agency/`** (this reset target) = installed framework (adopter-facing + framework-operational)
- **`src/`** (#337) = canonical source that installs INTO `agency/` + `.claude/`

Rename-move does not create `src/`. This reset is PURE rename + reorg + cruft + sweep.

### 0.2. `.claude/` vs `agency/` ownership boundary

Per MAR A3: explicit principle captured:

> **`.claude/`** = Anthropic-owned discovery surface. Claude Code reads hooks + skills + agents + commands from here.
> **`agency/`** = framework-owned source-of-record. Contains framework tools, hook scripts, reference docs, templates, workstreams.
> **Cross-refs flow `.claude/` → `agency/`, never the reverse.**

`.claude/settings.json` points at `agency/hooks/*.sh`. `.claude/skills/*/SKILL.md` has `required_reading:` that references `agency/REFERENCE/*.md`. Never the other way.

### 0.3. `agency/config/` preserved

Per MAR A1: `agency/config/` (currently `agency/config/`) stays intact — holds `agency.yaml`, `manifest.json`, `settings-template.json`. Reserves future home for `install-manifest.yaml` (#337). No restructure in this reset.

### 0.4. Atomic single-PR delivery

Per MAR R9: the reset ships as **one PR, one merge, one release**. If it can't fit one PR, we abort and redesign. No intermediate-merge pattern. Rollback remains sane only if the commit boundary is atomic.

### 0.5. Rename-first, sweep-second ordering

Per MAR R10: git rename detection degrades if we move + content-edit in the same commit. Execution order is strict:
1. Pure rename commits (no content edit — just `git mv`)
2. Reference sweep commits (content edits only — no moves)
3. `git log --follow` on 5 canary files validates history preservation before merge

### 0.6. CLAUDE.md @import rewrite is the LAST step

Per MAR R6: CLAUDE.md @imports update only after all moves + all internal-content sweeps complete. Before that step, no parallel subagents may be spawned — if a subagent's session starts mid-reset, it hits broken import resolution.

Ordering: moves → content sweeps (in modules) → `.claude/settings.json` rewrite → CLAUDE.md + CLAUDE-*.md @import rewrite (dead last).

## 1. Branch strategy + merge order

**Decision (captain, per MAR P8 autonomous call):**

- **New branch:** `v46.0-structural-reset` cut from `contrib/claude-tools-worktree-sync` HEAD
- **Merge order:** PR #294 merges first (already prepped, review-ready). When #294 lands on master, the reset branch rebases onto master and opens as a new PR.
- **Rationale:** PR #294 is already substantial scope (helper refactor + retrofits + andrew-demo work). Adding the structural reset to #294 makes the mega-PR unreviewable. Separate PRs give cleaner review, cleaner rollback, cleaner release notes.
- **Alternative (if principal overrides):** monolithic PR #294 with reset appended. Documented but not captain-preferred.

## 2. Execution phases

The reset is partitioned into 5 phases. Each phase has a **gate artifact** (receipt) that must produce zero-error before the next phase starts.

### Phase 0 — Pre-reset baseline capture (~5 min)

Per MAR V5: freeze the pre-reset state before ANY move.

Deliverables → `usr/jordan/captain/reset-baseline-20260419/`:
- `agency-health.json` — full fleet health JSON snapshot
- `bats-output.txt` — `bats tests/` run output
- `file-inventory.txt` — `find claude -type f | sort > file-inventory.txt`
- `file-inventory.sha256sum` — sha256 over file-inventory.txt
- `ref-inventory-pre.txt` — scripted scan of all `claude/` path references (see 5.1)
- `git-log-head.txt` — `git log --oneline -5 HEAD`
- `git-tag-v45.3-pre-reset` — git tag for rollback

**Gate:** all 7 artifacts exist + principal approval that baseline is captured.

### Phase 1 — Great Rename tree move (~3 min)

Per §0.5: pure rename, no content edits.

```
AGENCY_ALLOW_RAW=1 git mv claude agency
```

**Commit 1:** "feat(v46.0): Great Rename — claude/ → agency/ (pure move, no content edits)"

**Gate 1 (MAR A4 / V6 alignment):**
- `git log --follow agency/tools/git-safe` resolves history back through `agency/tools/git-safe` (5 canary files validated)
- `git status --porcelain` clean
- `ls agency/` shows expected tree

### Phase 2 — Subdir reorganization (~5 min)

Per MAR A1: `config/` preserved. Per PVR §4.2: docs reorg.

```
mkdir -p agency/REFERENCE agency/README
# move 36 REFERENCE-*.md
AGENCY_ALLOW_RAW=1 git mv agency/REFERENCE-*.md agency/REFERENCE/
# move 3 non-top README-*.md (KEEPS README-THEAGENCY + README-GETTINGSTARTED at agency/ root)
AGENCY_ALLOW_RAW=1 git mv agency/README-ENFORCEMENT.md agency/README/
AGENCY_ALLOW_RAW=1 git mv agency/README-SAFE-TOOLS.md agency/README/
AGENCY_ALLOW_RAW=1 git mv agency/README-RECEIPT-INFRASTRUCTURE.md agency/README/
```

**Commit 2:** "feat(v46.0): subdir reorg — REFERENCE/ + README/ for navigability"

**Gate 2:**
- `ls agency/REFERENCE/ | wc -l` == 36
- `ls agency/README/ | wc -l` == 3
- `ls agency/*.md` shows only `README-THEAGENCY.md`, `README-GETTINGSTARTED.md`, `CLAUDE-THEAGENCY.md`
- `git log --follow agency/REFERENCE/REFERENCE-AGENT-DISCIPLINE.md` resolves back through `agency/REFERENCE-AGENT-DISCIPLINE.md`

### Phase 3 — Cruft removal + archive-to-flotsam (~10 min)

Per MAR R2: **Archive-before-delete binding rule.** Per MAR R1: extract bug DB contents before removal.

**Delete** (after validation each item is truly dead):
- `agency/workstreams/test; rm -rf ` — injection test, 1 file. Delete directly.
- `agency/reviews/` — single REVIEW-captain-2026-03-28.md. Captain 1B1 with self: determined dead (one-off, superseded by per-workstream qgr/rgr). **Archive** to `agency/workstreams/the-agency/history/flotsam/legacy-reviews-20260419/`.
- `agency/data/bug.db`, `agency/data/bugs.db` — legacy from killed `/agency-bug`. Extract `sqlite3 .dump` to `history/flotsam/legacy-bug-dbs-20260419/` first, then delete.
- `agency/docs/` — empty after `docs/plans/` deprecation fix. Delete directory.
- `docs/plans/` (repo root) — delete (deprecated per D42-R3 #335, root-cause fixed in `_agency-init` already).
- `docs/` (repo root) — delete (empty after plans/ removal).

**Archive to flotsam** (preserve legacy content):
- `agency/principals/` — v1 principal system, replaced by `usr/` + `agency.yaml`. Move entire tree to `agency/workstreams/the-agency/history/flotsam/legacy-principals-20260419/`.
- `agency/receipts/` — pre-D42-R3. Receipts migrated to per-workstream `qgr/`+`rgr/`. Remaining 8 RGR files → `agency/workstreams/the-agency/history/flotsam/legacy-receipts-20260419/`.
- `agency/logs/` — audit: content-specific decision in Phase 3.5. Default: archive to flotsam.

**Defer to follow-up** (requires collab repo setup):
- `agency/workstreams/gtm/` → stays in place with `TODO-MOVE-TO-THE-AGENCY-GROUP.md` marker
- `agency/proposals/` → same treatment

**Commit 3:** "feat(v46.0): archive legacy subsystems + delete confirmed-dead cruft"

**Gate 3:**
- None of the deleted paths exist
- `agency/workstreams/the-agency/history/flotsam/legacy-*-20260419/` contains archived content
- `HISTORICAL-PATH-NOTE.md` in archives (see §0.2 + MAR R8)
- `git status` clean

### Phase 3.5 — Duplicate workstream merge (~5 min)

Per MAR A5: content-type-aware triage before merge.

**Source:** `agency/workstreams/{agency,captain,housekeeping}/`

**Triage rules:**
| Content type | Destination |
|---|---|
| Captain personal state (handoffs, session logs) | `usr/jordan/captain/history/flotsam/legacy-captain-workstream-20260419/` |
| Shared workstream artifacts (PVRs, A&Ds, plans, transcripts) | `agency/workstreams/the-agency/history/legacy-{source}-workstream-20260419/` |
| Dead content (e.g., duplicates of current the-agency/ content) | Archive to flotsam |

**Captain workstream `transcripts/dialogue-transcript-20260419.md` preservation:**
- This is THIS SESSION's transcript (captain's design-stage dialogue). Should move to `agency/workstreams/the-agency/transcripts/` as an ACTIVE transcript of the reset itself.

**Commit 4:** "feat(v46.0): consolidate duplicate workstreams into the-agency/"

**Gate 3.5:**
- `agency/workstreams/` contains ONLY: `the-agency/` + per-app workstreams (`mdpal/`, `mdslidepal/`, `mock-and-mark/`, `iscp/`, `devex/`, `designex/`) + deferred `gtm/` marker
- No `agency/`, `captain/`, `housekeeping/` at workstream root

### Phase 4 — Reference sweep (~30 min with parallel subagents)

Per MAR A4 + R3: scripted, per-category, zero-leakage gated.

**5.1. Reference inventory (captain, pre-sweep)**

Generate `ref-inventory-pre.txt`:
```
# Script: agency/tools/ref-inventory-gen (to be written)
# Finds all `claude/` references across active code:
#  - .claude/**/*.{md,json,sh}
#  - agency/tools/**
#  - agency/hooks/**.sh
#  - agency/hookify/**.md
#  - agency/REFERENCE/**.md (internal cross-refs)
#  - CLAUDE.md
#  - tests/**
#  - Excludes: history/**, workstreams/*/transcripts/, workstreams/*/history/, CHANGELOG*.md, release-notes-*.md
```

Store inventory. Diff against post-sweep for zero-leakage verification.

**5.2. Subagent fan-out (parallel — NO CLAUDE.md @import touched yet)**

Per MAR R6, CLAUDE.md rewrites are LAST (Phase 4.5). Subagents handle content sweeps in isolated scopes:

- **Subagent A — Tools sweep:** update hardcoded `claude/` paths in `agency/tools/*` (all 133 tools). Scope: bash scripts + ts tools.
- **Subagent B — Skill frontmatter:** update `required_reading:` paths in `.claude/skills/*/SKILL.md` (all that have required_reading). Also skill body references.
- **Subagent C — Hookify rules + hook scripts:** update `agency/hookify/*.md` references + `agency/hooks/*.sh` internals.
- **Subagent D — Agency docs internal cross-refs:** update REFERENCE-*.md + README-*.md internal cross-references to new `agency/REFERENCE/` + `agency/README/` paths.
- **Subagent E — Tests + starter packs:** update `tests/**` fixtures + `agency/starter-packs/**` internal references.

**Constraint:** subagents operate on DISJOINT file sets; captain verifies scope boundaries before fan-out.

**Commit 5:** "feat(v46.0): reference sweep — all claude/ paths → agency/ across active code (subagent fan-out)"

**Gate 4:**
- `ref-inventory-post.txt` generated
- Diff `ref-inventory-pre.txt` vs post: zero active-code entries (modulo allowlist)
- `bats tests/` passes

### Phase 4.5 — `.claude/settings.json` + CLAUDE.md @imports (~5 min, captain only)

Per MAR R6: this is the LAST step. No subagents beyond this point.

**Files rewritten:**
- `.claude/settings.json` — hook paths: `$CLAUDE_PROJECT_DIR/claude/hooks/X.sh` → `$CLAUDE_PROJECT_DIR/agency/hooks/X.sh`
- `CLAUDE.md` — `@claude/CLAUDE-THEAGENCY.md` → `@agency/CLAUDE-THEAGENCY.md`
- `agency/CLAUDE-THEAGENCY.md` — internal `@agency/REFERENCE-*.md` → `@agency/REFERENCE/REFERENCE-*.md`
- `agency/agents/*/agent.md` — any `@` imports referencing old paths

**Commit 6:** "feat(v46.0): finalize @import resolution — CLAUDE.md + settings.json point at agency/"

**Gate 4.5 (captain smoke battery per MAR V7):**
- `./agency/tools/handoff read` succeeds (→ post-reset: `./agency/tools/handoff read`)
- `./agency/tools/dispatch list` succeeds
- `./agency/tools/flag list` succeeds
- `./agency/tools/agency-health` returns clean
- `./agency/tools/session-resume --dry-run` (if skill supports) OR `bash session-resume hook test`
- Fresh Claude Code session starts, reads CLAUDE.md, `@imports` all resolve (manual smoke)
- Invoke one skill with `required_reading:` — ref-injector resolves new paths

### Phase 5 — Hookify rule validation (~10 min)

Per MAR R4: enumerate + validate each hookify rule fires post-rename.

Per rule in `agency/hookify/*.md` + corresponding `agency/hooks/*.sh`:
- **Static check:** grep the rule doc + script for hardcoded `claude/` paths. Any hits = bug.
- **Dynamic check:** trigger each rule (or a canary for groups) — confirm block/warn fires.

**Commit 7:** "test(v46.0): hookify rule validation — all rules firing post-reset"

**Gate 5:** 40+ hookify rules all validated (static + dynamic).

### Phase 6 — Release notes + migration guide (~10 min)

Per MAR R7 + V8: mandatory migration, monofolk smoke checklist.

**Deliverables:**
- `CHANGELOG-2026-04-19-v46.0.md` — "v46.0: Structural Reset" — human-readable breaking-change release notes
- `agency/REFERENCE/REFERENCE-MIGRATION-V46.md` — step-by-step migration guide for adopters
- `agency/tools/_agency-update --migrate` — flag implementation that rewrites adopter's `.claude/settings.json` + `CLAUDE.md` (optional but recommended)
- Monofolk smoke checklist in release notes:
  1. `agency update` exits 0
  2. `.claude/settings.json` hook paths point at `agency/hooks/` (no ENOENT on hook fire)
  3. `CLAUDE.md` @imports resolve (fresh session starts cleanly)
  4. One dispatch round-trip captain ↔ adopter agent

**Commit 8:** "docs(v46.0): release notes + migration guide for v46.0 structural reset"

**Gate 6:** release notes contain working migration examples for the 3 breaking paths (settings.json, CLAUDE.md, required_reading).

## 3. Data preservation design

### 3.1. Archive-to-flotsam binding rule

Per MAR R2: every deletion is preceded by archive unless principal 1B1 confirms zero-value.

Enforced by:
- Phase 3 checklist (every delete has an explicit "archive this first" or "confirmed-zero-value: [rationale]")
- Commit message for Phase 3 lists every deletion with archive-path
- Post-reset, flotsam content remains greppable + restorable

### 3.2. Legacy database extraction

`bug.db`, `bugs.db`, any active-state SQLite DBs that are removed: `sqlite3 .dump` export to flotsam before delete.

### 3.3. History-preservation validation

`git log --follow` validated on 5 canary files post-Phase-1:
- `agency/tools/git-safe`
- `agency/REFERENCE/REFERENCE-AGENT-DISCIPLINE.md` (from nested subdir)
- `agency/workstreams/the-agency/seeds/seed-true-installer-bootstrap-20260419.md`
- `agency/hooks/block-raw-tools.sh`
- `agency/README/README-ENFORCEMENT.md` (from nested subdir)

If any shows as delete+add (rename not detected), PHASE 1 ABORTS and we redesign the move.

## 4. Hookify bypass discipline (MAR R5)

Per MAR R5: `AGENCY_ALLOW_RAW=1` per-command only. Never session env export. Captain-only. Audit log.

**Audit log path:** `usr/jordan/captain/reset-audit-20260419.log`

Every raw-git invocation documented:
```
TIMESTAMP COMMAND EXIT_CODE RATIONALE
2026-04-19T19:23:14Z git mv claude agency 0 Phase 1 — Great Rename
2026-04-19T19:27:48Z git mv agency/REFERENCE-*.md agency/REFERENCE/ 0 Phase 2 — subdir
...
```

**No subagents use AGENCY_ALLOW_RAW=1.** Raw ops are captain-exclusive.

## 5. Validation + test matrix

### 5.1. Pre-reset baseline artifacts (Phase 0)

See §2 Phase 0 deliverables.

### 5.2. Per-phase gates

See §2 Gate 1-6. Each phase's gate is a GO/NO-GO decision. NO-GO = rollback to baseline.

### 5.3. Captain smoke battery (post-Phase-4.5)

See §2 Gate 4.5 smoke checklist.

### 5.4. Fleet worktree smoke (Phase 7 — post-merge)

Per MAR V12: each of the 9 worktree agents runs a 60-sec post-rebase smoke:
- Rebase onto master (`git-safe merge-from-master --remote`)
- `./agency/tools/git-safe status` + `branch` succeed
- Handoff read succeeds
- Dispatch list succeeds
- `agency-health` for their worktree: no regressions

Dispatch template: `dispatch-template-post-v46-worktree-smoke.md`

### 5.5. Monofolk adopter smoke

Per §2 Phase 6 checklist. Captured in release notes. Principal 1B1 on execution.

### 5.6. Fresh `agency init` validation

Run `agency init --project testproject` on `/tmp/v46-init-test/`:
- Creates `agency/`, `.claude/`, `usr/<principal>/`, `CLAUDE.md` (template-expanded), `.gitignore`
- No `claude/` dir, no `docs/plans/`, no `workstreams/housekeeping/`, no `workstreams/myapp/`
- Repo-level workstream is `agency/workstreams/testproject/` (uses repo basename per #334 fix)
- Fresh session starts cleanly

## 6. Rollback mechanics (MAR A6 + R9)

**Pre-reset tag:** `v45.3-pre-reset` (see Phase 0)

**Rollback triggers:**
- Gate 1 fails (rename detection broken) → hard reset to tag, redesign move
- Gate 2-3 fails → same
- Gate 4 fails (ref sweep leakage) → fix leakage, re-run. If unfixable, rollback.
- Gate 4.5 fails (CLAUDE.md breaks) → fix @imports, retry. If unfixable, rollback.
- Gate 5 fails (hookify rules silently no-op) → fix rules, re-validate. Don't merge without green.
- Gate 6 fails (release notes incomplete) → write release notes, retry. Low-risk.

**Rollback procedure (if triggered mid-flight):**
1. `AGENCY_ALLOW_RAW=1 git reset --hard v45.3-pre-reset`
2. Force-push the-agency branch to discard
3. Notify monofolk: no adopter-side migration needed (nothing merged yet)
4. Debrief; capture lessons; re-plan

**Rollback procedure (if triggered post-merge — WORST CASE):**
1. Revert the merge commit (`git revert -m 1 <merge-sha>`)
2. Tag reverted state
3. Monofolk: `agency update --version v45.3 --migrate-back` (if we have that flag; otherwise manual revert of `.claude/settings.json` + CLAUDE.md)
4. Communicate to monofolk via cross-repo dispatch

Principal approval required for any rollback after merge.

## 7. Content audit (MAR P9 defer from PVR)

Items to audit during Plan stage (captain 1B1 with self):
- `agency/assets/theagency-logo-constellation.svg` — stay at `agency/assets/` or move to `agency/brand/`? Captain call: keep at `assets/` (no brand/ needed for a logo).
- `agency/integrations/claude-desktop/` — what is it? Captain to inspect. If MCP config, keep. If stale, archive.
- `agency/logs/reviews/` — keep or flotsam? Captain: flotsam unless active.
- `agency/schemas/` — keep at `agency/schemas/`. Future #337 may move to `src/schemas/`.
- `agency/starter-packs/` — keep at `agency/starter-packs/`. Future #337 may src-split.
- `agency/templates/` — keep at `agency/templates/`. Future #337 may src-split.

These decisions captured in the Plan, not blocking for A&D transition.

## 8. Release notes skeleton (MAR V4)

```markdown
# v46.0 — Structural Reset

**Breaking change.** The framework directory has moved from `claude/` to `agency/`.

## What changed
- `claude/` → `agency/` (tree rename)
- `agency/REFERENCE/*.md` (all 36 REFERENCE docs, was flat at `claude/`)
- `agency/README/*.md` (3 README files, was flat at `claude/`)
- Various legacy/dead subsystems removed or archived

## What you need to do (adopter)
Run: `agency update --migrate` (mandatory flag for v45.x → v46.0)

Then validate:
1. `.claude/settings.json` points at `agency/hooks/`
2. `CLAUDE.md` @imports resolve
3. `/handoff read` works
4. One dispatch round-trip

## Example migration diffs
[settings.json before/after]
[CLAUDE.md before/after]
[required_reading before/after]

## Rollback
`agency update --version v45.3 --migrate-back`
```

## 9. Open items for Plan

- Exact `agency update --migrate` implementation (write the flag for `_agency-update`)
- Exact `ref-inventory-gen` script (new tool for V9)
- Canary file selection for `git log --follow` validation (5 final files picked in Plan)
- `TODO-MOVE-TO-THE-AGENCY-GROUP.md` content for deferred moves (template in Plan)
- Hookify rule enumeration script (static-check tool for R4)

These surface in the Plan as concrete tasks.

---

## Completeness scorecard

| # | Section | Status |
|---|---|---|
| 0 | Architecture decisions | ✓ Complete (6 decisions captured) |
| 1 | Branch strategy | ✓ Captain-autonomous decision captured |
| 2 | Execution phases | ✓ 7 phases + gates |
| 3 | Data preservation | ✓ Archive rule + extraction + history validation |
| 4 | Hookify bypass discipline | ✓ Per-command + audit log |
| 5 | Validation matrix | ✓ Baseline + gates + smoke |
| 6 | Rollback | ✓ Pre-merge + post-merge procedures |
| 7 | Content audit | ✓ Deferred-to-Plan list |
| 8 | Release notes skeleton | ✓ Captured |
| 9 | Plan-stage open items | ✓ 5 items |

**Score: 10/10 complete.** All MAR findings folded in.

## Transition

Next: `/plan` — produce executable Plan with:
- Phase → Task breakdown (Phase 0 tasks, Phase 1 tasks, etc.)
- Subagent briefs for Phase 4 fan-out (5 briefs, disjoint file sets)
- Canary file list for history validation
- `ref-inventory-gen` script design
- `TODO-MOVE-TO-THE-AGENCY-GROUP.md` template
- Hookify enumeration tool design
- Release notes + migration guide draft
- Captain + monofolk smoke batteries as scripts
- MAR queued before transition.
