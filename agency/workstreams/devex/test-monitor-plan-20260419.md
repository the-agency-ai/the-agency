---
type: plan
project: test-monitor
workstream: devex
date: 2026-04-19
status: draft
seeds:
  - agency/workstreams/devex/test-monitor-pvr-20260417.md
  - agency/workstreams/devex/test-monitor-ad-20260419.md
build_order: UC1 → UC3 → /quality-gate rewire → UC2 (PVR Q9, A&D Downstream)
---

# Plan: test-monitor v1

Implementation plan for the test-monitor + test-watch tool family. Five iterations, each ending at an **iteration-complete** QG gate. Phase gate at the end (pr-prep).

Build order is fixed by PVR Q9: **UC1 → UC3 → `/quality-gate` rewire → UC2**. UC2 (test-watch) is the natural carve-off point — if complexity blows up, ship v1 without it and file a follow-on issue.

---

## Iteration 1 — test-monitor core (UC1 minimum viable)

**Goal:** Ship `test-monitor` single-run with BATS suite support only. Single suite, clean exit, `[TEST …]` line emission. Monitor-tool compatible. No triggers. No multi-framework. No state persistence.

### Entry criteria
- A&D draft-v2 committed (done — `241b4727`)
- `agency/tools/lib/` directory does not exist (this iteration creates it)

### Files created
- `agency/tools/test-monitor` — Python executable, ~600–700 LOC (per Plan-MAR R1#3 realistic estimate)
  - Shebang + version guard (stdout emission per MAR-H4)
  - argparse CLI (`--suite`, `--verbose`, `--timeout SEC`, `--help`, `--version`)
  - `--timeout SEC` default 0 (no timeout); on non-zero, subprocess killed on expiry + `[TEST ERROR]` + exit 2 (draft-v3 fix for MAR-Adv-L6). Owned by Iter 1 because it has no state-file dependency.
  - REPO_ROOT resolution via git-safe (MAR-H5)
  - agency.yaml loader (simple line-regex parser, matches test-run convention)
  - Framework detection (command substring match)
  - Subprocess launch (`shell=True`, `CI=1` env, stdout line-buffered)
  - Parser dispatch → `bats` parser
  - Event emission: SUITE_START, CASE_FAIL, SUITE_DONE, RUN_DONE, ERROR
  - Silent on pass except SUITE_START/SUITE_DONE (FR1)
  - Parser drift fallback: RAW passthrough + RUN_DONE still emits (MAR-H2)
  - Subprocess cleanup in finally (MAR-M8)
  - Signal handlers (SIGINT/SIGTERM clean exit; SIGPIPE SIG_DFL per MAR-L4)
  - `[TEST ERROR]` emissions with path redaction (MAR-L1)
  - **`fcntl.flock` NOT in Iter 1** — deferred to Iter 3 (where state file is created). Iter 1 has no persistence per §2.4, so there's no file to lock. (Plan-MAR F2 correction.)
- `agency/tools/lib/__init__.py` — empty marker
- `agency/tools/lib/test_parsers/__init__.py` — package + Framework enum + detect() + registry dispatch
- `agency/tools/lib/test_parsers/bats.py` — TAP parser; feed()/flush() interface returning events
- `agency/hookify/<rule-name>.md` — new hookify rule: block pip imports in `agency/tools/lib/` (ZERO-PIP enforcement per A&D §5.2; Plan-MAR F8). Rule pattern: match non-stdlib imports in `agency/tools/lib/**/*.py` and block with guidance.
- `src/tests/tools/test-monitor.bats` — CLI smoke + BATS integration test
  - `test-monitor --version` → prints version, exits 0
  - `test-monitor --help` → prints usage
  - `test-monitor --suite nonexistent` → `[TEST ERROR]` + exit 2
  - `test-monitor` with a passing BATS suite fixture → expected SUITE_DONE + RUN_DONE
  - `test-monitor` with a failing BATS suite → CASE_FAIL lines + exit 1
  - `test-monitor` with missing `bats` binary (PATH=.) → `[TEST ERROR]` + exit 2
- `src/tests/python/test_parsers/test_bats.py` — stdlib unittest
  - fixture: 5 passing cases → expected event sequence
  - fixture: mixed pass/fail → CASE_FAIL locations extracted
  - fixture: malformed TAP → ParseError raised
  - fixture: YAML body on failure → reason + body_truncated populated

### Files modified
- `agency/config/agency.yaml` — ensure `testing.suites.tools` exists (it does already); no schema change yet
- `src/tests/tools/fixtures/test-monitor/` — new directory with BATS fixture suites (`passing.bats`, `failing.bats`, `malformed.bats`)

### Critical design points (from A&D)

- **shell=True** for subprocess (§4.2) — matches test-run trust model
- **UTC everywhere** for timestamps (§2.1, §4.1) — even though this iteration has no persistence, the habit starts here
- **sys.path insert** for lib imports (§5.2) — `sys.path.insert(0, str(Path(__file__).parent / "lib"))`
- **Stream, don't buffer** — iterate `proc.stdout` line-by-line, don't read all
- **Line-buffered stdout** — `sys.stdout.reconfigure(line_buffering=True)` at startup

### Tests — coverage targets

| Layer | Target | How |
|-------|--------|-----|
| BATS parser unit | 90%+ | Python unittest + TAP fixtures |
| CLI integration | All flags + error paths | BATS suite invoking test-monitor as subprocess |
| Parser drift fallback | RUN_DONE still emits on ParseError | Python unittest with mocked parser |
| Signal handling | SIGINT/SIGTERM/SIGPIPE | BATS helper `bats_kill_and_wait`: spawn test-monitor in background, `sleep` to let it reach steady state, `kill -TERM $PID`, `wait $PID`, assert exit code + state file contents (Plan-MAR F4 standard harness) |
| Never-silent | Every error path emits `[TEST ERROR]` | Audit of all exit paths in code review + BATS test forcing each error path |
| `--timeout` | Subprocess killed on expiry; exit 2 | BATS fixture suite that sleeps 5s; invoke with `--timeout 2`; assert exit 2 and `[TEST ERROR] timed out` line within 3s wall-clock |

### Exit criteria

1. `./agency/tools/test-monitor` runs the `tools` BATS suite end-to-end, emits correct event sequence (specific: `[TEST tools] suite started (bats, ~N tests)`, per-case `FAIL` lines for known-failing fixtures, `[TEST tools] suite done — X pass, Y fail, Z skip, Ts`, final `[TEST] run complete — … exit E`)
2. All tests pass — `bats src/tests/tools/test-monitor.bats` exits 0; `python3 -m unittest discover src/tests/python/test_parsers/` exits 0
3. MAR review on the diff — 2 reviewer agents in parallel, three-bucket disposition (Disagree-with-reasoning / Autonomous / Collaborative); **any Collaborative finding surfaces to principal before iteration-complete**; Autonomous findings fixed in-iteration; Disagree items documented
4. iteration-complete QG passes — receipt signed via `receipt-sign`
5. No untracked files except the recursive commit-dispatch artifact

### Estimated scope

~600–700 LOC per Plan-MAR R1#3 realistic estimate. Breakdown:
- tool + lib (~400 LOC)
- 3 BATS fixture suites (~100 LOC)
- BATS integration tests (~120 LOC)
- Python unittest fixtures (~80 LOC)

One-to-1.5 sessions. If scope blows past session budget, surface to principal.

---

## Iteration 2 — vitest + XCTest parsers

**Goal:** Extend test-monitor to handle vitest and XCTest suites via per-framework parser modules. Validates the plugin model (A&D §5.2). After this, all three v1-required frameworks (PVR FR6) work.

### Entry criteria
- Iteration 1 complete and committed

### Files created
- `agency/tools/lib/test_parsers/vitest.py` — parser for `CI=1` vitest reporter output
- `agency/tools/lib/test_parsers/xctest.py` — parser for `swift test` output
- `src/tests/python/test_parsers/test_vitest.py` — fixture-based unit tests
- `src/tests/python/test_parsers/test_xctest.py` — fixture-based unit tests
- `src/tests/tools/fixtures/test-monitor/vitest-*` — vitest output fixtures (captured real output)
- `src/tests/tools/fixtures/test-monitor/xctest-*` — XCTest output fixtures

### Files modified
- `agency/tools/lib/test_parsers/__init__.py` — register vitest, xctest in framework detection
- `src/tests/tools/test-monitor.bats` — add integration cases for vitest + mdpal suites

### Critical design points

- **vitest:** `CI=1` makes the default reporter emit one line per test file with pass/fail summary + a final summary block. Parse that. Fall back to RAW if format shifts (MAR-H2).
- **XCTest:** `swift test` emits `Test Case '-[ClassName testName]' started`, `… passed (X.Y seconds)`, `… failed (X.Y seconds)`. Regex + accumulator.
- **Real fixtures**, not synthetic. Capture from actual test runs. Store in `src/tests/tools/fixtures/test-monitor/` with a README explaining source + vitest/Swift version at capture time.

### Exit criteria

1. `test-monitor --suite mdpal` emits correct events for Swift XCTest output
2. `test-monitor --suite <vitest-suite>` emits correct events (if we have a vitest suite registered — the agency doesn't; use the `test/test-agency-project/` fixture or a dedicated test vitest suite)
3. All parser unit tests pass
4. MAR review + iteration-complete QG + receipt

### Estimated scope

~250 LOC (two parsers + tests + fixtures). One session.

---

## Iteration 3 — --trigger-on (UC3)

**Goal:** Ship `--trigger-on green|red|change` + `--trigger-to ADDR`. Dispatch/flag emission on run completion. Rate limiting (§5.7) and circuit breaker.

### Entry criteria
- Iteration 2 complete
- Verify `agency/data/` is in `.gitignore` (Plan-MAR R1#9, F9). If not, add as first change of this iteration.

### Files created
- `agency/data/test-monitor/` — directory (gitignored — should verify `agency/data/` is already gitignored)
- `src/tests/python/test_trigger_dedup.py` — unit tests for run_signature computation + dedup logic
- `src/tests/tools/fixtures/test-monitor/trigger-*` — test fixtures for green/red/change dispatch bodies

### Files modified
- `agency/tools/test-monitor` — add:
  - `--trigger-on {green,red,change}` argparse option
  - `--trigger-to ADDR` argparse option — **REQUIRED when --trigger-on is set** (A&D §3.1 draft-v3). argparse cross-validation raises if `--trigger-on` given without `--trigger-to`. No default.
  - (`--timeout SEC` already shipped in Iter 1)
  - run_signature computation (sha256 of sorted failure signatures)
  - Unified state file `<suite>.state` (A&D §2.4 + §5.7 draft-v3) — holds last_outcome, last_failure_signatures, last_green_head, last_trigger_type, last_trigger_signature, last_trigger_at. One file, one schema.
  - **`fcntl.flock(LOCK_EX | LOCK_NB)` introduced here** (not Iter 1 — no state file there, per Plan-MAR F2). Acquired at state-file open; second concurrent process for same suite emits `[TEST ERROR]` + exit 2.
  - Dedup check (§5.7): skip dispatch if same signature as last trigger of same type
  - Circuit breaker: 3 consecutive dispatch failures → disable for run
  - YAML body emission with block scalars (MAR-M6, §8.3)
  - Dispatch subprocess invocation: `./agency/tools/dispatch create --type test-failure --priority ... --to ... --body ...`
  - Flag subprocess invocation: `./agency/tools/flag new "..."`

- `src/tests/tools/test-monitor.bats` — add cases:
  - `--trigger-on red` without `--trigger-to` → exits 2 at argparse (A&D draft-v3 §7 #20)
  - `--trigger-on red --trigger-to captain` on failing suite → dispatch file created in `usr/jordan/devex/dispatches/`
  - `--trigger-on red --trigger-to captain` twice with same failures → second suppressed (dedup)
  - `--trigger-on red --trigger-to captain` with changed failures → second fires
  - `--trigger-on green --trigger-to captain` on passing suite → commit-ready dispatch
  - `--trigger-on change --trigger-to captain` → flag emission on outcome change
  - Circuit breaker: simulate 3 dispatch failures (via mocked dispatch tool) → subsequent attempts skip
  - (`--timeout 2` test already in Iter 1)
  - fcntl lock: launch first test-monitor with `--timeout 10` on a fixture suite that sleeps 8s (first holds the lock for a bounded window per Plan-MAR F5); launch second test-monitor for same suite 1s later → second exits 2 with `state file locked` error within ~1s; first completes normally at 8s

### Critical design points

- **YAML emission is hand-built** (not `yaml.dump`) per §8.3. Write a small helper `_emit_yaml_block_scalar(key, value)` that escapes user content via block scalar literal syntax.
- **run_signature** is stable across runs — sorted tuple of FailureSignature hashes.
- **Circuit breaker is per-run**, not persistent — reset at next invocation.
- **`.last-trigger` file format** is part of §2.4 unified state (not a separate file)? Revisit: actually §5.7 says `.last-trigger` is separate from `<suite>.state`. Let me align: **merge into `<suite>.state`** — one file per suite, contains last_outcome + last_trigger. Simpler and MAR-M2 correct.

### A&D alignment (resolved in draft-v3)

A&D §2.4 and §5.7 now agree: one unified `<suite>.state` file contains both the outcome/signature fields (for watch transitions) AND the trigger dedup fields. No separate `.last-trigger` file. Plan-MAR F1/R1#2 fixed in draft-v3.

### Tests — coverage targets

| Layer | Target | How |
|-------|--------|-----|
| run_signature stability | Same failures → same signature across runs | unittest with fixed inputs |
| Dedup logic | Same signature → suppressed; different → dispatched | unittest mocking file IO |
| Circuit breaker | 3 fails → disabled; next invocation resets | BATS test with mocked dispatch |
| YAML emission safety | Reason with `\n`, `---`, `!!str` → valid YAML, extracts back correctly | unittest roundtrip |
| Dispatch address resolution | Unknown addr → ERROR line | BATS test with bogus `--trigger-to` |

### Exit criteria

1. All three `--trigger-on` modes emit correct artifacts (dispatch for red/green, flag for change)
2. Dedup prevents duplicate dispatches on unchanged failure sets
3. Circuit breaker works as specified
4. YAML roundtrip tests pass (emit + re-parse → same data)
5. MAR + iteration-complete + receipt

### Estimated scope

~200 LOC (trigger logic + state file + YAML helper + tests). One session.

---

## Iteration 4 — /quality-gate Step 8 rewire + agency.yaml schema

**Goal:** Rewire `/quality-gate` skill Step 8 to detect and use test-monitor. Add `testing.monitor` flag to agency.yaml schema. Backward-compat fallback to test-run.

### Entry criteria
- Iterations 1-3 complete (test-monitor with --trigger-on works end-to-end)

### Files modified
- `.claude/skills/quality-gate/SKILL.md` — Step 8 text updated:
  - Detection logic (tool exists + `testing.monitor: true`)
  - Monitor tool invocation instruction
  - Line-match for `^\[TEST\] run complete`
  - Parse exit code from the line
  - Fallback to `./agency/tools/test-run` if either condition false
- `agency/config/agency.yaml` — add `testing.monitor: true` (opt-in for the-agency repo; other adopters stay opted out)
- `agency/templates/agency.yaml.template` (if it exists) — add `testing.monitor: false` as default with comment

### Files created
- `src/tests/tools/quality-gate-step8.bats` — integration tests verifying:
  - Step 8 picks up Monitor mode when both conditions true
  - Step 8 falls back to test-run when `testing.monitor: false`
  - Step 8 falls back when test-monitor is missing (simulate by temp-rename)
- `agency/docs/test-monitor-adoption.md` (OR inline in agency.yaml commentary) — adopter guide: "flip `testing.monitor: true` after `agency update` brings in test-monitor"

### Critical design points

- The skill is a Markdown document — the "rewire" is text that instructs the agent. No Python/bash runtime code in the skill itself. The agent reads the skill, checks the files, constructs the Monitor tool call.
- **Ref-injector** (per CLAUDE-THEAGENCY.md) — the skill already injects `REFERENCE-QUALITY-GATE.md`. We don't need a new injected doc; the Step 8 change is self-contained in the skill.
- **Test coverage** is via BATS tests that simulate the skill's logic — we can't directly test a Markdown skill, so we test the contract (the agent would check these files, invoke these tools).

### Exit criteria

1. `/quality-gate` skill prose contains all required anchors (Plan-MAR F6): `test-monitor`, `testing.monitor`, `test-run` fallback, `\[TEST\] run complete` line-match pattern. Verified via `grep` assertions in BATS.
2. Both branches work: Monitor-mode on `testing.monitor: true`, sync fallback otherwise. Verified by BATS tests that simulate the agent's contract (check files, construct expected invocation string).
3. **Manual verification (not automated):** one reviewer agent reads the updated skill and predicts the Monitor invocation from the prose alone, confirms it matches intent. Documented in iteration-complete QGR as "manual skill-prose verification: PASS."
4. Adopter guide exists (in agency.yaml or a separate doc)
5. `test-run` is not modified (fallback preserves existing behavior 1:1 — diff check)
6. MAR + iteration-complete + receipt

### Estimated scope

~50–80 LOC (skill edits + template tweaks + BATS tests + grep-anchor verification). Half-session.

### Honest testability note (Plan-MAR F6)

Markdown skill files cannot be unit-tested — an agent reads the prose at runtime and constructs behavior from it. Our verification strategy has three layers: (a) **prose-anchor grep** (the skill text contains the expected keywords/patterns); (b) **contract BATS tests** (files and flags the skill references actually exist and behave as the skill claims); (c) **manual reviewer pass** (an agent reads the skill and describes what it would do). Layers (a) and (b) are automated; layer (c) is the irreducible manual gate.

---

## Iteration 5 — test-watch (UC2)

**Goal:** Ship `test-watch` file-watch loop. Long-lived process. Transition-only emission. State persistence. Silent on stable.

### Entry criteria
- Iteration 4 complete (test-monitor is fully functional and QG uses it)
- **Carve-off decision point:** if preceding iterations burned budget or surfaced complexity, test-watch can be cut from v1 and moved to a separate PR. PVR Q9 anticipates this. Principal makes the call at this gate.

### Files created
- `agency/tools/test-watch` — Python executable, ~250 LOC
  - argparse (`--suite` required, `--interval`, `--debounce`, `--help`, `--version`)
  - State file read/write (YAML, atomic writes, MAR-M2 unified schema)
  - File-watch loop (§5.5 corrected algorithm with lstat + MAX_SNAPSHOT + quiet_since debounce)
  - Watch-path resolution (explicit from agency.yaml OR inferred per framework OR repo-root default)
  - Subprocess invocation of test-monitor per run cycle
  - Transition detection (§2.1 rules — silent on GREEN→GREEN and RED→RED-same-signatures)
  - Signal handlers (SIGINT/SIGTERM clean shutdown; SIGPIPE SIG_DFL)
  - Slow-scan warning (>1s)
  - Snapshot cap warning (MAX_SNAPSHOT)
- `src/tests/tools/test-watch.bats` — integration tests
  - Initial run → emits initial state
  - File change → re-runs → emits transition if state changed
  - Silent when state unchanged
  - SIGTERM → clean shutdown
  - Symlink loop → handled (doesn't hang)
- `src/tests/python/test_watch_loop.py` — unit tests for:
  - `scan_mtimes` with lstat + inode tracking
  - Debounce algorithm (quiet_since races)
  - Snapshot cap

### Files modified
- `agency/tools/test-monitor` — no changes expected; test-watch consumes its stdout

### Critical design points

- **Polling, not inotify** (PVR Q4, ZERO-PIP)
- **Atomic state writes** — tmp + rename
- **lstat + inode tracking** — no symlink recursion (MAR-M2)
- **quiet_since debounce** not "time since last scan" (MAR-M4 fix)
- **Watch-path inference** per framework (A&D §5.4)

### Exit criteria

1. `test-watch --suite tools` runs end-to-end on the agency repo; editing a tool file triggers a re-run within 2s; re-running without changes stays silent
2. Transition detection matches spec (all 6 cases from §2.1)
3. Signal handling: SIGTERM → 0 exit code; state file flushed
4. Snapshot cap triggers warning, doesn't crash
5. MAR + iteration-complete + receipt

### Estimated scope

~300 LOC (tool + unit tests + integration tests). One session.

### Fallback: carve-off (measurable triggers — Plan-MAR R1#6)

Carve-off if ANY of:
- Iteration 5 exceeds 1.5 sessions of work
- MAR surfaces ≥3 findings that require A&D revision (not just code fixes)
- Watch-path inference (§5.4) fails for any registered framework during integration testing
- `fcntl.flock` behavior diverges between macOS and Linux CI in a way that breaks the concurrency invariant (Plan-MAR R1#11 risk)

On carve-off: commit partial progress to a branch, file a tracking issue, continue to PR Prep with UC1+UC3+QG rewire only. No silent abandonment.

---

## PR Prep Phase

After iteration 5 (or iteration 4 if test-watch is carved off):

- Run `/pr-prep` for the full diff vs `origin/main`
- Full QG with parallel agent review
- Receipt for the PR-boundary gate
- `gh pr create` via `pr-create` tool
- PR body summarizes: 5 iterations (or 4), 2 new tools, 1 skill rewire, 1 schema extension, follow-on issue references

---

## MAR gate specification (per iteration)

Per Plan-MAR R1#7 — MAR gates between iterations are specified, not hand-waved:

**Reviewers:** 2+ agents in parallel. Default pair:
- `general-purpose` agent with "design quality" prompt
- `general-purpose` agent with "adversarial/risk" prompt

For iterations that introduce code (not just docs), also launch:
- `reviewer-code` subagent (correctness, logic errors)
- `reviewer-security` subagent (injection, path traversal)
- `reviewer-test` subagent (coverage gaps)

**Triage:** every finding classified as **Disagree-with-reasoning / Autonomous / Collaborative** (no severity labels). Per framework principle: no deferrals. Findings are either:
- **Disagree** with written reasoning documented in the A&D/Plan disposition section, OR
- **Autonomous** — fixed in-iteration before iteration-complete, OR
- **Collaborative** — surfaced to principal; iteration-complete blocked until resolution.

**Blocking rule:** any Collaborative finding blocks iteration-complete until principal input. Autonomous findings requiring A&D revision produce A&D draft-vN+1 within the same iteration (precedent: draft-v2 → draft-v3 within this session).

**Receipt:** iteration-complete writes a QGR receipt via `receipt-sign` with the five-hash chain.

## Dependencies & Sequencing

```
Iteration 1 (test-monitor + BATS)
  │
  ▼
Iteration 2 (vitest + XCTest)
  │
  ▼
Iteration 3 (--trigger-on)
  │
  ▼
Iteration 4 (/quality-gate rewire)
  │
  ▼
[decision point: test-watch in v1 or carve-off]
  │
  ▼
Iteration 5 (test-watch) — or skip
  │
  ▼
PR Prep → PR
```

Sequential. No parallelism — each iteration's exit state is the next's entry state.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| vitest output format shifts mid-implementation | Med | Med | Fixture-based tests + RAW passthrough fallback (§5.3) |
| Python 3.13 not on adopter PATH (flag #175, dispatch #694) | High on some machines | Med | Runtime guard emits `[TEST ERROR]` on stdout (MAR-H4); QG falls back to test-run; captain is fixing via agency init/update |
| test-watch complexity blows up | Med | Low | Carve-off allowed with measurable triggers above. Ship v1 without it. |
| `/quality-gate` skill rewire breaks existing QG runs | Low | High | Opt-in default (`testing.monitor: false`). Existing users unaffected unless they flip the flag. Extensive BATS integration tests. |
| Parser tests become flaky due to real framework invocation | Low | Med | Fixtures captured once, committed to repo. Tests use fixtures, not live frameworks. |
| State file concurrent writes corrupt state | Low | Low | Atomic writes + YAML validity check on read + reset-on-corrupt (§7 #11) + fcntl lock (§2.4 draft-v3) |
| Dispatch tool address rejection | Low | Low | Circuit breaker after 3 failures (§5.7); `--trigger-to` required param means no silent dispatch to unknowns (draft-v3 §3.1) |
| **Fixture staleness — Iter 2 fixtures captured at T, real framework updated at T+N** (Plan-MAR F10) | Med over long run | Med | Each fixture file has a header comment: source command, framework version, capture date. `src/tests/python/test_parsers/README.md` documents refresh procedure. Occasional integration smoke against live frameworks (manual, not CI). |
| **`fcntl.flock` macOS vs Linux semantics** (Plan-MAR R1#11) | Low | Low | Use `LOCK_EX \| LOCK_NB` advisory lock — behavior identical on macOS (BSD) and Linux (POSIX) for local filesystems. Document: "local filesystems only; NFS / shared-volume behavior unsupported." Test on both macOS + Linux in iter 3 MAR. |
| **MAR finding requires A&D revision, not just code fix** (Plan-MAR F7) | Med | Low | Precedent established: A&D drafts-v2 → v3 within a session when MAR surfaces A&D-level issues. Iteration-complete commit includes BOTH the code changes AND the A&D revision. No separate iteration needed; no deferral. |
| **Iter 2 vitest fixture gap** (Plan-MAR R1#10, F3) | High | Med | `test/test-agency-project/` gains a minimal vitest suite as first Iter 2 change — ensures live vitest integration test is possible. Alternative: capture from any public vitest repo with compatible config. Decision fixed: add minimal suite in-repo. |

---

## Critical Files Map

For fast orientation during review. "Critical" = touched by multiple iterations or high-risk.

| File | Role | Iterations touching it |
|------|------|------------------------|
| `agency/tools/test-monitor` | Main tool | 1, 2, 3 |
| `agency/tools/test-watch` | File-watch tool | 5 |
| `agency/tools/lib/test_parsers/__init__.py` | Plugin registry | 1, 2 |
| `agency/tools/lib/test_parsers/bats.py` | BATS parser | 1 |
| `agency/tools/lib/test_parsers/vitest.py` | vitest parser | 2 |
| `agency/tools/lib/test_parsers/xctest.py` | XCTest parser | 2 |
| `.claude/skills/quality-gate/SKILL.md` | Skill rewire | 4 |
| `agency/config/agency.yaml` | Schema extension | 4 |
| `agency/data/test-monitor/*.state` | Persistent state | 3, 5 |
| `src/tests/tools/test-monitor.bats` | Integration tests | 1, 2, 3 |
| `src/tests/tools/test-watch.bats` | Integration tests | 5 |
| `src/tests/python/test_parsers/*` | Parser unit tests | 1, 2 |
| `src/tests/python/test_trigger_dedup.py` | Trigger logic tests | 3 |
| `src/tests/python/test_watch_loop.py` | Watch loop tests | 5 |
| `src/tests/tools/fixtures/test-monitor/` | Captured fixtures | 1, 2, 3 |
| `.gitignore` | Verify `agency/data/` covered (Plan-MAR R1#9) | 3 (entry check) |
| `test/test-agency-project/` | Add minimal vitest suite as Iter 2 first change (Plan-MAR F3) | 2 |
| Hookify rule for `agency/tools/lib/` stdlib-only | Enforce ZERO-PIP via hookify — added in Iter 1 alongside lib/ creation (Plan-MAR F8) | 1 |

---

## Scope boundaries (not defects, not deferrals)

Disagree-with-reasoning items. These are **out-of-scope by PVR decision**, not issues deferred from v1:

1. **No mid-run abort** — PVR Q5 with principal: v1 is non-interruptive by design. Issue #345 tracks the v2 feature request.
2. **No JSON reporter opt-in** — A&D §6.1: text output + RAW passthrough handles drift. YAGNI without evidence.
3. **Single-suite test-watch** — PVR UC2 scope. Multi-suite is a new feature request, not a defect.
4. **Watch-path inference is framework-specific** — A&D §5.4: this IS the feature.
5. **Upstream Python 3.13 PATH fix (captain-owned via dispatch #694)** — distinct from test-monitor's in-scope runtime guard. The guard (Iter 1) emits `[TEST ERROR]` on stdout when the interpreter is sub-floor, and `/quality-gate` falls back to sync test-run. The UPSTREAM fix (agency init/update verifying `python3` resolution at install time) is captain's work, not this project's scope.

All MAR findings (32 total) have been either fixed (31) or moot (1 — monitor-test wrapper dropped). No deferrals.

---

## Completeness Scorecard

| Item | Status |
|------|--------|
| Iteration breakdown | ✓ 5 iterations, each with entry/goal/files/tests/exit |
| Critical files identified | ✓ Mapped |
| Dependencies sequenced | ✓ Linear; measurable carve-off triggers at iter 5 |
| Test strategy per iteration | ✓ Unit + integration + coverage targets + signal-handler harness |
| Risk register | ✓ 10 risks with mitigations |
| Scope boundaries (Disagree-with-reasoning) | ✓ 5 items, each with PVR/A&D reference |
| MAR review gate | ✓ Every iteration ends with MAR + iteration-complete + receipt; A&D-level findings produce draft-vN+1 inline (Plan-MAR F7) |
| Principal decision points | ✓ Carve-off at iter 5 has measurable triggers; all others autonomous |

**Plan MAR applied (draft-v2). Ready to start Iter 1.**

---

## Plan-MAR disposition

24 findings across 2 reviewers. All triaged per three-bucket rule (no severity labels, no deferrals).

### Disagree-with-reasoning (1)

| # | Finding | Reasoning |
|---|---------|-----------|
| F12 | `--timeout=0` CLI runaway path | Principal accepted in draft-v3 MAR-Adv-L6. Monitor-tool mode is the primary path (bounded by Monitor timeout); CLI is a debugging affordance with explicit opt-in to unbounded runtime. |

### Autonomous (23 — all fixed in this Plan draft-v2)

| Finding | Fix |
|---------|-----|
| R1#1 / F2 | `fcntl` moved to Iter 3 (no state file in Iter 1); `--timeout` stays Iter 1 (no state dependency) |
| R1#2 / F1 | A&D §5.7 rewritten to use unified `<suite>.state` file; removed `.last-trigger` |
| R1#3 | Iter 1 LOC estimate bumped to 600–700, breakdown documented |
| R1#4 / F6 | Iter 4 verification layers explicit: prose-anchor grep + contract BATS + manual reviewer pass |
| R1#5 | Scope Boundary #5 tightened to distinguish captain's upstream fix from our in-scope runtime guard |
| R1#6 | Iter 5 carve-off triggers made measurable (4 specific conditions) |
| R1#7 | MAR gate specification added (reviewers, triage rule, blocking rule, receipt requirement) |
| R1#9 / F9 | `.gitignore` verification added as Iter 3 entry criterion; added to Critical Files Map |
| R1#10 / F3 | Decision fixed: add minimal vitest suite to `test/test-agency-project/` as Iter 2 first change |
| R1#11 | Risk register: fcntl macOS/Linux semantics noted; local-filesystem scope documented |
| R1#12 | Completeness Scorecard updated ("Scope boundaries" not "Known limitations"; 5 items not 7) |
| F4 | Signal-handler BATS harness specified: `bats_kill_and_wait` helper pattern |
| F5 | fcntl concurrency test synchronization specified: first process holds lock via `--timeout 10` on 8s-sleep fixture |
| F7 | MAR feedback-to-A&D loop documented: A&D draft-vN+1 within iteration, precedent established |
| F8 | Hookify rule for `agency/tools/lib/` ZERO-PIP enforcement added to Iter 1 |
| F10 | Risk register: fixture staleness; mitigation via capture-date headers + manual refresh procedure |
| F11 | Iter 5 timing criterion made specific: "within 2.0s wall-clock, verified via timestamp on emitted line" |

### Collaborative (0)

*Nothing required principal input. All findings resolved autonomously or via Disagree-with-reasoning.*

### Moot (0)

*All 24 findings represent real concerns.*
