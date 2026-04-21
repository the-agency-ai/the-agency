# MAR Review — Plan A-B-C Stabilization (Architect Angle)

Reviewer: Plan subagent
Date: 2026-04-21
Plan reviewed: `agency/workstreams/agency/plan-abc-stabilization-20260421.md`

## Overall assessment

**Sound, with revisions recommended.** The plan's architecture and dependency reasoning are coherent, the A → B → C → Phase 5 ordering holds, and the principal-decision gates are correctly surfaced. Three concrete sequencing/granularity issues warrant revision before execution, plus two smaller couplings that should be explicitly acknowledged. The plan is not broken — none of the findings below rise to "reject" — but shipping as-written leaves avoidable friction on the table.

## Findings

### Finding 1 — granularity / bundling
**Observation:** B#388 (`git-safe add` directory rejection) and B#389 (`git-safe unstage` shell-meta handling) both edit the same tool (`agency/tools/git-safe`, confirmed as a single 17KB bash file distinct from `git-safe-commit`) and the same test file (`src/tests/tools/git-safe.bats`). They are also both trivial-to-moderate and independent from other B items. The plan treats them as separate PRs (#7 and #8 in the sequence table) and the "one PR per issue" rule as default.

**Impact:** Two PRs rebasing on the same tool source within hours of each other. Second PR inherits merge-conflict risk on `git-safe`. Reviewer cognitive load nearly doubles for what is effectively one DX-polish session. Release cadence burns two version bumps on near-trivial work. This is the clearest case in the plan where "one PR per issue" produces worse hygiene than bundling.

**Recommendation:** Bundle B#388 + B#389 into a single PR titled something like "git-safe: directory staging + shell-meta-safe unstage" with both tests. Keep the two issues as separate issues (closed by one PR). Add this as an explicit exception in the PR shape section alongside the A#393 / B#384+B#55 exceptions already listed.

**Confidence:** high

### Finding 2 — granularity / bundling
**Observation:** A#395 (`git-safe-commit --coord` flag) and A#393 (session-end handoff commit) are related by intent — A#393 will use `git-safe-commit --no-work-item` as the commit mechanism per the chosen Option 1, and A#395 adds the `--coord` flag that is exactly the right primitive for what A#393 wants to invoke. They touch *different* files (skill vs. tool) but there is a sequencing/self-consistency question: if A#395 lands first, A#393 can call `--coord` directly, which is semantically cleaner than `--no-work-item` for a coord artifact commit. Current sequence: A#393 is PR #1, A#395 is PR #3.

**Impact:** A#393 will ship invoking `--no-work-item "misc: session-end handoff"`, then within two PRs later the `--coord` flag lands, and A#393's invocation is immediately stale (works, but not idiomatic). Minor, but it's churn the plan could avoid by inverting the order.

**Recommendation:** Swap A#395 before A#393. Land the `--coord` flag first (trivial, self-contained), then consume it in the A#393 skill fix. This also produces a cleaner commit message in the session-end skill. Alternative: keep the order but have A#393's skill invocation use `--no-work-item` and accept that it will be updated in A#395's companion scope.

**Confidence:** medium (this is a preference call, not a correctness issue)

### Finding 3 — hidden coupling / companion scope
**Observation:** The plan identifies `/compact-prepare` as a "companion check" rolled into the A#393 PR if it has the same bug. I verified: `.claude/skills/compact-prepare/SKILL.md` has identical structure (Step 1 `session-pause --framing continuation`, Step 2 authoring handoff at `handoff_path`, Step 3 report). The *same bug exists*: Step 2 writes a new handoff file, and nothing commits it in the happy path where Step 1's primitive reported `handoff_commit_sha=none` (clean prior tree). The "if the same bug exists" phrasing in the plan is tentative when the answer is actually deterministic.

**Impact:** Treating `/compact-prepare` as a conditional companion understates the scope of A#393. The fix *must* land in both skills together or the next `/compact-prepare` run produces the same dirty-tree symptom. If the PR ships with only session-end patched, the next post-compact `/compact-resume` surfaces an identical failure and needs a second PR.

**Recommendation:** Re-scope A#393 explicitly as "session-end AND compact-prepare: commit the authored handoff" — not as "session-end with compact-prepare maybe." Add `/compact-prepare` SKILL.md Step 2.5 to the files list and add a BATS case covering it. Same PR, same release. This also lets A#393 assert "no Step-2-writes-but-nothing-commits" pattern is no longer present in either PAUSE-surface skill.

**Confidence:** high

### Finding 4 — sequencing / dependency
**Observation:** C#372 (release automation gap) is sequenced 4th, after all three A items. The stated rationale — "needs to land before we start doing 10+ PRs in a row without releases" — is sound. But the plan says "Deliverable is a diagnosis report first, then a targeted fix PR." This implies two deliverables (diagnosis doc + fix PR) serializing slot #4, and the plan's sequence table shows only one row for C#372. The diagnosis could also run in parallel with A#393–A#395 so the C#372 fix PR is unblocked by the time A finishes.

**Impact:** If diagnosis is serial after A, the fleet runs three more PRs with the release bug still silently firing — the exit-criteria line "Every PR fired a release (validates #372 fix)" becomes partially unfalsifiable for the A PRs. If diagnosis runs in parallel (as a background research task), the fix PR can land before any A PRs merge, and every A PR becomes a live test of the fix.

**Recommendation:** Move the *diagnosis* phase of C#372 to run in parallel with A (it is read-only research, no coupling). The *fix PR* stays at slot #4 but is pre-armed with the diagnosis. This also provides early signal on whether C#372 is simple-config or structural — informing whether B#384 and B#55 can safely run serial.

**Confidence:** high

### Finding 5 — scope-decision gate / principal fork
**Observation:** The plan correctly flags B#384 (BATS Docker) as the structural/scope-decision item with a gated go/no-go at plan review, and correctly identifies B#55 (CI build-out) as dependent on that decision. Good architecture work. However, two other items plausibly deserve similar principal-decision gates that the plan treats as decided:

- **A#394 shebang strategy** — the plan picks "re-exec inside Python" over "bash wrapper per tool" with stated rationale. This is a framework-wide convention change (every Python tool gets a 15-line bootstrap) and the plan acknowledges "factored bootstrap uses `exec(open)` is a code-quality smell." This is the kind of call that if wrong bakes in 10+ files of churn to undo.
- **B#392 detect-and-document vs. wait-for-Phase-4c** — the plan picks "fix now, don't let Phase 4c delete it." Valid, but this is an explicit rewrite-awareness call that the principal directive section (`Risks §1`) is specifically designed to trigger. It's the canonical case of "fix something Phase 5 will rewrite."

**Impact:** Not gating these means the plan walks into two design decisions under momentum. If the principal has a view on either (e.g., "bash wrappers are fine, I prefer file-count over bootstrap-per-tool" or "defer B#392 entirely, adopters can wait for Phase 4c"), catching that after merging A#394 or B#392 is expensive.

**Recommendation:** Add both to `## Open questions for principal` at the bottom of the plan:
- "A#394: confirm re-exec-inside-Python over per-tool bash wrapper — or defer shebang decision to a separate micro-plan?"
- "B#392: confirm detect-and-document now, or defer to Phase 4c (#376) and accept adopter friction until then?"

**Confidence:** medium-high

### Finding 6 — release cadence realism
**Observation:** The plan projects ~11 PRs, each firing a release per framework convention (`gh release create` after each merge). The exit criteria bar "Every PR fired a release" reinforces this. Eleven releases in one push is a high rate — even if each is mechanical, cumulative overhead (manifest bumps, release notes, tag creation, release verification) is non-trivial and interleaves with review cycles.

**Impact:** Release fatigue is real. More importantly, the plan says "Manifest bumps per PR: 46.11 → 46.12 → 46.13 → … (or squash at natural boundaries; principal's call)" — the "squash at natural boundaries" clause is already an acknowledgment that 11 releases might be excessive. Without specifying what the natural boundaries are, this becomes discretionary mid-push and adds principal decision load at every PR boundary.

**Recommendation:** Pre-specify the natural release boundaries in the plan. Candidate grouping:
- Release 1: all of A (46.11 → 46.12 for 3 merged PRs, or one release covering all of A)
- Release 2: C#372 fix
- Release 3: B trivial batch (B#383, B#385, B#388+B#389 bundled, B#392)
- Release 4: B#384 (if in-scope)
- Release 5: B#55

That's 4-5 releases for 9-11 PRs — still one-per-natural-unit but far more sustainable. Alternatively, pre-commit to one-release-per-PR and accept the overhead, but state it as a policy not a default.

**Confidence:** medium

### Finding 7 — exit criteria independence check
**Observation:** Reviewing per-bucket exit criteria for hidden couplings:
- Bucket A exit criteria are independent across A#393, A#394, A#395. Clean.
- Bucket B exit criteria mostly independent, but B#385 ("commit-precheck timeout") exit criterion "Individual test hang is killed at ≤30s and reported" couples to B#384's Docker BATS scope. If B#384 lands, the ≤30s per-test timeout is implemented via container hard-kill; if deferred, it's implemented via `timeout` subprocess. Plan mentions this in B#385 fix point #3 but the exit criteria don't reflect the branching.
- B#55 exit criterion "Runtime < 5 minutes wall-clock" couples to B#384's Docker startup overhead. If B#384 is in-scope, 5 min is tight (Docker build + BATS run).

**Impact:** Two exit criteria are soft-coupled to B#384's in/out decision. If B#384 gets deferred mid-push, B#385 and B#55 exit criteria still technically achievable but via different implementation paths than the plan implicitly assumes.

**Recommendation:** Make the coupling explicit in B#385 and B#55 exit criteria — either "timeout achieved via Docker hard-kill OR `timeout` subprocess depending on B#384 outcome" or split the exit criteria into B#384-in and B#384-out variants. Small edit, prevents "we shipped B#385 but the timeout mechanism isn't what we expected" confusion.

**Confidence:** medium

## Questions for the captain

1. Bundling B#388+B#389 (same file) — do you want this as a formal exception in the plan, or is the principal's granularity guidance stricter?
2. Is C#372 diagnosis as parallel-read-only research acceptable, or do you want to run it strictly serial for attention-focus reasons?
3. For A#394, is there an existing framework convention document (e.g., REFERENCE-PYTHON) that should be the location for the shebang-and-launcher contract, or is creating that doc part of this push?
4. Release cadence — do you want me to propose the pre-specified natural-boundary grouping, or is that a principal-level call that should go in the Open Questions list?
5. The `session-pause` primitive already force-commits the handoff on the abort path (confirmed in both SKILL.md files). A#393's Option 1 (Step 2.5 commit) handles the happy path. Should A#393 also audit whether the primitive itself could be taught to know about the post-Step-2 handoff write (Option 2), even if we don't land Option 2 in this PR? Or is that explicitly out of scope until Phase 5?

## Summary

**Change:** Bundle B#388+B#389 into one PR (same-file coupling); invert A#393 and A#395 order (clean primitive-first sequencing); re-scope A#393 to cover `/compact-prepare` deterministically rather than conditionally; run C#372 diagnosis in parallel with A so the fix PR lands before any A merges; pre-specify release-grouping boundaries instead of leaving it as mid-push discretionary.

**Keep:** The A → B → C → Phase 5 ordering is correct. The B#384 scope-gate is exactly right. The "fix things Phase 5 will rewrite, flag them in the plan" approach is sound. Risks section is honest. Open-questions list is the right mechanism — just add two more items to it (A#394 shebang strategy, B#392 defer-or-fix-now).

**Decide:** Principal go/no-go on B#384 (already gated). Add two more explicit principal gates for A#394 shebang strategy and B#392 fix-now-vs-defer. Confirm release cadence policy (one-per-PR strict vs. natural-boundary grouping). Confirm bundling exception for B#388+B#389.
