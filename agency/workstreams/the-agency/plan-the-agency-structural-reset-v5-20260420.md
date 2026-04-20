---
type: plan
workstream: the-agency
slug: structural-reset
artifact: plan-the-agency-structural-reset-v5-20260420.md
version: 5
supersedes: plan-the-agency-structural-reset-20260419.md (v4)
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-20
pvr: pvr-the-agency-structural-reset-20260419.md
ad: ad-the-agency-structural-reset-20260419.md
mar_triages:
  - (forthcoming) research/mar-plan-v5-structural-reset-20260420.md
driver: "Post-failure rework. Overnight captain-solo execution on v4 violated plan structure; branch abandoned. v5 incorporates execution-failure learnings."
---

# Plan — The Agency Structural Reset (v5) — POST-FAILURE REWORK

## 0. Context

v4 was executed as an **overnight captain-solo shortcut** instead of the specified 5-subagent Phase 4 + per-phase MAR checkpoints + 1B1-resolved open questions. The resulting branch (`v46.0-structural-reset`) is:

- 54 commits behind current `origin/main` (never synced)
- Missing PVR §4.2 subdir reorg (REFERENCE/ + README/ never created)
- Missing PVR §4.3 cruft triage (docs/, receipts/, integrations/, logs/, data/, assets/ unreviewed)
- Missing Open Questions #4, #5, #7, #8, #9 resolution (never 1B1'd)
- Phase 4 over-aggressive sweep damage (meta-files self-rewritten)
- Version format wrong (46.0.0 not D.R)
- Pre-existing latent bugs rode through (`agency-whoami` reference to non-existent tool; misplaced `tools/*.ts`; `usr/test/` fixture; `agency/agents/unknown/backups/` session-end hook artifact)

**Plan v5 supersedes v4.** v4's 13 binding principles are retained (they were sound). v5 adds **5 new principles** addressing the execution-failure modes, adds **Phase -1 (pre-reset inventory + open-question 1B1s)**, tightens Phase 4 discipline, and specifies the **salvage-and-fresh-start strategy**.

## 1. Learnings from v4 execution failure

| # | Learning | v5 response |
|---|----------|-------------|
| L-1 | Autonomous directive ("do it overnight") does NOT authorize skipping plan structure. 5 subagents exist for failure-mode reasons; captain-solo combined-manifest has known over-aggressive behavior. | New Principle 14; explicit ban on captain-solo Phase 4 |
| L-2 | Pre-existing latent bugs ride through rename silently. `agency-whoami` was deleted in `bdeb09b6` but still referenced by `session-backup`. `agency/agents/unknown/backups/` committed on every session-end. | New Principle 15; Phase -1 inventory step |
| L-3 | Branch drift from origin/main is catastrophic with rename-heavy diffs. v4 branch never merged origin/main; 54-commit drift on a 1370-file diff. | New Principle 16; mandatory periodic merge-from-origin with conflict triage |
| L-4 | Open Questions are execution blockers, not "deferred to later." docs/, integrations/, assets/, logs/, reviews/, tools/*.ts, usr/test/, src/ population ALL need 1B1 before their relevant phase. | New Principle 17; Phase -1 1B1 block |
| L-5 | Version format is D.R (the project's actual convention), not semantic. Plan v4 used 46.0 as both project name AND release version — conflated. | New Principle 18; decouple project name from release version |
| L-6 | Per-phase MAR checkpoints are non-optional. v4's MAR checkpoints got compressed to captain-only decisions. | Reinforces Principle 7; MAR is captain-run but 3-reviewer-agent, never captain-only |
| L-7 | `agency/docs/` is deprecated per PVR #91 — 1B1 review + delete/archive was explicit and never happened. | Phase -1 1B1 resolves |
| L-8 | Phase 4 sweep damaged meta-files (verification tools, BATS fixtures, manifests) because combined manifest had no scope discipline. Per-subagent manifests with explicit excludes prevent this. | Hard ban on combined-manifest Phase 4 |
| L-9 | Session-end hook artifacts (`agency/agents/unknown/`) accumulate in tree without gitignore discipline. | `.gitignore` update in Phase -1 |
| L-10 | Plan §8 Non-Goal "`src/` source + install split — installer territory, not this reset" may not reflect principal intent. Needs 1B1. | Phase -1 open question |
| L-11 | Misplaced monofolk ports (`tools/service-add.ts`, `tools/ui-add.ts`, `tools/lib/`) and `usr/test/` fixture need placement decision. | Phase -1 open question |

## 2. v4's 13 Binding Principles — RETAINED VERBATIM

All 13 principles from v4 §2 are retained without modification. They were correct; execution violated them. Summary:

1. Rename is pure move; content sweep is separate commit
2. Archive before delete
3. Atomic per-phase commit; per-phase revertable
4. Fully qualified path substitutions only
5. Static + dynamic reference verification
6. No raw shell globs in rename operations
7. MAR at every phase boundary
8. Every tool has BATS coverage with declared min-test-count before it's invoked
9. In-scope partition rule
10. Phase 4.5 atomicity
11. Hookify-bypass discipline
12. Adopter-artifact isolation + shim resilience
13. Subagent worktree isolation

## 3. NEW Binding Principles (v5 additions)

### Principle 14 — Autonomous execution respects plan structure

"Autonomous overnight" and "no BS stops" are directives about **principal availability**, not about **plan discipline**. Every plan principle, phase gate, and MAR checkpoint applies identically in autonomous and interactive execution. If captain is tempted to shortcut a phase because "principal is asleep," captain instead writes a `/session-compact` handoff and stops. Principal rolls back or resumes.

**Enforcement:** Phase 0d deliverable `reset-autonomy-check.sh` — runs at every phase gate entry; detects captain-solo fan-out attempts in phases declaring subagent-fan-out; blocks with exit-2 + explicit rationale requirement.

### Principle 15 — Pre-existing latent bugs don't ride through

Before any rename begins, a **pre-reset inventory audit** identifies:

- Tool-path references that point at non-existent targets (static analysis: `grep` for `./agency/tools/X` where `X` is not in `git-safe ls-files`)
- Files in suspicious locations (`tools/*.ts` at repo root — monofolk ports; `usr/test/` — misplaced fixture; `agency/agents/unknown/` — session-hook artifact)
- Directories called out in PVR as deprecated-but-never-removed (`agency/docs/`, `agency/receipts/`, `agency/integrations/claude-desktop/`)
- Duplicate or stale workstream directories

Each item triage'd via 1B1 (principal decides: fix-in-this-reset / carve-out-to-follow-up / leave-as-is-with-rationale). No silent ride-through.

### Principle 16 — Origin/main merge discipline

Branch cuts from **current origin/main HEAD**, not historical. Every phase gate pass includes `git merge origin/main` — this keeps conflict surface minimal and surfaces adopter-visible paths as main advances. If origin/main advances during execution, merge happens at the next gate boundary (not ad-hoc).

**Enforcement:** Phase gate-check includes `git rev-list --left-right --count origin/main...HEAD` — if right-side count is non-zero (commits on origin/main not yet merged), gate BLOCKS.

### Principle 17 — Open questions are 1B1 blockers

Every open question in the PVR §9 / A&D / plan must have a 1B1 resolution recorded in `research/open-questions-resolutions-<date>.md` **before** the phase that would act on that question enters execution. No phase transitions with unresolved open questions touching its scope.

**Enforcement:** Gate entry for each phase runs `open-questions-check --phase=N` which lists unresolved questions scoped to that phase; gate BLOCKS if any present.

### Principle 18 — Decouple project name from release version

- **Project name:** `v46.0-structural-reset` (descriptive; stays in branch name, plan title, release-notes narrative)
- **Release version:** `D.R` (assigned by principal; written to `agency/config/manifest.json` `agency_version`)
- These are distinct: the project name describes what this reset IS; the release version describes where it lands in the tag sequence. Release tag format: `vDD.R` (e.g., `v45.3`, `v46.1`).

**Decision deferred to Phase 0a opening 1B1:** what is the D.R for this reset?

## 4. Salvage Strategy — from abandoned `v46.0-structural-reset` branch

The overnight branch has artifacts worth preserving. Salvage via cherry-pick onto a fresh branch cut from current `origin/main`:

| Commit | Content | Salvage action |
|--------|---------|----------------|
| `5f6f5cf2` | agent-identity main-checkout fix + `block-raw-tools.sh --agent` flag typo | **Cherry-pick** |
| `0cb4fc73` | 36 hookify canary fixtures + test-scoper src/archive/** exclude | **Cherry-pick** (canaries apply; test-scoper path may need rebase adjustment) |
| Phase 0 tool commits (`0401f768`, `a4808493`, `044823f8`) | 20 new tools (git-rename-tree, agency-sweep, ref-inventory-gen, gate-check, agency-verify-v46, agency-health-v46, etc.) | **Cherry-pick**; these tools ARE Phase 0 deliverables in v5 |
| `1880c40e` | Phase 4 sweep residual cleanup (verification tool fixes + commit-precheck regex fix + handoff impl-file regex fix + icloud-setup agent dir check) | **Partial cherry-pick:** take the commit-precheck + handoff fixes; DROP the verification-tool "repairs" since those tools will be re-validated in v5 Phase 0 |
| Phase 1-4.5 rename commits (`1662036c`, `ae556af9`, `f3c1f33f`, `ad472b6c`, `7fabf727`, `16b7b4f0`, `cf43cf1d`) | The actual rename + subdir moves + sweep | **DO NOT cherry-pick.** These are replaced by a clean re-execution per plan v5. |
| QGR receipt `79c1f1a6` | Synthetic plan-complete receipt | **Do not cherry-pick.** Invalid for a new execution. |
| Release notes + runbook + manifest bump `3b7d0702`, `a8952094` | Release notes skeletons | **Do not cherry-pick.** Rewrite at v5 Phase 6 with correct D.R. |

**Tag the abandoned branch** before branch-delete: `abandoned/v46.0-overnight-shortcut-20260420`.

## 5. Phase Structure — v5 (net additions from v4)

### Phase -1 — Pre-reset Inventory + Open-Question 1B1s (NEW in v5, ~45 min)

**Objective:** enumerate latent bugs, misfilings, deprecated-but-unremoved dirs. Resolve open questions via 1B1. Produce `research/phase-minus-1-inventory-<date>.md` + `research/open-questions-resolutions-<date>.md` as gate evidence.

**Sub-phases:**

- **-1a. Latent tool-reference audit.** For every `./agency/tools/X` (or pre-rename `./claude/tools/X`) invocation across the tree, verify the target exists. Record misses. Specifically audit: `agency-whoami` references in `session-backup`, `restore`, `project-create`, `_agency-init`, `context-save`, `context-review`, `config`, `commit-prefix`, `bug-report`, `agent-create`.
- **-1b. Misplaced-file audit.** Inventory: `tools/service-add.ts`, `tools/ui-add.ts`, `tools/lib/`, `usr/test/`, any `agency/agents/unknown/` or similar identity-fallback output.
- **-1c. Deprecated-dir audit.** Inventory contents + origin + last-mutation date for: `agency/docs/`, `agency/receipts/`, `agency/integrations/claude-desktop/`, `agency/logs/reviews/`, `agency/data/bug.db` (if present), `agency/data/bugs.db` (if present), `agency/assets/`, `agency/schemas/`, `agency/workstreams/test; rm -rf ` (injection artifact).
- **-1d. Open-question 1B1 block.** Principal + captain 1B1 on each:
  - Q1: Release version for this reset — D? R?
  - Q2: `src/` population — in scope this reset or follow-up?
  - Q3: `agency/docs/` contents — delete / archive to flotsam / keep-with-subdir-restructure
  - Q4: `agency/receipts/` legacy RGRs — delete / archive
  - Q5: `agency/integrations/claude-desktop/` — purpose + keep/move/delete
  - Q6: `agency/logs/reviews/` — delete / archive
  - Q7: `agency/assets/` — stay or move to `agency/brand/`
  - Q8: `tools/*.ts` misfilings — move to `agency/tools/`? `src/`? delete?
  - Q9: `usr/test/` fixture — move to `test/` or `agency/templates/principal/`? delete?
  - Q10: `agency/agents/unknown/backups/` — delete + `.gitignore` pattern
  - Q11: Latent `agency-whoami` bug — fix in this reset (restore tool OR refactor callers) or carve out to follow-up
  - Q12: Pre-existing `bug.db` / `bugs.db` fate (PVR Open Q #6)
  - Q13: `agency/workstreams/gtm/`, `agency/workstreams/proposals/` — leave with TODO-markers OR cross-repo move (plan §4.6 says deferred if collab repo not ready; check status)

**Gate -1 exit:** all 13 open questions resolved in writing; all latent-bug items have fix-plan or carve-out. Inventory report committed.

**MAR checkpoint -1→0** — 3 reviewers (architect, operations, risk).

### Phase 0 — Baseline + Tooling Build (retained from v4 ~90 min)

Same as v4 Phase 0 with these additions:

- **New tool: `reset-autonomy-check.sh`** (Principle 14 enforcement).
- **New tool: `open-questions-check`** (Principle 17 enforcement).
- **Phase gate script enhancement** — include `git rev-list --left-right --count origin/main...HEAD` for Principle 16 enforcement.
- **Salvage cherry-pick list execution:** cherry-pick the salvageable commits from abandoned branch at Phase 0 start; verify via BATS.
- **`.gitignore` update** for `agency/agents/unknown/`, `agency/agents/*/backups/` (runtime artifact), `.reset-wt/` (subagent worktrees).

### Phase 1 — Great Rename (retained from v4 ~15 min)

Unchanged from v4.

### Phase 2 — Subdir Reorg (v4 2a-2f + NEW 2g/2h ~60 min)

v4 sub-phases 2a-2f retained (src/ tree, starter-packs, dead artifacts, 9 non-class agents, templates, designex refactor).

**NEW sub-phases:**

- **2g. REFERENCE/ subdir move.** `mkdir agency/REFERENCE`; `git-rename-tree agency/REFERENCE-*.md → agency/REFERENCE/`. (Was Subagent B's scope in v4 — moved to explicit Phase 2 sub-phase to prevent skip.)
- **2h. README/ subdir move.** `mkdir agency/README`; move README-ENFORCEMENT, SAFE-TOOLS, RECEIPT-INFRASTRUCTURE → `agency/README/`; README-THEAGENCY + README-GETTINGSTARTED stay at `agency/` root.

**Gate 2 exit:** v4 criteria plus:
- `agency/REFERENCE/` contains exactly 36 files (matches PVR §7 #2)
- `agency/README/` contains exactly 3 files (matches PVR §7 #3)
- No flat `agency/REFERENCE-*.md` or `agency/README-*.md` except the two top-level READMEs

### Phase 3 — Archive + Extract + Delete (retained + expanded ~60 min)

v4 Phase 3 sub-phases 3a (archive principals) + 3b (extract) + 3c (delete) retained with additions **determined by Phase -1 open-question resolutions**:

- `agency/docs/` — action per Q3 resolution
- `agency/receipts/` — action per Q4 resolution
- `agency/integrations/claude-desktop/` — action per Q5 resolution
- `agency/logs/reviews/` — action per Q6 resolution
- `agency/assets/` — action per Q7 resolution
- `tools/*.ts` — action per Q8 resolution
- `usr/test/` — action per Q9 resolution
- `agency/agents/unknown/` — delete + .gitignore (Q10 action)
- `bug.db` / `bugs.db` — action per Q12 resolution
- `agency/workstreams/test; rm -rf ` — delete per v4 plan
- `agency/workstreams/gtm/` + `proposals/` — action per Q13

### Phase 4 — Reference Sweep (retained from v4 ~85 min, with hardened discipline)

Explicitly 5 parallel subagents (A-E) with per-subagent manifests. NO combined manifest. NO captain-solo.

**Enforcement:** `reset-autonomy-check.sh` runs at Phase 4 entry; refuses to enter if `phase-4-combined-manifest.yaml` exists in reset-baseline-dir. Hard fail.

Subagent manifests reused from abandoned branch `usr/jordan/captain/reset-baseline-20260419/subagent-{A-E}-manifest.yaml` (they were authored correctly; execution skipped them).

### Phase 4.5 — @import + settings + shim cleanup (retained from v4 ~15 min)

Unchanged from v4, with new reference-rewrite targets from Phase 2g/2h:
- `@agency/REFERENCE-*.md` → `@agency/REFERENCE/REFERENCE-*.md`
- `@agency/README-*.md` (for ENFORCEMENT/SAFE-TOOLS/RECEIPT-INFRASTRUCTURE) → `@agency/README/README-*.md`
- Ref-injector hook mapping update

### Phase 5 — Hookify Canary (retained from v4 ~15 min)

Cherry-picked canaries from abandoned branch cover 36 of 42 rules. Phase 5 runs the remaining 6 (plus validates all 36 still pass post-fresh-execution).

### Phase 6 — Release Notes + Runbook + PR (retained from v4 ~40 min)

v4 Phase 6 retained with:
- Version format per Principle 18 (D.R, not 46.0.0)
- Release notes explicitly document the plan-failure + rework: "v4 was attempted and abandoned; this release is the v5 re-execution"
- Runbook reflects the actual final state (REFERENCE/, README/, etc.)

### Gate 7 — Post-merge smoke (retained from v4)

Unchanged.

## 6. Execution Checklist (v5)

1. **MAR this plan (v5)** — 4 reviewers on plan document
2. **Resolve MAR findings** ≥50
3. **Principal final approval** of plan v5
4. **Tag abandoned branch** `abandoned/v46.0-overnight-shortcut-20260420`
5. **Cut new branch** `reset/v5-structural-reset-20260420` from current `origin/main` HEAD
6. **Cherry-pick salvage commits** per §4 table
7. **Execute Phase -1** (pre-reset inventory + 1B1s)
8. **Execute Phases 0 through 6** per plan
9. **Merge + post-merge** per Gate 7

## 7. Out of Scope (v5)

Same as v4 §8, subject to Phase -1 Q2 resolution (`src/` population may move in-scope).

## 8. Non-Goals

Unchanged from v4 §8 (pending Q2).

## 9. Open Questions

All 13 questions in Phase -1 §1d must be resolved before Phase 0 entry. See Principle 17.

---

**Next action:** principal reviews plan v5. Then MAR (4 reviewers). Then findings fold. Then principal approves. Then execute.
