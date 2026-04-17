---
type: plan
phase: 1B
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-15
captain_directive: dispatch #380 (scope), #399 (PR cadence)
---

# Phase 1B — Real-CLI Integration

## Goal

Replace `MockCLIService` runtime with `RealCLIService: CLIServiceProtocol` that shells out to the `mdpal` CLI and parses its JSON output. Mock stays available for previews and tests. Phase completes when the app can open a real bundle, list sections, read, edit, comment, flag — end-to-end through the CLI — with tests driving both happy path and error-envelope handling.

Per captain #399: this phase's completion is the **first PR** for mdpal-app. No PR is cut mid-phase.

## Non-goals

- **Persistence** — Phase 1C per captain #380.
- **Bundle creation / init / commit commands** — only the reader surface from Phase 1A.
- **Live NSTextView selection**, diff-in-conflict, XCUITest harness — all deferred from Phase 1A, remain deferred.
- **Rewrite of CLIServiceProtocol** — Phase 1B implements against the existing protocol; drift fixes only if mdpal-cli's shape forces them.

## Inputs

- `CLIServiceProtocol` (Services/CLIServiceProtocol.swift, 9 methods) — the contract.
- Model types: `Section`, `SectionTreeNode`, `Comment`, `Flag`, `EditResult`, `ResolveResult`, `FlagResult`, `ClearFlagResult`, `BundlePath`.
- `CLIServiceError` typed error surface — `cliNotFound`, `versionConflict`, `sectionNotFound`, `bundleConflict`, `executionFailed`, `parseError`, etc.
- mdpal-cli JSON spec (dispatch #23, authoritative) — **awaiting wire-format confirmation via dispatch #407** before I finalize parsers.
- mdpal-cli Phase 1 iterations 1.1–1.4 landed (per dispatch #154) — commands available: sections, read, edit, comments, add-comment, resolve-comment, flags, flag, clear-flag. Bundle path mechanics from CLI Phase 1.4.

## Dependencies / blockers

- **Wire-format confirmation from mdpal-cli (#407).** Plan proceeds; parsers are stubbed until confirmed. Implementation of each command's parser waits on its confirmed shape.
- **CLI binary resolution.** Phase needs a deterministic way to locate the `mdpal` binary. Candidates: env var `MDPAL_BIN`, PATH lookup, known install locations. Deferred detail pending CLI binary delivery.

## Iteration plan

All iterations are on the `mdpal-app` branch; no PR until phase complete.

### 1B.1 — Process harness + cliNotFound path
**Scope:** `CLIProcess` helper that invokes a binary with argv + optional stdin, captures stdout/stderr, returns exit code. Pure, testable via substitutable `ProcessRunner` protocol. First consumer: `RealCLIService.init` resolves the binary path; throws `CLIServiceError.cliNotFound` when binary missing.
**Deliverable:** `RealCLIService` type exists, can be constructed, fails cleanly when no CLI on PATH. Flag/env-var selection of binary location.
**Tests:** fake `ProcessRunner` for happy-path launch; absent-binary error path; env-var override precedence.

### 1B.2 — Read-side command: `listSections` ✅ COMPLETE (commit b539144)
**Scope (landed):** First real `CLIServiceProtocol` method. `listSections(bundle:)` shells out to `mdpal sections <bundle>` per dispatch #23, decodes `SectionsResponse`, flattens depth-first. Introduces `runCommand<T>` helper (no-typed-error read shape) and shared `JSONDecoder` (iso8601, forward-proofs 1B.3 Dates). RealCLIService init extended with `fallbacks: [String]` for hermetic test resolution.
**Scope split:** Plan originally grouped four read methods into 1B.2 — split per captain #380 (one-method iterations). `readSection`, `listComments`, `listFlags` move to 1B.3 (now renamed — see updated iteration numbering below).
**Deliverable (landed):** `listSections` path end-to-end against canned JSON; 6 tests (happy 3-level; argv; empty; non-zero exit; malformed JSON; missing required field); 60 → 66 green.
**Fixture strategy:** inline JSON strings in ModelTests.swift (no separate Tests/Fixtures/cli/ dir yet — revisit if fixtures proliferate in 1B.3).

### 1B.3 — Read-side commands: `readSection` + `listComments` + `listFlags` (pending)
**Scope:** Three remaining read-only methods. Each: argv assembly + decode through `runCommand<T>`. `readSection` returns `Section`; `listComments` unwraps `CommentsResponse`; `listFlags` unwraps `FlagsResponse`. First iteration to decode Date fields (Comment/Flag timestamps) — proves the shared decoder's iso8601 strategy.
**Tests:** For each: happy-path + malformed-JSON + non-zero-exit.
**Design note:** `runCommand<T>` comment flags this as the iteration where typed-envelope parsing (sectionNotFound on `readSection`) may need to land — either extend the helper or introduce a sibling.

### 1B.4 — Edit (version-hash conflict envelope)
**Scope:** Implement `editSection`. Per mdpal-cli #408: CLI will signal versionConflict via exit code 2 + structured stderr JSON `{"error":"versionConflict","expected":"...","actual":"..."}`. This iteration introduces the typed-envelope parsing path on top of `runCommand<T>` (likely as a sibling helper or an extension with optional `CLIErrorResponse` decoding from stderr).
**Deliverable:** Edit happy-path + typed `versionConflict` → existing Phase 1A conflict alert still drives correctly.
**Tests:** happy-path; versionConflict envelope → `.versionConflict(slug:expectedHash:currentHash:)`; generic failure → `.executionFailed`.

### 1B.5 — Mutation commands (add-comment, resolve-comment, flag, clear-flag)
**Scope:** Four mutation commands. Pattern reuses 1B.4's envelope-parsing machinery.
**Deliverable:** All sheet surfaces from Phase 1A work end-to-end against CLI.
**Tests:** For each: happy-path + one error path. Coverage pragmatic — the process/parse machinery is shared.

### 1B.6 — Service selection + runtime switch + housekeeping
**Scope:** Wire the app so `RealCLIService` is the default when a CLI is available, `MockCLIService` stays for previews/tests and as an explicit fallback (env var or launch flag). No hardcoding — the selection lives in one place. Also lands deferred housekeeping: `ClipboardReader` env-injection refactor; DefaultProcessRunner size cap on stdout/stderr (DoS defense from 1B.2 QG).
**Deliverable:** Shipping behavior: real CLI. Previews and tests: mock. Opt-out via env.

### 1B (phase close) — Phase QG + PR
**Scope:** Phase QG invoked via captain general-purpose escalation to reach formal reviewer-* agents (per #380). If escalation not available, flag the gap and request disposition.
**Deliverable:** `/phase-complete 1B` → **first mdpal-app PR** per #399. Release via `/release`.

## Quality-gate policy

- **Iteration QGs:** self-review path continues (reviewer-* not invocable from this agent class). QGR per iteration, stage-hashed, committed with work item.
- **Phase QG:** must invoke formal reviewer-* via captain general-purpose escalation (captain directive in #380). If not reachable, flag enforcement gap, dispatch captain, wait.

## Architectural notes

- **CLIProcess as seam.** All process invocation flows through one choke point. This is the only place that knows about `Process`, file descriptors, and `Data`. Keeps `RealCLIService` pure — it does argv assembly + JSON decode.
- **Fixture-driven parsers.** JSON fixtures in the test target. Adding/changing a command means adding a fixture, not mocking `Process`.
- **Error mapping.** CLI stderr/exit-code → typed `CLIServiceError`. The mapping layer is a pure function tested independently.
- **SectionReaderView.swift split (deferred from 1A):** do this during 1B as housekeeping — the file already touches edit/conflict/mutation paths, so the split aligns with real-CLI work. Land in a dedicated iteration or housekeeping commit inside 1B.

## Deferred / out of scope for Phase 1B

- **Persistence layer** (Phase 1C).
- **Live selection via NSTextView** (Phase 2).
- **Diff in conflict alert** (Phase 2).
- **SwiftUI view tests** — awaits XCUITest harness.
- **Per-error-type alert styling.**
- **DocumentModel state-model consistency (addComment vs resolveComment)** — revisit once real CLI shapes confirm the right state model.

## Open questions — answered by #408

Resolved by mdpal-cli dispatch #408 (2026-04-15):

1. **Wire-format drift vs #23:** none yet — CLI unbuilt (Phase 2); #23 remains authoritative target.
2. **versionConflict signalling:** exit code 2 + stderr JSON `{"error":"versionConflict","expected":"...","actual":"..."}`.
3. **CLI binary install path:** `swift build` → `apps/mdpal/.build/debug/mdpal` for now; install path lands in mdpal-cli Phase 2.
4. **Bundle path:** absolute recommended (engine accepts both via URL resolution).
5. **Stderr structure:** structured JSON per error envelope (see #23 spec).

## Iteration status

| Iter | Status | Commit | Tests | Notes |
|------|--------|--------|-------|-------|
| 1B.1 | ✅ COMPLETE | `8f80b7a` | 46 → 60 | CLIProcess harness + RealCLIService init + cliNotFound |
| 1B.2 | ✅ COMPLETE | `b539144` | 60 → 66 | listSections against #23; runCommand<T>; shared iso8601 decoder |
| 1B.3 | pending | — | — | readSection + listComments + listFlags |
| 1B.4 | pending | — | — | editSection + versionConflict envelope |
| 1B.5 | pending | — | — | mutation commands (add/resolve/flag/clear) |
| 1B.6 | pending | — | — | service selection + housekeeping (ClipboardReader, DoS cap) |

## Quality Gate Reports

### QGR — iteration-complete 1B.2 (commit `b539144`, hash E `d65f1d9`)

**Receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-app-mdpal-mdpal-app-qgr-iteration-complete-20260417-0937-d65f1d9.md`
**Hash chain:** A `daa1f4b` → B `63ff916` → C `4b67dd1` → D `4b67dd1` (auto-approved) → E `d65f1d9`
**Base:** `8f80b7a` (Phase 1B.1)

**Issues Found and Fixed (12):**

| # | Category | Sev | Description | Fix |
|---|----------|-----|-------------|-----|
| 1 | reviewer-test | HIGH | No empty-sections coverage | Added empty-JSON test |
| 2 | reviewer-test | HIGH | No 3+-level deep-nesting end-to-end test | Extended happy-JSON to 3 levels; assert depth-first over 4 nodes |
| 3 | reviewer-test | MEDIUM | Missing required-field test (keyNotFound path) | Added test with JSON lacking versionId |
| 4 | reviewer-test/design | MEDIUM | Test helper leaked tmp dir on init throw; caller-defer burden | Rewrote as `withRealCLIServiceForTesting(result:body:)` — closure-owning, helper owns defer |
| 5 | reviewer-test | MEDIUM | Test helper didn't pass `fallbacks: []` — host-state risk | Extended RealCLIService init to accept `fallbacks:`; test helper passes `[]` |
| 6 | reviewer-code/design | LOW (forward-risk) | `JSONDecoder()` no iso8601 — 1B.3 Comment/Flag Date would silently fail | Hoisted shared `static let decoder` with `.iso8601` into RealCLIService |
| 7 | reviewer-design/test | LOW | Stdin-nil assertion used `throw TestFailure`, misleading "0 bytes" msg | Swapped to `expectNil` |
| 8 | reviewer-design | LOW | Stub msg "Phase 1B.3+" inconsistent scope signal | Reworded "not yet implemented" |
| 9 | reviewer-design | LOW | Header "Updated:" stale / missing scope caveat | Updated RealCLIService + ModelTests headers |
| 10 | own review | LOW | Fixture `count: 3` contradicted dispatch #23 (top-level) | Corrected to `count: 2` |
| 11 | reviewer-code | LOW | count/versionId discard not documented | Added docstring block |
| 12 | reviewer-design | LOW (deferred note) | `runCommand<T>` scaling note for 1B.3+ | Strengthened comment |

**Deferred with rationale:** D1 runCommand<T> mutation scaling (architectural note, not bug); D3 `.notImplemented` error case (same 1B.1 deferral — enum + UI surface); S2 JSON DoS cap (1B.6 housekeeping, DefaultProcessRunner scope); S3 argv `--` (blocked on CLI flag parser, mdpal-cli #408); C8 children non-optional (merged into #3).

**Dismissed below threshold 50:** 12 findings (style, pre-existing, speculative, redundant).

**Coverage:** 60 → **66 tests**; 6 new for listSections (happy 3-level; argv; empty; non-zero exit; malformed JSON; missing required field); zero build warnings.

**Stage 1 — Parallel Review:**
- reviewer-code (general-purpose substitute): 8 findings — 1 forward-risk fix + 1 doc fix, 6 below threshold.
- reviewer-security (general-purpose substitute): 4 findings — 2 deferred, 2 speculative.
- reviewer-design (general-purpose substitute): 10 findings — 6 fixes + 1 deferred-with-stronger-comment, 3 below threshold.
- reviewer-test (general-purpose substitute): 10 findings — 3 HIGH/MEDIUM coverage + 2 MEDIUM robustness, 5 below threshold.
- reviewer-scorer (haiku substitute): scored 28 findings, 12 passed ≥50 + 1 own-review finding.
- Own review: fixture `count` mismatch with dispatch #23.

**Stages 3–8:** Six new coverage tests → green. Build clean. 66/66 passing.

Per captain #380: reviewer-* agents not invocable from this agent class; general-purpose substitutes documented as the Phase-1B-iteration interim path until captain general-purpose escalation is available.
