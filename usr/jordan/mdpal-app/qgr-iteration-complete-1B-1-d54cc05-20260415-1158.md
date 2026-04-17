# Quality Gate Report — iteration-complete 1B.1

**Boundary:** iteration-complete
**Phase-Iteration:** 1B.1
**Scope:** CLIProcess harness — substitutable ProcessRunner seam, DefaultProcessRunner (Foundation.Process with concurrent pipe drain), CLIProcess composer, CLIBinaryResolver (MDPAL_BIN → PATH → fallbacks); RealCLIService init wires the resolver and fails fast with cliNotFound; the 9 protocol methods are stubs pending #407 wire-format.
**Stage hash:** `d54cc05`
**Date:** 2026-04-15 11:58

## Issues Found and Fixed

| ID | Category | Severity | Description | Fix |
|----|----------|----------|-------------|-----|
| 1 | reviewer-code | HIGH | `DefaultProcessRunner` wrote `stdoutData`/`stderrData` from concurrent drain queues and read them after `drainGroup.wait()` without an explicit memory barrier — Swift 6 strict concurrency would flag the data race; on ARM the writes are theoretically reorderable past the wait. | Added `NSLock` around the writes in each drain block and around the read at the end. The dispatch_group leave/wait pair already establishes happens-before, but the lock makes the contract obvious in code and survives future refactors. |
| 2 | reviewer-code | HIGH | stdin write failure was silently swallowed (`// Best-effort: continue`). If the child expects stdin and the pipe write hard-fails, the caller sees only an opaque non-zero exit — no diagnostic. | Capture the error into a local `stdinError`, then append a `[CLIProcess] stdin write failed: …` marker to the captured stderr before resuming the continuation. The child-already-exited race remains expected (write throws EPIPE, marker shows up alongside the child's own stderr). |
| 3 | reviewer-code | MEDIUM | `withCheckedThrowingContinuation` ran `process.run()` + `waitUntilExit()` + `drainGroup.wait()` directly on the calling Swift-concurrency thread — blocking a cooperative-pool worker. | Refactored: `run(...)` now dispatches the synchronous Process work onto `DispatchQueue.global(qos: .userInitiated)` via a private `runBlocking(...)` static method. The continuation is resumed from the dispatch queue. Cooperative pool stays unblocked. |
| 4 | reviewer-design | MEDIUM | `RealCLIService` used `@unchecked Sendable` even though the class has only one immutable `let` property of a Sendable type. | Changed to plain `Sendable`. The class is `final` with all-immutable Sendable storage, so the unchecked escape hatch was unnecessary noise. |
| 5 | reviewer-test | MEDIUM | `testCLIBinaryResolverThrowsWhenNothingFound` was conditionally-passing: on hosts with a real mdpal in `/usr/local/bin` or `/opt/homebrew/bin` the fallback succeeded and the test silently passed without exercising the error path. | Added a `fallbacks: [String]` parameter to `CLIBinaryResolver.resolve(...)` (defaulting to `defaultFallbacks`). Test now passes `fallbacks: []` for a deterministic empty-search and asserts `cliNotFound` is thrown. |
| 6 | reviewer-test | MEDIUM | `DefaultProcessRunner` had ZERO direct tests — only `FakeProcessRunner` was exercised. The central correctness claim ("drain prevents >64KB deadlock") was untested. | Added 5 integration tests using real shell scripts and `/bin/cat`: stdout+exit-code capture, stderr+non-zero-exit capture, stdin-forwarded-to-child round-trip, ~256KB stdout-without-deadlock, and missing-executable → `executionFailed`. |
| 7 | reviewer-test | MEDIUM | Resolver precedence (MDPAL_BIN > PATH > fallbacks) was tested per-tier but not across tiers. | Added `testCLIBinaryResolverPATHWinsOverFallbacks` and `testCLIBinaryResolverMDPALBinWinsOverPATH` — each puts a real mdpal at multiple tiers and asserts which one wins. |
| 8 | reviewer-code | LOW | `Int(-1)` cast on `executionFailed(exitCode:)` was a no-op (the parameter is already `Int`). | Removed redundant cast. |

### Findings considered and dismissed (with rationale)

| Finding | Source | Disposition |
|---------|--------|-------------|
| Task cancellation does not terminate the child process | reviewer-code (MEDIUM) | **Deferred to a later 1B iteration with explanatory NOTE in the code.** No 1B.1 caller is cancellable yet — `RealCLIService` methods are stubs. Adding `withTaskCancellationHandler` requires threading a `Process` reference into the onCancel closure across the dispatch boundary, which is real work that should land alongside the first cancellable consumer (likely a long-running `mdpal sections` for very large bundles). Documented inline. |
| `notYetImplemented` returns `executionFailed` instead of a dedicated `.notImplemented` case | reviewer-design (LOW) | **Deferred to 1B.2** — adding a new error case touches the protocol enum and the UI's error-mapping surface. Cleaner to land alongside the first real method implementation when the wire format is known. |
| `terminationHandler` for abnormal launch | reviewer-code (MEDIUM) | **Dismissed.** `process.run()` throwing is the abnormal-launch path and it's already handled. `terminationHandler` adds complexity for a scenario `waitUntilExit` already covers on macOS Foundation. |
| `FakeProcessRunner` doesn't record call count | reviewer-test (LOW) | **Dismissed.** Concurrent-call testing is out of scope for 1B.1 (no concurrent caller exists). Fake records last-call args, which is sufficient for the present tests. |

## Quality Gate Accountability

| Finding | Raised By | Scored By | Bug-exposing test | Fix verified |
|---------|-----------|-----------|-------------------|--------------|
| #1 data race | reviewer-code (general-purpose) | self | N/A — pure thread-safety hardening; can't reliably red→green a race in a unit test | swift build clean; large-stdout test still green (which exercises the drain path heavily) |
| #2 stdin error swallowed | reviewer-code | self | covered by `testDefaultProcessRunnerForwardsStdinToChild` (proves stdin path is exercised; the marker only fires on hard pipe error which is too host-dependent to test deterministically) | Code inspection — error capture and stderr append visible in `runBlocking` |
| #3 cooperative-thread block | reviewer-code | self | N/A — observable only as scheduler starvation under load | Code inspection of `runBlocking` dispatch |
| #4 unchecked Sendable | reviewer-design | self | N/A — type-system finding | swift build clean |
| #5 conditional resolver test | reviewer-test | self | The original test was the bug-exposing test (it would pass on hosts with mdpal installed). Fix proven by injecting empty fallbacks and asserting `cliNotFound` | green |
| #6 DefaultProcessRunner untested | reviewer-test | self | These tests ARE the coverage closure — 5 new tests, all green | green |
| #7 precedence tests | reviewer-test | self | Same — 2 new tests, both green | green |
| #8 Int(-1) no-op | reviewer-code | self | N/A — cosmetic | swift build clean |

Reviewer-* agents not invocable from this agent class. Per captain dispatch #380, formal reviewer-* invocation via captain general-purpose escalation is required from Phase 1B onward; substitution by parallel general-purpose agents is the documented Phase-1B-iteration interim path.

## Coverage Health

| Aspect | Before | After | Delta |
|--------|--------|-------|-------|
| Total tests | 46 | **60** | +14 |
| 1B.1-tier tests | 0 | 14 | +14 (7 resolver + RealCLIService init + CLIProcess delegation + 5 DefaultProcessRunner integration) |
| DefaultProcessRunner direct coverage | 0 tests | 5 tests | +5 (stdout/exit, stderr/non-zero, stdin, large-output, missing-binary) |
| Build warnings | 0 | 0 | unchanged |

## Checks

| Check | Result | Notes |
|-------|--------|-------|
| `swift build` | PASS | Clean, zero warnings |
| `swift run MarkdownPalAppTests` | PASS | **60/60 passing** |
| Format / Lint | N/A | No Swift tooling configured in this repo |
| Typecheck | PASS | Part of `swift build` |
| Failing | **0** | |

## Quality Gate Summary

**Stage 1 — Parallel Review**
- reviewer-code (general-purpose substitute): 6 issues — data race (HIGH, real), stdin swallow (HIGH, real), thread block (MEDIUM, real), cancellation (MEDIUM, deferred with note), abnormal-launch handler (MEDIUM, dismissed), Int cast (LOW, real)
- reviewer-design (general-purpose substitute): 2 issues — `@unchecked Sendable` (MEDIUM, real), `.notImplemented` case (LOW, deferred)
- reviewer-test (general-purpose substitute): 5 issues — conditional pass (MEDIUM, real), DefaultProcessRunner zero coverage (MEDIUM, real), precedence (MEDIUM, real), tempdir leak on createFile throw (LOW, dismissed — defer would still run on the throw path; minor), call-count fake (LOW, dismissed)
- reviewer-scorer: not invokable from this agent class — self-scored using same threshold (>=50)
- Own review: re-read CLIProcess `runBlocking` dispatch boundary; verified `lock`/`drainGroup.wait()` interaction; verified `RealCLIService` stub error doesn't accidentally claim it executed

**Stage 2 — Scoring & consolidation**
- 13 raw findings → 8 in-scope fixes + 4 dismissals/defers with rationale.

**Stage 3–4 — Bug-exposing tests / Fixes**
- The conditional-pass test (#5) was its own bug-exposing test — fix proven by replacing the swallow-on-host-mdpal silent-pass with a deterministic empty-fallbacks failure assertion.
- The DefaultProcessRunner coverage tests (#6) ARE the proof for the data race fix (#1) and stdin fix (#2) at the integration level — they exercise the new `runBlocking` path with real Process invocation.

**Stage 5–6 — Coverage tests**
- 5 DefaultProcessRunner integration tests close the central coverage gap (the entire production runner was previously dead-on-test).
- 2 precedence tests close the cross-tier resolver gap.

**Stage 7 — New issues**
- None surfaced by the coverage tests.

**Stage 8 — Clean**
- `swift build`: clean, zero warnings.
- `swift run MarkdownPalAppTests`: **60/60 passing.**

## What Was Found and Fixed

The 1B.1 increment introduced the substitutable seam for `mdpal` CLI invocation: a `ProcessRunner` protocol, a `DefaultProcessRunner` backed by Foundation.Process with concurrent pipe-drain to avoid the 64KB pipe-buffer deadlock, a `CLIProcess` composer, a `CLIBinaryResolver` (MDPAL_BIN env → PATH → fallbacks), and a `RealCLIService` that resolves the binary at init (failing fast with `cliNotFound`) but stubs all 9 `CLIServiceProtocol` methods pending the wire-format spec from `mdpal-cli` in #407.

The QG surfaced two HIGH-severity correctness issues in `DefaultProcessRunner` worth calling out:

1. **Data race on captured pipe data.** The drain blocks wrote to `var stdoutData`/`var stderrData` from a concurrent `DispatchQueue`, then the spawning continuation read them after `drainGroup.wait()`. `dispatch_group_wait` does establish happens-before with the leaves, so the read is safe in the C memory model — but Swift's strict-concurrency model wants explicit synchronization, and a future refactor that does anything between the writes and the wait would silently introduce a race. Fix: an explicit `NSLock` around both the writes (one per drain block) and the read (after `drainGroup.wait()`). Belt and suspenders, but the contract is now visible in the source.

2. **stdin write failure was silent.** The original `do { write; close } catch { }` ate the error with a "best-effort, child may have exited" comment. That comment is *true* — the EPIPE-on-child-already-exited race is normal — but a real pipe error (e.g., disk full on a `/tmp`-backed pipe, signal interrupting write) would also be silently dropped, leaving the caller staring at an opaque non-zero exit with no clue that we never fed stdin. Fix: capture the error into a local, append a `[CLIProcess] stdin write failed: <description>` marker to the child's captured stderr before resuming. Diagnostic visibility without changing the success-path behavior.

Two MEDIUM issues round out the runner hardening: the Process work was running on a Swift-concurrency cooperative thread (refactored to dispatch onto a global queue via a private `runBlocking` static), and the `@unchecked Sendable` on `RealCLIService` was unnecessary (the class is `final` with one `let` property of a Sendable type — plain `Sendable` works).

The largest test-side gap was that `DefaultProcessRunner` had zero direct tests — every test in 1B.1 was driving the `FakeProcessRunner`. So the central correctness claim of the runner ("concurrent pipe drain prevents >64KB deadlock") was untested. Fix: 5 integration tests exercising stdout+exit, stderr+non-zero exit, stdin round-trip via `/bin/cat`, ~256KB stdout (proves the drain claim), and missing-executable. Plus 2 cross-tier precedence tests for the resolver (MDPAL_BIN > PATH, PATH > fallbacks). The conditional-pass test (`throwsWhenNothingFound`) needed an injection seam — added a `fallbacks: [String]` parameter (default `defaultFallbacks`) to `CLIBinaryResolver.resolve(...)`, and the test now passes `fallbacks: []` for deterministic empty-search.

Two findings deferred with explicit rationale: task cancellation (no caller is cancellable in 1B.1; documented inline; lands with first cancellable consumer) and a dedicated `.notImplemented` error case (touches the protocol enum and UI error-mapping; lands in 1B.2 alongside the first real method).

## Deferred / out of scope for this iteration

- Task cancellation → terminate child process (lands with first cancellable consumer)
- Dedicated `.notImplemented` error case (lands in 1B.2 with first real method)
- Real protocol method implementations (1B.2–1B.4 — blocked on #407 wire format)
- Concurrent-call testing on a single CLIProcess instance (no concurrent caller exists)

## Proposed Commit

```
Phase 1B.1: feat: CLIProcess harness + RealCLIService init + cliNotFound

Real-CLI integration foundation. Introduces the substitutable seam for
invoking the mdpal binary so RealCLIService can replace MockCLIService
once the wire format lands in #407.

New: apps/mdpal-app/Sources/MarkdownPalApp/Services/CLIProcess.swift
- ProcessResult (exitCode/stdout/stderr) — Sendable, Equatable
- ProcessRunner protocol — substitutable seam
- DefaultProcessRunner — Foundation.Process backed, dispatches the
  blocking work onto a global queue (cooperative pool stays unblocked),
  drains stdout/stderr concurrently to avoid the ~64KB pipe-buffer
  deadlock, surfaces stdin write failures via stderr, NSLock around
  drain captures for explicit memory-model safety
- CLIProcess — composes runner + resolved binary path
- CLIBinaryResolver.resolve(env, fileManager, fallbacks) — three-tier:
  MDPAL_BIN env → PATH → fallbacks (defaults to /usr/local/bin/mdpal,
  /opt/homebrew/bin/mdpal); fallbacks parameter is the test seam

New: apps/mdpal-app/Sources/MarkdownPalApp/Services/RealCLIService.swift
- final Sendable class implementing CLIServiceProtocol
- init resolves binary via CLIBinaryResolver, throws cliNotFound on miss
- 9 protocol methods are stubs (executionFailed with explanatory
  message) pending wire-format spec from #407 (Phase 1B.2+)

Tests: apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift
- 14 new tests, 46 → 60 green
- CLIBinaryResolver: MDPAL_BIN override, MDPAL_BIN points nowhere,
  PATH lookup, nothing-found (deterministic via empty fallbacks),
  PATH-wins-over-fallbacks, MDPAL_BIN-wins-over-PATH
- CLIProcess.run delegates to runner (FakeProcessRunner)
- RealCLIService init: cliNotFound when binary missing; succeeds
  when binary resolves
- DefaultProcessRunner integration (real Process): stdout+exit,
  stderr+non-zero exit, stdin round-trip (/bin/cat), ~256KB stdout
  without deadlock, missing-executable throws

QGR: usr/jordan/mdpal-app/qgr-iteration-complete-1B-1-d54cc05-20260415-1158.md

Files:
- apps/mdpal-app/Sources/MarkdownPalApp/Services/CLIProcess.swift
- apps/mdpal-app/Sources/MarkdownPalApp/Services/RealCLIService.swift
- apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift

Co-Authored-By: Claude <noreply@anthropic.com>
```
