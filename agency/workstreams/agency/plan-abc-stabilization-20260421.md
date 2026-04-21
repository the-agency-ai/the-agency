---
type: plan
workstream: agency
date: 2026-04-21
day: D45
principal: jordan
captain: the-agency/jordan/captain
status: draft-v2-post-mar
supersedes: none
revision: v2 — revised from MAR
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

# Plan — A-B-C Stabilization Push (2026-04-21) — v2

## Revision log

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

## Bucket 0 — Pre-flight (NEW, must land before Bucket A)

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

### B#392 — `agency update` chicken-egg  **[MOVED EARLIER — was v1 position 9]**
**Severity:** High for adopters. **Rationale for earlier placement:** every PR this push merges produces a new version that adopters can't sync to until #392 ships. Earlier = less adopter lag.

**Fix (from v1, unchanged):** detect + document + error. Manifest-driven rewrite is Phase 4c (#376) which will preserve/subsume this.

**Principal decision** (architect F5): fix-now vs. defer to Phase 4c? Default: **fix-now** (adopter pain is real today; Phase 4c is weeks out).

**Rewrite-preservation mechanism** (expands v1's Risk 1 hand-wave):
- Include in B#392 commit message: `Phase-5-preserve: detect-and-document behavior must survive #376 manifest-driven rewrite.`
- Add to `agency/workstreams/agency/research/phase-5-preserve-list.md` — an authoritative file Phase 5 plan must read before touching `_agency-update`.
- Phase 5 plan template adds a required section: "Pre-rewrite audit — check phase-5-preserve-list.md for behaviors to carry through."

This is the mechanism architect F5 asked for.

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

## Sequencing

| # | Item | PR shape | Parallel? |
|---|------|----------|-----------|
| 0a | #339 git-captain push (bash 3.2) | Trivial fix + test | — |
| 0b | #210 dispatch artifact loop | Diagnose + fix | — |
| — | C#372 diagnosis | Research doc (no PR) | runs parallel with 0a, 0b, A |
| 1 | A#395 `--coord` flag | Tool edit + tests | — |
| 2 | A#393 session-end + compact-prepare (single PR) | Skill edits + tests (incl. integration) | — |
| 3 | A#198 session-resume raw git fix | Skill edit + test | — |
| 4 | A#199 session-preflight framework-dirty guard | Tool edit + test | — |
| 5 | A#394 Python launcher (scoped N=1) | New tool + shebang swap + tests + REFERENCE doc | — |
| 6 | C#372 fix PR | Config/workflow fix + regression assertion | depends on C#372 diagnosis |
| 7 | B#383 verify + regression test | Close or regression-test PR | verify-first |
| 8 | B#392 agency update chicken-egg | Tool edit + REFERENCE doc + test | — |
| 9 | B#388 + B#389 git-safe bundle | Tool edit + tests | — |
| 10 | B#384 Docker BATS (IF IN-SCOPE) | Dockerfile + wrapper + CI wiring | Principal go/no-go |
| 11 | B#385 commit-precheck timeouts | Tool edit + tests | depends on B#384 decision for mechanism |
| 12 | B#55 CI build-out | Workflow update | depends on B#384 decision |

**Push-level smoke ritual** runs at close of push (devex F7): `/session-end` → fresh shell → `/session-resume` → `/session-end` — verifies the incident chain is no longer reproducible.

---

## Release cadence

Pre-specified boundaries (architect F6) — 4-5 releases total instead of 11:

| Release | Covers | Rough version |
|---------|--------|---------------|
| R1 | Bucket 0 + A#395 | 46.12 |
| R2 | A#393 + A#198 + A#199 + A#394 (session + Python lifecycle) | 46.13 |
| R3 | C#372 fix (release automation restored) | 46.14 |
| R4 | B bucket (B#383 verify, B#392, B#388+B#389, B#385, [B#384 if in]) | 46.15 |
| R5 | B#55 + push-level smoke + any holdover | 46.16 |

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
| 1 | PR #397 — handle before Bucket 0? | Yes, handle before (my recommendation) |
| 2 | B#384 Docker BATS — in this push? | Principal decides |
| 3 | A#394 shebang strategy — bash launcher wrapper vs Python re-exec? | bash launcher wrapper (my pick) |
| 4 | B#392 fix-now vs defer to Phase 4c? | Fix-now (my pick) |
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
- **B#392** — agency update chicken-egg (adopter unblock)
- **B#388** — git-safe add directory support (bundled)
- **B#389** — git-safe unstage shell-meta (bundled, mechanism corrected)
- **B#385** — commit-precheck timeouts (pgroup-aware)
- **B#384** — BATS in Docker (principal decision)
- **B#55** — CI build-out (depends on B#384)

---

*v2 — revised post-MAR. Awaiting principal review + Q&A on the 11 decision points before execution.*
