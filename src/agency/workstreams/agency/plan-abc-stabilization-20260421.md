---
type: plan
workstream: agency
date: 2026-04-21
day: D45
principal: jordan
captain: the-agency/jordan/captain
status: in-flight-v3.3 (E shipped v46.12; Bucket 0 shipped v46.13; C#372 shipped v46.14; Bucket G.1 accelerated to R4 v46.15)
supersedes: none
revision: v3.3 — fleet-rename dispatch gap + Bucket G.1 acceleration (Great-Rename-migrate tool moves from R9 to R4 — two worktrees blocked on rename)
mar_reviews:
  - qgr/mar-plan-abc-architect-20260421.md
  - qgr/mar-plan-abc-devex-20260421.md
  - qgr/mar-plan-abc-blindspots-20260421.md
related:
  - plan-d42-r3-workstream-content-split-20260416.md
  - research/issues-triage-20260421.md
  - research/triage-x-plan-memo-20260421.md
  - usr/jordan/captain/captain-handoff.md
tags: [stabilization, session-lifecycle, python-runtime, ci, release-automation]
---

# Plan — A-B-C-D-E-F-G Stabilization Push (2026-04-21) — v3.3

## Revision log

**v3.2 → v3.3 changes — surfaced mid-session:**

1. **Bucket 0 shipped as v46.13** (PR #405) and **C#372 shipped as v46.14** (PR #406, promoted from R6 slot for release-automation-gap urgency — 4-fix stack A+B+C+D shipped atomically).
2. **Fleet-rename dispatch gap identified.** The `claude/`→`agency/` + `tests/`→`src/tests/` structural rename landed on main (PRs #373, #386) without a pre-merge procedure-dispatch to the fleet. DevEx (#827) and DesignEx both hit the resulting merge conflicts independently. Captain sent fleet-wide path-forward dispatches 2026-04-21 (IDs 828-837). Standing-duty item filed: future structural renames require pre-merge procedure-dispatch.
3. **Bucket G.1 accelerated from R9 to R4 v46.15.** Two worktrees are blocked on manual rename reconciliation; 5+ more will hit it. Building `agency/tools/great-rename-migrate` NOW converts each future reconciliation from captain-expensive to mechanical. Bucket F shifts from R3 to R5.
4. **Bucket F plan v1 MAR-reviewed, NOT ready to execute.** 29 combined findings from design + scope/risk review agents. Both recommend Path A (proper plan v2 revision) over Path B (fix 6 HIGH + execute with caveats). Principal decision pending. Plan v2 drafting happens before R5 v46.16.
5. **Test-isolation-guard pending placement.** Principal flagged test-pollution from BATS tests writing to `$PWD` (untracked dirs like `test; rm -rf/` in repo root). Proposal: small tool + hookify rule + offender hunt. Slot TBD — before Bucket F (safety net for 5-subagent mechanical sweep) is my recommendation. Principal 5-decision Over outstanding.
6. **Sequencing + release cadence updated** — G.1 promoted to R4; F to R5; PR #397 to R6; A/B/D shift one slot each; G.2a-e unchanged at R10-R14.

**v3.1 → v3.2 changes — surfaced post-Phase-E merge:**

1. **Bucket E shipped** as v46.12 (PR #400 merged). Phase E was explicitly NARROW — targeted `skill-validation.bats` unblock on 21 skill files only. Full-tree audit deferred.
2. **New Bucket F** (full-tree sweep) — issue #401. Post-#400 audit surfaced residue across customer-shipped surfaces (`agency/README-*`, `REFERENCE/`, `README/`, `config/`, `agents/`, `tools/`, `.claude/agents/`, `src/apps/**`) not covered by skill-validation. Layer 1 = customer-shipped, Layer 2 = framework-internal audit, Layer 3 = new `framework-validation.bats` to prevent regression. Slots between Bucket 0 and PR #397.
3. **New Bucket G** (Great-Rename worktree integration) — issue #402. Routine post-merge worktree-to-main integration surfaced structural debt: 5 agent branches (mdslidepal-mac +9, mdpal-app +26, devex +27, iscp +39, designex +61) cut pre-Great-Rename, all added files under OLD path structure (`claude/`, `apps/`, `tests/`). Every merge produces `CONFLICT (file location)` per added file. **First item** of Bucket G = build `agency/tools/great-rename-migrate` (bash) — tool that applies path-rename map mechanically on agent branches + detects build artifacts. Then dispatch each of 5 agents to run tool + merge + resolve residual content conflicts + test + push + notify. Multi-release, starts after Bucket D.
4. **Captain standing duty captured:** integrate worktree commits into main after every `/iteration-complete`, `/phase-complete`, `/plan-complete`, `/seed`, `/define`, `/design`, `/plan` completion. Flagged for CLAUDE-CAPTAIN.md update.
5. **Sequencing + release cadence updated** — F inserted as R3, G as R8+ multi-release.

**v3 → v3.1 changes — surfaced mid-execution:**

1. **New Bucket E** (pre-flight before Bucket 0): remove residual `monofolk` references from 19 skill files. `skill-validation.bats` test "no monofolk references" fails on these → `commit-precheck` blocks every commit without `--no-verify`. Caught while trying to commit Bucket 0a (#339) fix. Principal directive: "add a phase to your plan and fix these."

**v2 → v3 changes from principal review:**

1. **New Bucket D** = #392 (agency update chicken-egg) — moved out of B per principal direction. Monofolk works around it in their Great Rename; it's on the work plan but not a hotfix.
2. **PR #397 placement confirmed:** after Bucket 0, before Bucket A. Clean push/release tooling before injecting external dependency.
3. **Sequencing table updated.**

**v1 → v2 changes from MAR review** (three agents — architect, devex, blindspots):

1. **Added Bucket 0** (pre-flight): #339 (bash 3.2 push) + #210 (dispatch loop) — both are live blockers for the push itself.
2. **Expanded Bucket A**: added #198 + #199 (session-lifecycle siblings to A#393 — same severity class).
3. **Bucket A bundling**: A#395 land before A#393 (semantic cleanliness). A#393 covers compact-prepare deterministically.
4. **A#394 corrections**: sweep scope is N=1 (dispatch-monitor only); added Docker matrix test; added parity baseline.
5. **B bucket corrections**:
   - B#388 + B#389 bundled (same file).
   - **B#389 fix mechanism corrected** — loosen input validation, NOT `update-index --force-remove` (devex F5, correctness bug in v1).
   - B#383 flagged for re-verification (likely already fixed).
   - B#384 moved earlier (gates A test rigor).
   - B#392 moved earlier (unblocks adopters).
6. **C#372**: diagnosis moved to run in parallel with Bucket 0+A (not serial).
7. **Release cadence**: pre-specified 4-5 natural boundaries (not 11 per-PR releases).
8. **New exit criteria**: push-level smoke ritual, skill-contract test coverage.
9. **New principal gates**: A#394 shebang strategy, B#392 fix-vs-defer.
10. **"Remember not to rewrite" mechanism**: explicit — QGR cross-ref + Phase 5 plan template section requiring it.
11. **Triage accuracy note**: blindspots found 2 classification errors in triage (1.2%). Plan assumes triage is indicative but not authoritative; bucket placements re-verify before commit.

## Context

Morning D45 session started with `/session-resume` and immediately surfaced three concrete errors. Root-causing them surfaced more. Principal directive:

1. **A → B → C**: fix the fresh stabilization items, then filed backlog, then release automation gap.
2. **Triage** all open issues (now 167): resolve already-addressed + dupes, group by theme.
3. **Make the call** on what else to fix.
4. **Phase 5** (Plan v5 Phase 4+).

This plan covers Step 1 (A-B-C, now with a Bucket 0 pre-flight). Step 2 triage lives at `research/issues-triage-20260421.md`. Step 3 decision happens at principal review. Step 4 is separate.

## Goals

- Restore session-lifecycle hygiene — `/session-end` → `/session-resume` cycle works clean; all 3 session-lifecycle bugs landed.
- Unblock framework tools on Apple-stock + brew-only hosts.
- Close the release automation gap before running 10+ PRs in a row.
- Land the stabilization work the refactor sprint surfaced — without creating work Phase 5 will delete.
- Leave a push-level smoke ritual as a regression guard.

## Non-goals

- No Phase 4+ / Phase 5 work.
- No other FIX-NOW items from triage beyond those promoted into A/B/C (the other 33 go to Step 3 principal decision).
- No monofolk-side work — PR #397 is a contributor-review path handled separately (see Risks §1).
- No skill-contract fleet-wide test suite build (class-fix candidate; scope-decision flagged).

## Bucket E — Skill validation unblock (NEW in v3.1 — lands FIRST, before Bucket 0)

### E — Remove residual `monofolk` references from 19 skill files
**Severity:** Blocker. `skill-validation.bats` test "no monofolk references" fails → `commit-precheck` blocks every commit. No work can land until this clears.

**Root cause.** Skills ported from monofolk carry hardcoded `monofolk_version`, `monofolk` workflow references in SKILL.md + examples.md + reference.md + scripts. The-agency framework should be generic.

**Files (19):**
- `.claude/skills/captain-log/SKILL.md`
- `.claude/skills/captain-release/{SKILL.md, reference.md}`
- `.claude/skills/captain-review/SKILL.md`
- `.claude/skills/pr-captain-land/{SKILL.md, examples.md, reference.md, scripts/pr-captain-land, scripts/README.md}`
- `.claude/skills/pr-captain-merge/examples.md`
- `.claude/skills/pr-captain-post-merge/{SKILL.md, examples.md, reference.md}`
- `.claude/skills/pr-submit/{SKILL.md, examples.md, reference.md, scripts/pr-submit, scripts/README.md}`
- `.claude/skills/transcript/SKILL.md`

**Genericization pattern:**
- `monofolk_version` → `agency_version` (framework version token)
- `monofolk` in workflow text → `<repo>` or "the-agency" where appropriate
- History/provenance mentions of "monofolk" left intact per-case (it's legitimate reference to the sister repo).

**Exit criteria:**
- [ ] `bats src/tests/skills/skill-validation.bats` passes all tests.
- [ ] `commit-precheck` unblocks for ordinary commits.
- [ ] Remaining literal `monofolk` references are justified provenance/cross-repo refs only.

**PR:** first PR of the push. R1. Bumps 46.11 → 46.12.

---

## Bucket F — Full-tree sweep (NEW in v3.2 — lands between Bucket 0 and PR #397)

Issue #401. Post-Phase-E audit surfaced residue across customer-shipped surfaces not covered by `skill-validation.bats`.

### F — Sweep monofolk + usr/jordan + {org} + ordinaryfolk across customer-shipped surfaces + add framework-validation.bats

**Layer 1 (customer-shipped, priority):**
- `agency/README-THEAGENCY.md`, `README-GETTINGSTARTED.md`, `CLAUDE-THEAGENCY.md`
- `agency/REFERENCE/*` (14 docs), `agency/README/*`
- `agency/config/agency.yaml`, `dependencies.yaml`, `agency-dependencies.yaml`, `manifest.json`
- `agency/agents/captain/agent.md`
- `agency/tools/*` (21 tools with residue)
- `.claude/agents/jordan/*.md` (9 agent registrations)
- `src/apps/mdpal/**` (~40 files, absolute `/Users/jordan/` paths — audit test-only vs. runtime)
- `src/apps/mock-and-mark/tools/book-note`

**Layer 2 (framework-internal, lower priority — audit intent):**
- `src/tools-developer/*`, `src/tests/tools/*.bats`, `.github/workflows/release-tag-check.yml`, `CHANGELOG.md`, `CODE_OF_CONDUCT.md`

**Layer 3 (tests):** new `src/tests/framework-validation.bats` covering all Layer 1 surfaces; asserts no `monofolk`, `usr/jordan/` (in shipped docs), `<org>`, `{org}`, `ordinaryfolk`. Bug-exposing test first (red against current main), then fixes (green).

**Out of scope:** `src/archive/**`, `usr/jordan/**` history, `agency/workstreams/**/history/flotsam/**`, hookify canaries (intentional), today's QGR/plan/triage/MAR docs.

**Gating:** MAR on sweep plan (catches runtime-literal traps like #400's `<org>` critical finding), bug-exposing test red→green, full bats green.

---

## Bucket 0 — Pre-flight (must land before Bucket A)

Two issues surfaced by blindspots MAR that are **live blockers for executing this push itself**:

### 0#339 — `git-captain push` fails under bash 3.2 + `set -u` ("push_args[@]: unbound variable")
**Severity:** Blocker for the push. **Captain pushes ~11 times during this push**; every argless push fires this bug.

**Root cause.** `push_args[@]` expanded under `set -u` with zero elements is "unbound." macOS bash 3.2 is strict about this.

**Fix.** Initialize `push_args=()` or use `"${push_args[@]:-}"` expansion pattern. Standard bash 3.2-safe idiom.

**Files:** `agency/tools/git-captain`
**Tests:** BATS case — empty argv + `set -u` + bash 3.2.
**Complexity:** Trivial.

### 0#210 — Infinite dispatch artifact loop: every commit creates a dispatch that needs committing
**Severity:** Could stall the first commit of the push.

**Fix.** Needs diagnosis — may be that commit-hook fires dispatch-create which itself needs a commit, recursion.

**Files:** likely `agency/hooks/commit-*.sh` or dispatch-create invocation
**Tests:** BATS case — commit twice in a row, verify no recursion.
**Complexity:** Moderate (depends on diagnosis).

**Pre-flight exit:** Both merged. Verified: captain can argless-push and consecutive coord commits don't loop.

---

## Bucket A — Fresh + promoted-from-triage session-lifecycle items

### A#395 — `git-safe-commit --coord` convenience flag  **[MOVED UP — was v1 position 3]**
**Severity:** Nit / DX. Now first in A so A#393 can consume it idiomatically.

**Fix.** Add `--coord` flag. Implies `--no-work-item`, validates coord artifacts, uses `misc:` prefix.

**Principal decision:** should we deprecate `--no-work-item` in favor of `--coord` as canonical? (devex F4). Default: keep both, `--coord` recommended, `--no-work-item` as escape hatch, doc both clearly.

**Files:** `agency/tools/git-safe-commit`, `src/tests/tools/git-safe-commit.bats`, docblock.
**Bonus:** update `/coord-commit` skill body to invoke `--coord` internally (consistency).
**Complexity:** Trivial.

---

### A#393 — session-end + **compact-prepare** (deterministic) write handoff without committing it
**Severity:** Bug. Hits every PAUSE-surface skill run.

**Scope — corrected from v1.** Both `/session-end` AND `/compact-prepare` have the identical bug (architect F3 confirmed by reading the skill). Both get the Step 2.5 commit fix. Single PR.

**Fix.** Add Step 2.5 to each skill: after writing the handoff, commit via `git-safe-commit --coord` (using flag from A#395 above).

**Files:**
- `.claude/skills/session-end/SKILL.md` — Step 2.5.
- `.claude/skills/compact-prepare/SKILL.md` — same Step 2.5.
- `src/tests/skills/session-end.bats` — clean-tree assertion + **integration test** covering full PAUSE→PICKUP cycle (devex F1).
- `src/tests/skills/compact-prepare.bats` — same pattern.

**Principal decision:** skill-contract test fleet-wide (every skill description vs. behavior predicate) — YES for this push, or follow-up? (devex F1). Default: **follow-up**. Class-fix work deserves its own plan; this push's scope is limited to session-lifecycle.

**Complexity:** Trivial-to-moderate.

---

### A#198 — `/session-resume` Step 4 uses raw git commands blocked by hookify  **[NEW in v2 — triage promoted]**
**Severity:** Every `/session-resume` run hits this.

**Fix.** Replace raw git commands with `git-safe` calls in the skill body.

**Files:** `.claude/skills/session-resume/SKILL.md` (or wherever step 4 lives).
**Tests:** BATS — `/session-resume` runs without hookify blocks.
**Complexity:** Trivial.

---

### A#199 — `session-preflight` fails on framework-managed dirty state (handoff, logs, archived handoffs)  **[NEW in v2 — triage promoted]**
**Severity:** Every session-resume hits this if any framework-managed file is dirty. Interacts directly with A#393 fix — even post-A#393, other framework-managed dirt (logs, archived handoffs) triggers preflight failure.

**Fix.** Teach preflight to distinguish "coord-artifact dirty" (expected, non-blocking) from "framework-code dirty" (blocking). Requires classifier that matches `session-pause` primitive's framework-code-gate.

**Files:** `agency/tools/session-preflight` + classifier.
**Tests:** BATS — preflight passes with coord-dirty, fails with framework-code-dirty.
**Complexity:** Moderate. Shares classifier with session-pause (consolidation opportunity or mere duplication — principal decision during impl).

---

### A#394 — Python tools fail on Apple-stock + brew-only `python@3.13` host
**Severity:** Blocks Monitor tool, `dispatch-monitor`.

**Scope correction from v1.** Blindspots verified: only `dispatch-monitor` currently carries the `sys.version_info < (3, 13)` runtime guard. Sweep is N=1, not N-many. Plan was over-scoped.

**Fix.** Three parts:
1. **Ship `agency/tools/_py-launcher`** (bash) — finds `python3.13+`, execs target.
2. **Update `dispatch-monitor` shebang** to use launcher (pilot). Remove the runtime guard (the launcher does the version check before Python starts).
3. **Improve error message** at launcher-level if no suitable Python found — concrete remediation (`brew link --overwrite --force python@3.13`).

**Principal decision** (architect F5, devex F2): shebang strategy — bash-launcher-wrapper (this plan's choice) vs. Python-re-exec vs. polyglot shebang? Default: **bash launcher wrapper**. Cleanest for N=1 (no churn on tools that don't need it yet). If future Python tools need 3.13+, they update shebang to match.

**Tests:**
- BATS mock-PATH for branch coverage.
- **Docker matrix test** (devex F2) if B#384 lands in this push — validates real install profiles (apple-stock + brew-unlinked, pyenv-shim, etc.).
- CI smoke on macOS runner — `dispatch-monitor --help` exit 0.
- Parity baseline (devex F6): capture `dispatch-monitor --help` output before + after sweep; must match.

**Files:**
- `agency/tools/_py-launcher` (new bash wrapper ~30 lines).
- `agency/tools/dispatch-monitor` (shebang update).
- `src/tests/tools/_py-launcher.bats` (new).
- `agency/REFERENCE/REFERENCE-PYTHON.md` (new — launcher contract + install-profile table).

**Complexity:** Moderate.

---

## Bucket B — Filed stabilization backlog (re-ordered)

### B#383 — presence-detect status line missing framework version  **[FLAGGED FOR RE-VERIFY]**
Blindspots says: `agency/tools/statusline.sh` lines 174–185 already wire `agency_version`. If verified, #383 is **already fixed**; close it with a test (which ensures regression protection) and move on.

**Pre-flight step:** I (captain) re-verify before starting work. If confirmed fixed, close with a "add regression test" PR.

---

### [MOVED TO BUCKET D] — see `## Bucket D` section below for #392. Placeholder kept here to avoid renumbering cross-refs elsewhere in this doc.

---

### B#388 + B#389 — git-safe DX bundle  **[BUNDLED — was v1 positions 7 & 8]**
Both touch `agency/tools/git-safe` + `src/tests/tools/git-safe.bats`. One PR.

**B#388 — `git-safe add` rejects directory-level paths.**
Add `--dir` opt-in flag. Validates no sensitive patterns (`.env`, `credentials.json`). Default behavior unchanged.

**B#389 — `git-safe unstage` refuses shell-meta paths.**  **[FIX MECHANISM CORRECTED]**
*v1 proposed `git update-index --force-remove -z --stdin`.* That's wrong — equivalent to `git rm --cached`, not `git reset HEAD --` (devex F5, correctness bug).

Actual fix: `cmd_unstage` already uses argv-safe passthrough (`git reset HEAD -- "$@"`). The bug is **over-aggressive input validation** at `git-safe` lines ~408–414. Fix: loosen the validation to allow newlines/quotes/etc. through. Alternative: migrate to `git restore --staged --pathspec-from-file=- --pathspec-file-nul` for really pathological cases.

**Tests:** `git-safe.bats` with literal-newline and quote filenames. Assert post-unstage that file remains in working tree (not deleted), and index entry is gone.

**Complexity:** Trivial (B#388) + trivial (B#389, now that mechanism is right).

---

### B#385 — `commit-precheck` scoped bats hangs on large PRs
**Fix (from v1, expanded per devex F3):**
1. Cap total timeout at 5 min.
2. Per-test timeout via `timeout 30 bats <file>` **with process-group kill** (matches existing `run_with_timeout` discipline).
3. File-level timeout (catches `setup_file` hangs — per-test timeout doesn't fire if no test has started).
4. Override mechanism — tests that legitimately need >30s declare `BATS_PER_TEST_TIMEOUT=60` in their `setup_file`.

**Tests:**
- commit-precheck against a test file that hangs in `setup_file`.
- commit-precheck against a test that spawns a subprocess which outlives it.
- commit-precheck with override — test declaring longer timeout.

**Exit criteria coupling to B#384** (architect F7): "per-test timeout mechanism = Docker hard-kill (if B#384 in) OR `timeout` subprocess (if B#384 out)." Plan states both paths explicitly.

**Complexity:** Moderate.

---

### B#384 — BATS tests must run in Docker  **[MOVED EARLIER — was v1 position 10]**
**Rationale for earlier placement:** A#393, A#394, A#199 tests ALL need the isolation. Running on host risks pollution of the kind gitignore guards only paper over.

**Fix.** Dockerfile at `src/tests/Dockerfile` + wrapper `./agency/tools/bats-docker` + CI wiring.

**Principal decision (already gated in v1, still open):** in-scope or deferred to own phase?

**If in-scope:** lands before A items; all A BATS tests run in Docker from commit day one.
**If deferred:** A items ship with host-run BATS + pollution guards (accept the lower rigor; flagged in exit criteria).

**Exit criteria if in-scope:**
- `bats-docker` local-identical to host-run output.
- No real-tree pollution after any test run.
- A#393, A#394, A#199 tests all green via bats-docker.

**Complexity:** Structural. Capped at "one working session" of effort — if Dockerfile + wrapper doesn't land in that window, escalate to own phase.

---

## Bucket D — Adopter unblock (NEW in v3)

### D#392 — `agency update` chicken-egg (adopter-side fix)
**Severity:** Medium — monofolk works around it in their Great Rename; the-agency adopters on pre-v46.1 still need the bridge.

**Status recap:**
- Upstream rsync path already fixed (`agency/ → agency/`) during v46.1 Great Rename.
- Adopter-side experience not fixed: stale local `_agency-update` silently no-ops.
- Issue #392 remains OPEN on GitHub.

**Fix — 4 parts:**

1. **Migration doc** — `agency/REFERENCE/REFERENCE-MIGRATION-V46.md` with one-time bootstrap rsync command for adopters on pre-v46.1.
2. **Upstream code fix** — current `agency/tools/lib/_agency-update` gets a source-tree shape check: if rsync source paths don't exist, fail loudly (not silent `|| true`). Protects against future renames.
3. **Regression test** — BATS case simulating stale-source state, asserting loud failure.
4. **Adopter communication** — migration doc linked from README; push notice to known adopters (you, andrew-demo).

**Phase 5 interaction:** Phase 4c (#376) rewrites `_agency-update` manifest-driven. The shape-check from step 2 should survive that rewrite. Captured in `agency/workstreams/agency/research/phase-5-preserve-list.md`.

**Files:**
- `agency/REFERENCE/REFERENCE-MIGRATION-V46.md` (new)
- `agency/tools/lib/_agency-update` (shape-check addition)
- `src/tests/tools/_agency-update.bats` (new or augment)
- `README.md` or similar (migration link)
- `agency/workstreams/agency/research/phase-5-preserve-list.md` (new)

**Complexity:** Moderate.

**Exit criteria:**
- [ ] `agency update` on a pre-v46.1 adopter emits clear error + link to migration doc (not silent no-op).
- [ ] Migration doc includes copy-paste bootstrap one-liner.
- [ ] BATS regression test fails on stale-source simulation.
- [ ] Phase-5-preserve list records the shape-check invariant.

---

### B#55 — CI build-out
**Exit criteria coupling to B#384** (architect F7): if B#384 in, CI runs tests via `bats-docker` from day one; runtime budget 5 min becomes tight. If B#384 out, host-run BATS on CI (Ubuntu runner has its own isolation tier).

**Scope for this push:** minimal first pass — lint (shellcheck) + core BATS battery. Broader coverage (typecheck, full BATS, skill-audit, framework-verify) follows in subsequent PRs.

**Files:** `.github/workflows/smoke.yml` replacement.

---

## Bucket C — Release automation gap

### C#372 — `pr-captain-post-merge` + `release-tag-check` didn't fire for 8 merges
**Sequencing change from v1** (architect F4): diagnosis runs **in parallel with Bucket 0 + Bucket A**. Fix PR lands before B bucket starts. Every Bucket B PR becomes a live test of the fix.

**Fix approach.** Diagnosis-first:
1. Pull recent merged PRs; enumerate which released, which didn't.
2. Check Actions workflow run history for `pr-captain-post-merge` + `release-tag-check`.
3. Identify invariant that broke.
4. Ship targeted fix PR with regression guard.

**Deliverables:**
- **Diagnosis report:** `agency/workstreams/agency/research/release-gap-diagnosis-20260421.md` — runs parallel.
- **Fix PR:** runs after diagnosis lands. Sequenced after A#394 per architect F4.

**Post-fix regression guard (devex F6-aligned):** CI assertion that every merged PR produced a release tag within N minutes. If this push produces 4-5 releases (not 11; see §Release cadence), the assertion fires that many times and is validated by ordinary push activity.

---

## Bucket G — Great-Rename worktree integration (NEW in v3.2 — multi-release, starts after Bucket D)

Issue #402. 5 agent branches cut pre-Great-Rename carry structural path debt. Every `git merge <branch>` into main produces `CONFLICT (file location)` per added file (old paths: `claude/`, `apps/`, `tests/`, `claude/workstreams/the-agency/`).

### G.1 — Build `agency/tools/great-rename-migrate` (bash) + BATS tests (FIRST ITEM)

Tool that runs on agent's worktree/branch. Applies rename map mechanically:
- `claude/workstreams/the-agency/` → `agency/workstreams/agency/`
- `claude/` → `agency/`
- `apps/` → `src/apps/`
- `tests/` → `src/tests/`

Detects + cleans build artifacts (`**/*.app/`, `**/.build/`, `**/node_modules/`, `**/*.{o,so,dylib}`) via `git rm --cached` + `.gitignore` update. Collision detection (new path exists on main → halt, principal decides). Commits: `fix: migrate branch to post-Great-Rename path structure (Bucket G)`. Output is structured (moved/collisions/gitignored/commit-sha/next-step).

**Refuses:** on main/master, on dirty tree, not in git repo.

**Tests:** `src/tests/tools/great-rename-migrate.bats` — dry-run, --apply, collision halt, build-artifact cleanup, refuse-on-main, refuse-on-dirty-tree.

### G.2 — Run tool on 5 agent branches (one dispatch per agent)

Per-branch conflict details captured today (2026-04-21):

| Branch | Ahead | Rename conflicts | Content conflicts | Special |
|---|---|---|---|---|
| mdslidepal-mac | +9 | 1 file | 0 | `.app` bundle to remove + gitignore |
| mdpal-app | +26 | 6 files | 0 | — |
| devex | +27 | 6 files | 1 (REPORTS-INDEX.md) | — |
| iscp | +39 | 13 files | 0 | — |
| designex | +61 | 13 files | 8 files (tools + bats + captain-handoff) | highest complexity |

Dispatch template (per agent): run `great-rename-migrate` preview → `--apply` → `git-safe merge-from-master` → resolve content conflicts manually → agent's test suite must pass → push → dispatch captain. Captain merges clean branch into main.

### G.3 — Framework learning capture

Document the Great-Rename-era debt lesson for future major refactors: before any tree-wide path rename, either (a) merge all active worktree branches first, or (b) ship a migration tool concurrent with the rename and dispatch it to all agents on day-of. This is a retrospective artifact (no further PR).

**Gating:** MAR on G plan before execution, plus `great-rename-migrate` gets its own QG pass.

---

## Sequencing

| # | Item | PR shape | Parallel? |
|---|------|----------|-----------|
| E | Skill validation — remove 19 files' monofolk refs | Multi-file edit + validation test | ✅ SHIPPED v46.12 (PR #400) |
| 0a | #339 git-captain push (bash 3.2) | Trivial fix + test | — |
| 0b | #210 dispatch artifact loop | Diagnose + fix | — |
| F | Full-tree sweep (#401) | MAR + bug-exposing test + multi-surface sweep + framework-validation.bats | — |
| — | C#372 diagnosis | Research doc (no PR) | runs parallel with 0a, 0b, F, A, PR#397 |
| — | **PR #397** (external — monofolk contributor) | Review + merge + release v46.15 | between Bucket F and Bucket A |
| 1 | A#395 `--coord` flag | Tool edit + tests | — |
| 2 | A#393 session-end + compact-prepare (single PR) | Skill edits + tests (incl. integration) | — |
| 3 | A#198 session-resume raw git fix | Skill edit + test | — |
| 4 | A#199 session-preflight framework-dirty guard | Tool edit + test | — |
| 5 | A#394 Python launcher (scoped N=1) | New tool + shebang swap + tests + REFERENCE doc | — |
| 6 | C#372 fix PR | Config/workflow fix + regression assertion | depends on C#372 diagnosis |
| 7 | B#383 verify + regression test | Close or regression-test PR | verify-first |
| 8 | B#388 + B#389 git-safe bundle | Tool edit + tests | — |
| 9 | B#384 Docker BATS (IF IN-SCOPE) | Dockerfile + wrapper + CI wiring | Principal go/no-go |
| 10 | B#385 commit-precheck timeouts | Tool edit + tests | depends on B#384 decision for mechanism |
| 11 | B#55 CI build-out | Workflow update | depends on B#384 decision |
| 12 | **D#392** agency update chicken-egg | Tool edit + REFERENCE doc + test + preserve-list | — |
| G.1 | `great-rename-migrate` tool + BATS | Tool build + tests (QG) | AFTER Bucket D |
| G.2 | Run tool on 5 agent branches | 5 serial dispatches + per-branch merges | one at a time |
| G.3 | Retrospective doc (pre-Rename debt lesson) | Workstream doc (no PR) | parallel with G.2 |

**Push-level smoke ritual** runs at close of push (devex F7): `/session-end` → fresh shell → `/session-resume` → `/session-end` — verifies the incident chain is no longer reproducible.

---

## Release cadence

Pre-specified boundaries (architect F6) — 4-5 releases total instead of 11:

| Release | Covers | Rough version | Status |
|---------|--------|---------------|--------|
| R1 | Bucket E (skill validation unblock) | 46.12 | ✅ shipped PR #400 |
| R2 | Bucket 0 (#339 + #210) | 46.13 | ✅ shipped PR #405 |
| R3 | C#372 release-automation-gap (A+B+C+D 4-fix stack, promoted from R6 for urgency) | 46.14 | ✅ shipped PR #406 |
| **R4** | **Bucket G.1 — `great-rename-migrate` tool + BATS (accelerated from R9 — 2+ worktrees blocked)** | **46.15** | ⏳ next |
| R5 | Bucket F (full-tree sweep #401 — pending plan v2 per MAR) | 46.16 | ⏳ |
| R6 | PR #397 (monofolk contributor) | 46.17 | ⏳ |
| R7 | Bucket A (A#395 + A#393 + A#198 + A#199 + A#394) | 46.18 | ⏳ |
| R8 | Bucket B (B#383 verify, B#388+B#389, B#385, [B#384]) | 46.19 | ⏳ |
| R9 | Bucket D (D#392) + B#55 + push-level smoke | 46.20 | ⏳ |
| R10 | Bucket G.2a — mdslidepal-mac integration (+9 commits) | 46.21 | ⏳ |
| R11 | Bucket G.2b — mdpal-app integration (+26 commits) | 46.22 | ⏳ |
| R12 | Bucket G.2c — devex integration (+27 commits, +1 content conflict) | 46.23 | ⏳ |
| R13 | Bucket G.2d — iscp integration (+39 commits) | 46.24 | ⏳ |
| R14 | Bucket G.2e — designex integration (+61 commits, +8 content conflicts) | 46.25 | ⏳ |

**Pending placement:** test-isolation-guard (small tool + hookify rule + offender hunt). Recommended slot: before R5 Bucket F, as a safety net for the 5-subagent mechanical sweep. Principal 5-decision Over outstanding — slot locks when answered.

Each release cuts a `gh release create` + tag + release notes. Manifest bumps occur at PR merge (one per PR); release groups multiple merged commits into one release tag.

---

## Exit criteria (push-level)

- [ ] Bucket 0 items merged: `git-captain push` argless works under bash 3.2; consecutive coord commits don't loop.
- [ ] All A items merged: session-end/compact-prepare leave clean tree; session-resume Step 4 uses `git-safe`; session-preflight tolerates coord-only dirt; `dispatch-monitor` and other Python tools run on Apple-stock + brew-only host without workaround.
- [ ] C#372 diagnosis doc landed; fix PR merged; every subsequent PR fires a release.
- [ ] B items merged OR explicitly deferred with issue note.
- [ ] **Push-level smoke ritual** passes on dev host: `/session-end` → new shell → `/session-resume` → no dirty-tree warning, no hookify blocks, no Python-version errors, no missing-release warnings.
- [ ] Triage report re-verified for #341 and #383 (known classification errors) — either corrected in triage or handled in push.
- [ ] Release count matches cadence plan (4-5 releases, not 11).
- [ ] Dispatch-monitor runs cleanly; no manual `/opt/homebrew/bin/python3.13` workaround needed.
- [ ] No unread dispatches at push close.

---

## Risks

### Risk 1 — PR #397 cross-repo dependency (promoted from v1 Non-goal → Risk)
Blindspots F5. PR #397 is a monofolk contributor PR to the-agency waiting on: review, version bump, QGR receipt, merge, release. It's blocked ONLY on principal approval (CI green, mergeable). If we start A-B-C without handling #397, monofolk captain stays blocked; cross-repo trust erodes. If we handle #397 in the middle of the push, it injects one version bump between our push PRs (messy cadence).

**Mitigation:** handle #397 BEFORE Bucket 0 starts (or immediately after Bucket 0; before A#395). That way the push starts from post-#397 state, clean sequence.

### Risk 2 — Fixing things Phase 5 will rewrite (mechanism added, v1 was hand-wave)
Architect F5 + blindspots F9. v1 said "remember not to rewrite." v2 specifies the mechanism:
- Each such item (B#392) carries `Phase-5-preserve: <behavior>` in commit message.
- `agency/workstreams/agency/research/phase-5-preserve-list.md` is authoritative.
- Phase 5 plan template has a required "Pre-rewrite audit" section referencing that list.

### Risk 3 — B#384 scope creep
Unchanged from v1. Capped at one working session; escalate to own phase if it doesn't land.

### Risk 4 — A#394 shebang strategy lock-in
If the bash-launcher-wrapper approach proves wrong (e.g., startup latency, environment leakage), undoing it is cheap (N=1, dispatch-monitor). Pilot catches issues before any future N-many sweep.

### Risk 5 — Triage inaccuracy propagating into bucket decisions
Blindspots found 2 classification errors in 167 items (#341 falsely ALREADY-FIXED, #383 likely already fixed). 1.2% error rate. Plan's Bucket B includes #383 pending re-verify; other "ALREADY-FIXED" and "SUBSUMED" classifications need a spot-check before any Step 3 decisions rely on them.

**Mitigation:** triage is indicative, not authoritative. Before promoting any triage item into follow-up work, re-verify. Re-triage pass after Phase 5 catches drift.

### Risk 6 — Release automation gap cascade
C#372 diagnosis reveals structural issue → multiple past releases missed → decision point on backfill. **Scope limit:** fix forward, don't backfill, unless principal asks.

### Risk 7 — Scope creep from blindspots findings
Blindspots found 12 items worth surfacing. Not all 12 are in-scope. In-scope: #339 (0a), #210 (0b), #198 (A), #199 (A), #341/#383 (re-verify). Out-of-scope deliberately: other triage FIX-NOW items are Step 3 principal decisions.

---

## Principal decision points (expanded)

| # | Question | Default |
|---|----------|---------|
| 1 | PR #397 — slot between Bucket 0 and Bucket A? | **Confirmed v3:** yes, after Bucket 0, before Bucket A |
| 2 | B#384 Docker BATS — in this push? | Principal decides |
| 3 | A#394 shebang strategy — bash launcher wrapper vs Python re-exec? | bash launcher wrapper (my pick) |
| 4 | D#392 fix-now vs defer to Phase 4c? | **Confirmed v3:** fix-now (D bucket per principal) |
| 5 | A#395 — deprecate `--no-work-item` in favor of `--coord`? | No deprecation; doc both |
| 6 | A#393 — skill-contract test fleet-wide in this push? | No — follow-up initiative |
| 7 | Release cadence — 4-5 natural boundaries (my proposal) or strict per-PR? | 4-5 natural boundaries |
| 8 | B#388+B#389 bundling — OK as exception? | Yes (architect F1, confirmed by devex F5) |
| 9 | #341 re-classification to FIX-NOW misc? | Yes — trivial close |
| 10 | #383 re-verify — if already fixed, close with regression test? | Yes |
| 11 | Bucket 0 items in scope? (#339, #210) | Yes — they block the push itself |

---

## Appendix — items by number

- **0#339** — git-captain push fails bash 3.2 + set -u (pre-flight)
- **0#210** — infinite dispatch artifact loop (pre-flight)
- **A#395** — git-safe-commit --coord flag
- **A#393** — session-end + compact-prepare handoff commit
- **A#198** — /session-resume Step 4 raw git
- **A#199** — session-preflight framework-dirty tolerance
- **A#394** — Python tools launcher (N=1 pilot on dispatch-monitor)
- **C#372** — release automation gap (diagnose + fix)
- **B#383** — status-line framework version (re-verify)
- **D#392** — agency update chicken-egg (adopter unblock) — moved from B to D per v3
- **B#388** — git-safe add directory support (bundled)
- **B#389** — git-safe unstage shell-meta (bundled, mechanism corrected)
- **B#385** — commit-precheck timeouts (pgroup-aware)
- **B#384** — BATS in Docker (principal decision)
- **B#55** — CI build-out (depends on B#384)

---

*v3.2 — Bucket F (#401, full-tree sweep) + Bucket G (#402, Great-Rename worktree integration with tool-first approach) added post-Phase-E merge. Bucket E shipped as v46.12 (PR #400 merged 2026-04-21T08:45 UTC). Captain standing duty captured: integrate worktree commits after iteration/phase/plan/seed/define/design/plan completions.*
