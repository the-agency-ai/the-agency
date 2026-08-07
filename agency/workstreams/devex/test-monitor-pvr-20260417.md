---
type: pvr
project: test-monitor
workstream: devex
date: 2026-04-17
status: draft
seeds:
  - issue #180 (principal-filed)
  - dispatch #552 (captain directive, three patterns)
  - agency/tools/dispatch-monitor (D44-R1 Python precedent)
---

# PVR: test-monitor — Monitor Tool Integration for Test Runs

## 1. Problem Statement

Test runs today are one-shot: invoke `test-run`, block waiting for output, react. Agents can't:

- Start a long-running test suite and remain responsive while it executes
- React mid-run to specific failure patterns in streaming output
- Chain follow-up actions to test outcomes (green → commit-ready dispatch; red → draft fix plan; new failure → flag)

The Monitor tool (Claude Code v2.1.98+) solves the same class of problem for dispatches — `dispatch-monitor` polls every 10s, stays silent when nothing is happening, emits a line when a new dispatch arrives, and the Monitor tool surfaces that line to the agent as a notification. The agent keeps working; token cost is zero when nothing is happening.

The same primitive applied to test runs turns a blocking operation into an event stream: the agent launches the test suite and keeps designing the next piece; when the suite completes (or a critical failure fires mid-run), a notification arrives.

**For whom:** All agents that run tests — DevEx during framework work, workstream agents during iteration QG, captain during release gate.
**Why now:** Monitor tool is proven (dispatch-monitor shipped D44-R1); `test-run` is the framework's standard test entry point and already reads `agency.yaml → testing.suites`. The integration is the missing piece.

## 2. Target Users

| User | Role | Primary benefit |
|------|------|-----------------|
| DevEx agent | Framework tool work | Long BATS runs don't block design work |
| Workstream agents (mdpal, mock-and-mark, iscp, …) | Feature iteration | `/iteration-complete` QG step uses Monitor instead of blocking |
| Captain | Release gating | Parallel test streams across workstreams during PR queue processing |
| Principal | Real-time awareness | PushNotification when red→green flips (or new failure) during a long session |

## 3. Use Cases

### UC1 — Pattern A: Monitor a single test run to completion

Agent launches a suite, stays responsive, reacts to completion.

```
Agent: Monitor tool runs `./agency/tools/test-run tools --monitor-mode`
→ Emits per-suite progress lines (suite start, each failure, summary)
→ Agent keeps working on next subtask
→ On SUITE_DONE line, agent reads the result and proceeds
→ On FAIL line mid-run, agent can decide: keep going or interrupt and draft a fix
```

**Trigger:** `/iteration-complete` QG Step 8 (test run), a manual "run tests while I keep thinking" request.

### UC2 — Pattern B: Continuous watch, emit on transitions

Background watcher re-runs on file change, silent when green→green or red→red, emits on state transitions.

```
Agent: Monitor tool runs `./agency/tools/test-watch tools`
→ Initial run — emits STATE: GREEN
→ Agent edits a file — re-run triggered
→ Still green — silent (no emission)
→ Agent introduces a bug — re-run
→ Emits TRANSITION: GREEN→RED with failing test name + assertion
→ Agent sees the notification, fixes, re-run
→ Emits TRANSITION: RED→GREEN
→ Silent again until next transition
```

**Trigger:** Extended iteration sessions where the agent iteratively edits + wants immediate feedback without asking.

### UC3 — Pattern C: Outcome-triggered dispatch/flag

Test completion emits a dispatch or flag so follow-up work is captured in ISCP, not stuck in agent memory.

```
test-run finishes green → `dispatch commit-ready <stage-hash>` to captain
test-run finishes red   → `dispatch test-failure` with {suite, failing test, assertion, diff hint}
new failure appears     → `flag` with test name + assertion
```

**Trigger:** Unattended QG runs where the agent context may compact before tests finish. The ISCP artifact persists through compact/restart.

### UC4 — `/quality-gate` non-blocking test step (v1 scope)

Today, `/quality-gate` Step 8 invokes `test-run` synchronously — the agent is idle during the test window. v1 rewires Step 8 to launch `test-monitor` via the Monitor tool and await the `RUN_DONE` line before gating. Agent stays responsive during the test run.

`/iteration-complete`, `/phase-complete`, and `/pr-prep` all delegate to `/quality-gate` and inherit the change automatically.

**Backward compatibility:** if `test-monitor` is absent or the project opts out via `agency.yaml → testing.monitor: false`, `/quality-gate` falls back to synchronous `test-run`. Prevents breaking projects that haven't adopted the new flow.

## 4. Functional Requirements

### FR1 — `test-monitor` (new peer Python tool)

New tool at `./agency/tools/test-monitor`, Python 3.13+, structured file-by-file mirror of `dispatch-monitor`. Shells out to `test-run` (or frameworks directly) and parses their output. Emits line-buffered, grep-friendly output on stdout.

**Output format** conforms to the **monitor-tool family convention** already established across `dispatch-monitor`, `ci-monitor`, `issue-monitor`, and `changelog-monitor`:

- **`[TAG]` prefix** — uppercase, single bracket, at line start for Monitor grep-filter stability
- **Prose body** after prefix (not structured `key=value` or JSON) — agent-parseable by pattern match
- **Sub-identifier** embedded in the tag where useful: `[TEST tools]`, `[TEST mdpal]`, `[TEST ERROR]`
- **Inline action hint** on actionable events: `— agent: investigate failures`
- **Silent when idle** — no heartbeat, no output unless state changed
- **One event per line**, line-buffered (Monitor tool requirement)

| Event | Emitted when | Example line |
|-------|--------------|--------------|
| Suite start | Before each suite | `[TEST tools] suite started (bats, ~15 tests)` |
| Case pass | Per passing case (**`--verbose` only**, or framework reports it) | `[TEST tools] PASS bats/foo.bats:8` |
| Case fail | Per failing case | `[TEST tools] FAIL bats/foo.bats:12 — expected 1 got 2` |
| Suite done | After each suite | `[TEST tools] suite done — 15 pass, 1 fail, 0 skip, 2.3s` |
| Run done | After all suites | `[TEST] run complete — 15 pass, 1 fail, 0 skip, 2.3s, exit 1 — agent: investigate failures` |
| Error | Tooling failure (missing framework, config broken) | `[TEST ERROR] pytest not installed for suite=python — agent: install or skip` |

- A clean-passing suite emits only the suite-start and suite-done lines.
- Exit code: 0 all green, 1 any fail, 2 tooling error.
- **No `--format json` flag in v1.** Single stable contract; convention matches all existing monitor-tool outputs.

### FR2 — `test-watch <suite>` (new tool)

File-watcher + test runner loop. Python implementation (following dispatch-monitor precedent for bash 3.2 compat).

- Watches the source tree paths registered in `agency.yaml → testing.suites.<name>.watch_paths` (new config field, default: repo root excluding `.git`, `node_modules`, etc.).
- Debounces rapid file changes (e.g. 500ms quiescence before triggering a run).
- Tracks last-known state per suite: `GREEN` | `RED`.
- Emits only on **transitions**: `GREEN→RED`, `RED→GREEN`, new failure appearing in an already-red state, or transient tooling failure clearing.
- Silent during GREEN→GREEN / RED→RED-same-failures.
- Supports `SIGTERM` / Ctrl-C for clean shutdown (no zombie watchers).

### FR3 — `test-monitor --trigger-on <event>`

Emit a dispatch on completion.

- `--trigger-on green` — emit `dispatch commit-ready` if all pass.
- `--trigger-on red` — emit `dispatch test-failure` with structured payload if any fail.
- `--trigger-on change` — emit `flag` if this run's outcome differs from the last stored outcome.
- `--trigger-to <agent>` — destination; defaults to captain.

### FR4 — Monitor tool integration helper

`./agency/tools/monitor-test` — thin wrapper for agents that prefers a one-liner over constructing the Monitor invocation themselves. Mirrors `dispatch-monitor` as a template.

### FR5 — `/quality-gate` Step 8 rewire (v1 scope)

- `/quality-gate` Step 8 detects `test-monitor` presence and `agency.yaml → testing.monitor` opt-in; if both true, launches `test-monitor` via Monitor tool and awaits `RUN_DONE`.
- Falls back to synchronous `test-run` if `test-monitor` is absent or opt-out is set. Backward-compatible by default.
- `/iteration-complete`, `/phase-complete`, `/pr-prep` inherit the change via their existing delegation to `/quality-gate`.

### FR6 — Framework coverage

| Framework | v1 support | Notes |
|-----------|-----------|-------|
| BATS | Required | Primary test runner for framework tools |
| vitest | Required | Primary test runner for TypeScript workstreams |
| pytest | Deferred | No current pytest suites in framework; add when needed |
| Swift XCTest (mdpal) | Required | Already registered as a test suite; must emit transitions |

## 5. Non-Functional Requirements

| Dimension | Target |
|-----------|--------|
| Token cost when idle | Zero — no stdout emission when nothing changes |
| Latency (start → first emission) | < 1s for suite start, < 200ms after test process emits |
| Poll interval (test-watch) | Configurable, default 1s filesystem polling or inotify/fsevents if available |
| Memory (test-watch long-running) | Bounded — track last-state per suite, not per-case history |
| Python version | 3.13+ (framework floor, D45-R1 — supersedes D44-R6 3.12) — ZERO-PIP stdlib only for `agency/tools/` |
| Idempotency | Re-running produces the same outcome; transition detection is state-based, not diff-based |

## 6. Constraints

- **Tech:** Python 3.13+ (framework floor per D45-R1, supersedes D44-R6 3.12). Shebang convention: `#!/usr/bin/env python3` + runtime `sys.version_info` guard (NOT `python3.13` — hard-coded minor names break pyenv/nix/conda/Apple-stock installs; see `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md`). Modern idioms available (native `match`, PEP 604 unions, PEP 695 generics, `typing.Self`, `tomllib`) but 3.13 mandates no new opt-in required (PEP 703 no-GIL and PEP 744 JIT are opt-in). Framework tools (`agency/tools/`) remain ZERO-PIP (stdlib only). `test-run` stays bash; all new tools here (`test-monitor`, `test-watch` if kept) are Python 3.13.
- **Protocol:** Must compose with Monitor tool's line-buffered stdout contract. Grep patterns must be stable across releases.
- **Config:** `agency.yaml → testing.suites` is the source of truth. No hard-coded suite knowledge.
- **ISCP:** Outcome triggers emit via `./agency/tools/dispatch` and `./agency/tools/flag` — never write ISCP records directly.
- **Framework-neutral:** BATS, vitest, and XCTest have different output formats; the tool normalizes them to the prefixed line contract. New frameworks integrate by adding a parser module.
- **No silent failure:** if the tool can't find a suite, parse its output, or resolve a trigger destination, it emits an `ERROR` line — never goes silent on a broken path.

## 7. Success Criteria

| Measure | Target |
|---------|--------|
| `test-run --monitor-mode` emits structured lines on all configured suites | 100% of suites register either a parser or an explicit "no-parse" passthrough |
| `test-watch` token cost during 1h GREEN session with 10 file edits | 0 emissions beyond initial state line |
| `test-watch` emits on RED→GREEN transition within 2s of test completion | 95p latency |
| `/iteration-complete` adoption of `--monitor-mode` (v1.x follow-up) | Unblocks agent for the QG test window |
| Captain adopts Monitor for PR queue parallel test runs | Throughput ↑ on queue processing |

## 8. Non-Goals

- **Not a full test framework.** Doesn't replace BATS/vitest/XCTest — orchestrates and parses them.
- **Not a CI runner.** No remote execution, no matrix builds, no artifact upload. Local dev + captain session only.
- **Not a coverage tool.** Coverage reporting stays with each framework's native tooling.
- **Not a replacement for `commit-precheck`.** Pre-commit stays synchronous (fast fail). This tool is for longer test windows.
- **Not automatic commit/push on green.** `--trigger-on green` emits a dispatch; the captain decides to act. No autonomous commits.
- **Not a test generator.** Does not write tests, only runs/watches them.

## 9. Open Questions

1. ~~**Output format — structured JSON or prefixed plain-text?**~~
   - **Resolved 2026-04-19:** `[TAG]` prefix + prose body + optional inline action hint, conforming to the **monitor-tool family convention** already in use across `dispatch-monitor`, `ci-monitor`, `issue-monitor`, `changelog-monitor`. No JSON opt-in in v1. Monitor alerts are for agents (the sole consumer); principal sees only what the agent surfaces. Format optimized for agent consumption: compact, grep-anchored prefix, pattern-matchable prose. See rewritten FR1 output section above.

2. ~~**Should `test-watch` run in a separate process or stay foreground-blocking?**~~
   - **Resolved 2026-04-19:** `test-watch` IS the foreground process that the Monitor tool wraps. Monitor manages the lifecycle (start, kill on timeout, restart via re-invocation). No daemon, no fork, no subprocess tricks. Matches `dispatch-monitor` / `ci-monitor` / `issue-monitor` precedent exactly.

3. ~~**Pattern C dispatch payload schema.**~~
   - **Resolved 2026-04-19:** A&D question. PVR requires that `dispatch test-failure` carry a structured payload sufficient for the receiving agent to identify the failure without re-running the suite — at minimum: suite, failing test id, reason, location. Exact schema (field names, multi-failure handling, size limits, ISCP encoding) is implementation detail for A&D.

4. ~~**File-watch backend.** inotify / fsevents via `watchdog`, or 1s polling?~~
   - **Resolved 2026-04-19:** 1s stdlib polling (os.walk + mtime diff). Principal accepts 1s latency. No `watchdog` dep. Consistent with current ZERO-PIP convention for `agency/tools/`. Debounce 500ms quiescence before triggering. Implementation detail in A&D.

5. ~~**Mid-run interruption model.**~~
   - **Resolved 2026-04-19:** Out of scope for v1. Runs complete; agent reads results and decides. Cascade noise is tolerable at 1-2s per test; `/quality-gate` exits 1 on any fail regardless. Agent retains TaskStop capability independent of test-monitor. Revisit for v2 with framework-native bail (vitest has it; BATS/XCTest would need wrappers). Follow-on work captured in issue **#345** (test-monitor: mid-run critical-failure abort).

6. **Interaction with `/quality-gate`.** ~~Is v1 scope limited to the tools, or does v1 also rewire `/quality-gate` Step 8?~~
   - **Resolved 2026-04-17:** Larger v1 — ship tools AND rewire `/quality-gate` Step 8 in the same PR. Small v1 would ship unused primitives; the consumer rewire is where the value materializes. Backward-compat fallback for projects that haven't adopted.

7. ~~**Suite watch-paths config.**~~
   - **Resolved 2026-04-19:** Hybrid — explicit `testing.suites.<name>.watch_paths` field in `agency.yaml` is primary; if absent, test-watch infers from the suite's framework + command (framework-specific rules, defined in A&D); repo-root-minus-standard-ignores is the final safety net. Explicit field documents itself; inference handles "I just want it to watch the obvious stuff" cases. Ignore list (applied in all cases): `.git`, `node_modules`, `dist`, `build`, `.agency`, `agency/data`, plus anything in `.gitignore`.

8. ~~**Naming.** `test-run --monitor-mode` vs `test-monitor` as a peer tool?~~
   - **Resolved 2026-04-17:** `test-monitor` as new peer Python tool, mirroring `dispatch-monitor` file-for-file. Keeps `test-run` as the one-shot tool; `test-monitor` owns long-lived / streaming / state-aware concerns.

9. ~~**Priority ordering.** Which of UC1/UC2/UC3 ships first?~~
   - **Resolved 2026-04-17:** Internal PR order is **UC1 → UC3 → QG rewire → UC2**. UC1 minimum viable tool; UC3 thin post-processor on UC1's parser; QG rewire smokes out bugs by being the first real consumer; UC2 last — standalone feature, natural carve-off point if complexity blows up.

## 10. Completeness Scorecard

| # | Section | Status |
|---|---------|--------|
| 1 | Problem Statement | ✓ Complete |
| 2 | Target Users | ✓ Complete |
| 3 | Use Cases | ✓ Complete |
| 4 | Functional Requirements | ✓ Complete (FR1-FR6 drafted) |
| 5 | Non-Functional Requirements | ✓ Complete |
| 6 | Constraints | ✓ Complete |
| 7 | Success Criteria | ~ Partial — needs principal validation of targets |
| 8 | Non-Goals | ✓ Complete |
| 9 | Open Questions | 0 of 9 remaining — **all resolved** |

**Score:** 9/9 — PVR complete, ready for A&D.

## 1B1 Resolution Log

| Date | Q# | Topic | Resolution |
|------|----|-------|------------|
| 2026-04-17 | Q6 | v1 scope | Larger v1 — tools + `/quality-gate` Step 8 rewire in one PR, with backward-compat fallback |
| 2026-04-17 | Q8 | Naming | New Python peer tool `test-monitor`, mirrors `dispatch-monitor` file-for-file |
| 2026-04-17 | Q9 | Build order | UC1 → UC3 → `/quality-gate` rewire → UC2 (UC2 = natural carve-off point) |
| 2026-04-19 | Q1 | Output format | Conforms to monitor-tool family convention (`[TAG]` prefix + prose body + action hints); no JSON opt-in in v1. Agent is sole consumer; principal sees only what agent surfaces. |
| 2026-04-19 | Q2 | `test-watch` process model | Foreground process wrapped by Monitor tool — Monitor manages lifecycle. No daemon/fork/subprocess tricks. Matches existing monitor-tool precedent. |
| 2026-04-19 | Q3 | Pattern C payload schema | A&D question. PVR requires structured payload with minimum fields (suite, test id, reason, location); A&D designs exact schema. |
| 2026-04-19 | Q4 | File-watch backend | 1s stdlib polling (os.walk + mtime diff), 500ms debounce. No `watchdog` dep. Principal accepts 1s latency. |
| 2026-04-19 | Q5 | Mid-run interruption | Out of scope v1. Runs complete; agent reads results. Follow-on captured in issue #345. |
| 2026-04-19 | Q7 | `watch_paths` config | Hybrid: explicit `testing.suites.<name>.watch_paths` is primary; inference from suite command is fallback; repo-root-minus-ignores is safety net. Inference rules defined in A&D. |

## Path-rename note (v46 Great Rename, 2026-04-22)

This PVR was originally authored at `claude/workstreams/devex/test-monitor-pvr-20260417.md`. Main renamed `claude/` → `agency/` and `tests/` → `src/tests/` via PR #373 + PR #386. This file now lives at `agency/workstreams/devex/test-monitor-pvr-20260417.md` with all path references updated. No requirement content changed.

## Next Session Queue

**PVR complete 2026-04-19.** All 9 questions resolved. Next: invoke `/design --from agency/workstreams/devex/test-monitor-pvr-20260417.md` to start A&D. Expected A&D surface: parser module shape, trigger subprocess model, backward-compat sniffing pattern in `/quality-gate`, Pattern C payload schema (Q3), watch-path inference rules per framework (Q7).
