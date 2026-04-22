# MAR Review — Plan A-B-C Stabilization (DevEx Angle)
Reviewer: devex subagent
Date: 2026-04-21

## Overall assessment

**Needs revision.** The plan is directionally sound and the sequencing is defensible. Bucket A items are well-specified and low-risk. Bucket B items are well-scoped individually. But the plan has real gaps in three places: (1) test coverage for A#393 is insufficient (unit-level BATS alone misses the bug class that caused the incident), (2) A#394 test strategy ("mocked PATH") will miss the real failure modes, and (3) the plan has no push-level observability/smoke gate that would catch a regression of the exact incident that triggered this push. Fix these and the plan is executable.

## Findings

### F1 — A#393 test strategy is too narrow; misses the actual failure mode class

**Observation.** The proposed BATS test is "verify post-skill tree state is clean." That test would pass if Step 2.5 commits *anything*, including an empty commit. It would also pass on a successful `/session-end` run, but it wouldn't catch the failure mode that actually caused the incident — the end-to-end cycle `/session-end` → shell exits → new shell → `/session-resume` → confirms clean pickup.

The root cause wasn't "the skill leaves dirt in the tree" — it was "the skill's claim in its frontmatter description (`Leaves a clean working tree`) doesn't match its behavior, and the next session bounces off dirt." A test that exercises only the skill in isolation confirms neither the cycle nor the frontmatter contract.

Worth noting: `session-pause` already has a handoff force-commit path at line 351–367 — but it only fires on the abort path (when non-coord framework code is also dirty). The common case (only handoff dirty) is exactly what's broken. So the Step 2.5 fix is correct, but the test must drive the common case.

**Impact.** High. A passing BATS assertion on an isolated skill run is a weak gate. The test suite will green, but the next `/session-resume` incident will still happen on a different seam we didn't anticipate.

**Recommendation.**
1. Keep the proposed BATS test (post-skill `git status` clean, handoff frontmatter matches `mode: resumption`).
2. **Add an integration test** that runs the full PAUSE → new-shell-simulated PICKUP cycle. BATS can do this — fork a new bash process, set `$CLAUDE_PROJECT_DIR` to a test fixture repo, run session-pause + handoff write + session-pickup, assert pickup succeeds without "dirty tree" warning.
3. **Add a contract test** that validates every skill's `description:` frontmatter against a behavioral predicate. If a skill says "leaves a clean tree," a test at `src/tests/skills/contract.bats` should actually verify that in a sandbox. This is the class fix — the D45 incident was a skill-claim-vs-behavior drift, and we have 80+ skills with no such gate.

**Confidence:** High on points 1–2. Medium on point 3 (bigger scope; principal may scope-limit).

---

### F2 — A#394 "mocked PATH" test will miss the real-world failure modes

**Observation.** The plan says "BATS test covers launcher behavior on mocked PATH." A PATH mock tests the branch logic (picks `python3.13` before `python3.14`, falls through to `python3` last). It does **not** exercise the actual failure modes that triggered the incident:

- `python3` resolves to `/usr/bin/python3` (Apple-stock 3.9) because `brew link` was never run.
- `python3.13` symlink exists in `/opt/homebrew/bin` but is not on the user's PATH because brew PATH-injection fell out of their shell rc.
- brew `python@3.13` installed but unlinked (`brew install python@3.13` without `--force` on a system that already had python3 linked from an older version).
- pyenv shim points at 3.11; `python3.13` not installed under pyenv.
- Corporate-managed laptop with both Apple-stock and an IT-managed `/opt/python3.13` and conflicting PATH ordering.

A mock-PATH test confirms correctness in a hermetic sandbox but doesn't catch any of these. The real-world modes all involve interactions between brew/pyenv/Apple-stock/shell-rc state.

**Impact.** High. The whole reason this bug surfaced is that the runtime guard passed unit-test muster but dies on a very common install profile. We'll ship a "tested" launcher that has the same gap if we only test the mock.

**Recommendation.**
1. Keep the mocked-PATH BATS test — it's valuable for branch coverage.
2. **Add a matrix test** that runs in Docker (leverages B#384 if that's in) against a set of staged install profiles: (a) `/usr/bin/python3` → 3.9 + brew python@3.13 linked, (b) apple-stock only, (c) brew python@3.13 unlinked, (d) pyenv-shim + brew stacked. Each matrix cell validates either "launcher finds 3.13 and execs" or "launcher emits the remediation message." This ties A#394 to B#384 as a reason to do B#384.
3. **Add a real-world smoke** as part of CI on macOS runner: just run `dispatch-monitor --help` and confirm exit 0. If the runner's Python setup isn't 3.13+, the smoke should verify the launcher's remediation message fires. This catches the "launcher silently picks wrong python" mode.
4. **Document the launcher contract** in REFERENCE-PYTHON (the plan mentions this; reinforce that the doc must include the PATH-resolution order and a table of "what happens if X install profile").

**Confidence:** High. This is a shibboleth — if we only test with mocks, we'll re-run the same incident.

---

### F3 — B#385 commit-precheck timeout plan misses edge cases

**Observation.** The plan proposes (1) cap total timeout at 5 min, (2) per-test timeout via `timeout 30 bats <file>`. Both are correct directional moves. But the plan misses:

- **Tests that spawn subprocesses** (e.g., anything that shells to `git-safe-commit` which runs its own subprocess). A per-test `timeout 30 bats <file>` kills the bats parent but not necessarily the whole process group. The existing `run_with_timeout` in `commit-precheck` line 89–109 *does* use `--kill-after=5` and process-group kill — but only for the outer bats invocation, not for per-test. If per-test timeout is added, it needs the same pgroup-kill discipline.
- **Tests that use `BATS_TEST_TMPDIR`** — BATS sets this as an auto-cleaned tmpdir. If a test hangs and gets SIGKILL'd, BATS may not run its cleanup hook, leaving stale tmpdirs across runs. Not catastrophic but accumulates.
- **Tests that use `setup_file` / `teardown_file`** — these run once per file. If a file-level setup hangs, per-test timeout doesn't fire because no test has started yet. Need either file-level timeout or BATS `--timing --jobs` flag (which BATS 1.9+ supports, `--jobs 1` serialized with per-test SIGTERM).
- **Tests that intentionally wait** — any test that polls for a condition (e.g., monitor-register tests that wait for SIGTERM propagation). These legitimately need >30s in some cases. The fix: per-test timeout should be tunable at file level via a BATS variable (e.g., `BATS_PER_TEST_TIMEOUT=60` in the file's `setup_file`).

**Impact.** Medium. The plan as-stated would likely ship a fix that's better than today but leaves the hang-via-subprocess-orphan mode unfixed. Since that was arguably the trigger (630s bats hang leading to `--no-verify` bypass), this matters.

**Recommendation.**
1. Add to the plan: per-test timeout must use process-group kill (match existing `run_with_timeout` discipline).
2. Add a BATS test that explicitly tests commit-precheck behavior against a test file that hangs in `setup_file` — verifies the timeout fires at file level, not just test level.
3. Add a BATS test that exercises a test spawning a subprocess that outlives it — verifies the whole process tree dies.
4. Document the per-test timeout override mechanism in the commit-precheck docblock.

**Confidence:** Medium-high. Specific claim: without process-group discipline at per-test level, this fix will still hang on certain tests (just faster — 30s per hang instead of 630s once).

---

### F4 — A#395 `--coord` flag adds cognitive tax; worth the trade but call it out

**Observation.** The plan treats `--coord` as a simple ergonomics win. From a DevEx perspective, it's a mild cognitive tax: now there are three ways to commit coord artifacts:
- `/coord-commit` skill (discoverable via `/` autocomplete).
- `./agency/tools/git-safe-commit "msg" --no-work-item` (existing primitive).
- `./agency/tools/git-safe-commit "msg" --coord` (new alias).

Three ways to do the same thing is the "seven ways to start emacs" problem. BUT — the principal's observation is real: agents reach for `--coord` naturally by pattern-matching from `/coord-commit`. That's an affordance signal.

The question isn't "should we add the flag" — it's "should `--no-work-item` be deprecated in favor of `--coord`?" If `--coord` is strictly more specific (implies `--no-work-item` + validates coord-only + uses `misc:` prefix), then `--no-work-item` becomes the lower-level escape hatch and `--coord` the default.

**Impact.** Low-medium. Not critical but we're adding a new surface without retiring an old one. Historically that accumulates.

**Recommendation.**
1. Add `--coord` as proposed.
2. Make the tool docblock explicit about when to use which: `--coord` for coord artifacts (default), `--no-work-item` as the raw escape hatch (rare, power-user).
3. Add a deprecation note to `--no-work-item` if `--coord` covers all known use cases — or confirm a case where `--no-work-item` without `--coord` is still required (e.g., non-coord work that legitimately skips work-item binding).
4. **Have `/coord-commit` skill use `--coord` internally** — if the skill invokes the tool, agents reading the skill see `--coord` in the command and learn it. Consistency reinforces the affordance.

**Confidence:** Medium. This is a judgment call — I think the plan's instinct is right, it just needs a deprecation/consolidation path or the surfaces will accumulate.

---

### F5 — B#388 and B#389 are the right abstractions; B#389's `git update-index --force-remove -z --stdin` is NOT quite right

**Observation.** The plan proposes `git update-index --force-remove -z --stdin` for B#389 (git-safe unstage with shell-meta filenames). That's not the right incantation.

`--force-remove` on `update-index` **removes the entry from the index entirely** — even if the file exists on disk, the entry is gone. That's equivalent to `git rm --cached`, not `git reset HEAD -- <file>`.

For unstaging (the intent — "take this file back out of the staging area but keep it tracked if it was tracked in HEAD, or remove it from index if it was newly staged"), the correct primitive is one of:

- `git restore --staged --pathspec-from-file=- --pathspec-file-nul` (modern, `-z` NUL-separated paths from stdin). Git 2.23+.
- `git reset HEAD -- "$file"` with argv-safe quoting (the existing approach, just fix the quoting).

The current `git-safe unstage` at line 405–419 already uses argv passthrough (`git reset HEAD -- "$@"`) — the problem isn't shell expansion, it's the input-validation layer (lines 408–414) that refuses filenames with shell-meta characters. The fix is to **loosen the validation** so filenames with newlines/quotes/etc. pass through, because the downstream `git reset HEAD --` handles them correctly via argv.

B#389's actual fix is: keep the argv-safe approach, but drop the over-aggressive input validation. Or, if principal wants a NUL-safe stdin pipe (for really pathological cases), use `git restore --staged --pathspec-from-file=- --pathspec-file-nul <<< <NUL-joined paths>`.

**Impact.** Medium. The plan as-written would either (a) silently destroy index state by using `--force-remove` semantics or (b) confuse the reviewer who knows the difference. This is a correctness issue, not ergonomics.

**Recommendation.**
1. Change B#389 fix target from `git update-index --force-remove -z --stdin` to `git restore --staged --pathspec-from-file=- --pathspec-file-nul` OR to "loosen input validation; `git reset HEAD -- "$@"` already handles argv correctly."
2. Add a BATS test with literal-newline filename + quote filename. Verify that post-unstage, `git diff --cached` shows the file gone from index AND the file still exists in working tree (that's the whole difference from `--force-remove`).
3. Include a link to the existing code in the fix description — the validation is the bug, not the subprocess shape.

On B#388: the proposed `--dir` flag is the right abstraction. Option (a) cleaner than (b) — interactive confirms don't work well in agent-invoked contexts.

**Confidence:** High on B#389 correctness point (the mechanic is wrong). High on B#388 recommendation.

---

### F6 — Risk 4 mitigation (A#394 shebang sweep) needs observability, not just "pilot then sweep"

**Observation.** "Pilot then sweep" catches mechanical regressions (wrong path, bad re-exec). It doesn't catch **behavioral** regressions — a tool that worked on the old shebang but now has subtle startup-time issues, or a tool whose imports are order-dependent in a way that re-exec disturbs.

**Impact.** Medium. Framework tools are called during critical sessions. A regression that fires only at dispatch-monitor + Monitor-tool + real sessions would be discovered days later.

**Recommendation.**
1. Before the sweep, generate a baseline: for every Python tool, capture `<tool> --help` exit code + checksum of output. After the sweep, re-run; diff must be empty.
2. Generate a **startup-latency baseline** (time `<tool> --help`). After sweep, assert no individual tool regressed >50ms.
3. Wire this into a BATS test file `src/tests/tools/py-shebang-parity.bats` that can be re-run post-sweep and becomes a regression guard.
4. Pilot tool choice: `dispatch-monitor` is right (it's the visible incident). But also pilot a **quieter** tool (one without runtime guard sensitivity, e.g., `iscp-check`) to catch re-exec subtleties that dispatch-monitor's signal-handling might mask.

**Confidence:** Medium. Adds effort but is genuinely valuable for a cross-cutting sweep.

---

### F7 — No push-level smoke / observability gate

**Observation.** The plan's exit criteria list is a checklist of individual items. What's missing is a **push-level verification** that exercises the exact incident chain end-to-end: `/session-end` → new shell → `/session-resume` → check-in with dispatches → `/session-end` again. If that cycle works cleanly on the host that triggered this push, the push delivered its goal. If it doesn't, something regressed.

This isn't a test — it's a smoke ritual at push close. Could be:
- A bash script `src/tests/smoke/session-lifecycle.sh` that agents run manually or CI runs on every push.
- A new skill `/push-verify` that exercises the cycle and reports per-item status.
- Added to `/agency-health`'s existing checks.

**Impact.** Medium-high. Without this, we're trusting that N individually-green items compose correctly.

**Recommendation.**
1. Add an exit criterion to the push: "smoke ritual passes on the dev host" — even if smoke is a manual checklist.
2. Post-push, codify as a scripted smoke. Could be as simple as:
   - Run `/session-end`, assert tree clean.
   - Simulate new session, run `/session-resume`, assert no "dirty tree" warning.
   - Run `dispatch-monitor` for 5s, assert exit code 0.
   - Run `git-safe-commit --coord` on a trivial coord artifact, assert success.
3. Fold this into `agency-health` as a new tier (`--full` or `--smoke`).

**Confidence:** High on value. Medium on scope — could be scope-limited to "manual smoke checklist" for this push, codified in a follow-up.

---

## Test coverage gaps

Consolidated from findings above:

| Item | Proposed test | Gap | Needed addition |
|------|---------------|-----|-----------------|
| A#393 session-end | Post-skill `git status` clean | Doesn't exercise the PAUSE→PICKUP cycle | Integration test; skill contract test across all skills |
| A#394 _py-launcher | Mocked PATH | Doesn't catch real-world install profiles (apple-stock + brew + pyenv interactions) | Matrix test in Docker; real-world CI smoke |
| B#385 commit-precheck | Not specified in plan | Missing pgroup-kill for per-test timeout; missing subprocess-orphan case; missing setup_file hang | BATS cases for each class |
| B#388 git-safe add | "Test cases (flag accepted, validates coord-only...)" — that's A#395's test, not B#388's | B#388's test spec is missing | Specify: directory-level add with `--dir`, with sensitive pattern, without flag rejects |
| B#389 git-safe unstage | "Test case with embedded newline/quote in filename" | Correct class of test BUT mechanic is wrong (see F5) | Test must verify file STAYS in working tree post-unstage |
| A#395 --coord flag | Flag accepted + validates coord-only | Missing: test that `/coord-commit` skill internally uses `--coord` (if we make that consolidation) | Add if consolidation path adopted |
| C#372 release gap | Not specified; diagnosis-first | Post-fix: missing regression monitor | Add a CI assertion that every merged PR produced a release tag within N minutes |
| Push-level | None | No end-to-end smoke | Session-lifecycle smoke script or skill |

## Tool discipline concerns

Two concerns, one of which is resolvable and one of which is a watchpoint:

**Concern 1 (resolvable): B#389 proposes a mechanic that's not the right tool.** `git update-index --force-remove` is not equivalent to `git reset HEAD --`. Using it would be a subtle violation of "use the right primitive for the job." The existing `cmd_unstage` at line 405–419 already uses the correct primitive — the fix is to loosen input validation, not to switch primitives. See F5.

**Concern 2 (watchpoint): A#395 `--coord` flag risks surface accumulation.** `/coord-commit` skill + `git-safe-commit --coord` flag + `git-safe-commit --no-work-item` flag is three affordances for the same operation. The plan doesn't pick a canonical path. Without a deprecation plan, agents reading old handoffs will use `--no-work-item`, new agents will use `--coord`, the skill will continue to exist — three docs to maintain, three patterns to test. This is how surfaces accumulate. See F4.

**Not a concern but worth noting:** The plan preserves "route through the skill, not the tool" correctly in most places. Session-end correctly shells to `session-pause`, session-resume shells to `session-pickup`. The fix for A#393 correctly adds to the skill (Step 2.5), not to the primitive (keeps the primitive small). That's right.

## Questions for the captain

1. **F1 — skill contract test.** Should we add a skill-contract test suite (frontmatter claims vs behavior) as part of this push, or scope it out to a follow-up? It's class-fix work but it's the real lesson from the D45 incident.

2. **F2 — docker matrix test for A#394.** Does this bind A#394 to B#384 (Docker BATS)? If B#384 is deferred, we need an alternative matrix host (vagrant? GitHub Actions matrix?). Principal's call on whether to accept that coupling.

3. **F3 — per-test timeout override mechanism.** Some tests legitimately need >30s (monitor tests, integration tests). Proposed override is a file-level BATS var. OK, or do we push hard on the 30s cap and fix the tests that don't fit?

4. **F4 — `--no-work-item` deprecation.** Are you willing to deprecate `--no-work-item` (keep it working, mark it as the raw escape hatch) in favor of `--coord` as the canonical coord-commit path? If not, we should at minimum document the distinction.

5. **F5 — B#389 correct fix is "loosen validation," not new subprocess shape.** Confirm: the right fix is to allow newlines/quotes through input validation, because the existing `git reset HEAD -- "$@"` handles argv-safe passthrough. Not switching to `update-index --force-remove`.

6. **F7 — push-level smoke.** Is a manual smoke checklist acceptable for this push's exit criteria, with codification as a follow-up? Or do we want a scripted smoke in-scope?

## Summary

The plan is sound in structure and sequencing. It correctly sizes items (A = trivial, B = moderate, C = diagnosis-first). It correctly scopes out Phase 5 rewrites and issue triage.

The revisions needed are concentrated on **test strategy rigor**:
- A#393 needs the PAUSE→PICKUP cycle test, not just a post-skill assertion.
- A#394 needs real install-profile coverage, not just mocked PATH.
- B#385 needs per-test pgroup-kill discipline and setup_file timeout handling.
- B#389 has a mechanic error in the proposed fix (F5 — important to catch before implementation).
- The push lacks a session-lifecycle smoke that would detect regression of the exact incident.

**Top concern:** F5 — B#389's proposed mechanic (`git update-index --force-remove -z --stdin`) is not equivalent to the current `git reset HEAD --` semantics. Implementing as proposed would be a regression, not a fix. Must be corrected before execution.

Close second: F2 — "mocked PATH" test for A#394 will ship a green test on a launcher that still fails on the install profile that triggered the incident. Real-world matrix is the only honest test.

**Total findings:** 7 (F1 high-impact, F2 high, F3 medium-high, F4 medium, F5 high correctness, F6 medium, F7 medium-high).

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
