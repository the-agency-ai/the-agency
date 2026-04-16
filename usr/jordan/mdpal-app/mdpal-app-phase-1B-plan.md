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

### 1B.2 — Read-side commands (sections, read, comments, flags)
**Scope:** Implement the four read-only methods. Each command: build argv, run process, parse JSON stdout into the declared return type. Non-zero exit → `CLIServiceError.executionFailed`.
**Deliverable:** App can open a bundle and render section list, read content, comments, flags — all through the real CLI when selected.
**Tests:** For each command: one happy-path parse test with a recorded CLI JSON fixture; one malformed-JSON test → `.parseError`; one non-zero-exit test → `.executionFailed`.
**Fixture strategy:** check-in JSON samples under `Tests/Fixtures/cli/` — these are the contract the app compiles against.

### 1B.3 — Edit (version-hash conflict envelope)
**Scope:** Implement `editSection`. Key design call: how does CLI signal `versionConflict`? Dispatch #407 will answer; until then, design assumes a structured stderr or a specific non-zero exit + JSON error body. The plan contains a parser boundary so changing the envelope is a one-file swap.
**Deliverable:** Edit happy-path + typed `versionConflict` → existing Phase 1A conflict alert still drives correctly.
**Tests:** happy-path; versionConflict envelope → `.versionConflict(slug:expectedHash:currentHash:)`; generic failure → `.executionFailed`.

### 1B.4 — Mutation commands (add-comment, resolve-comment, flag, clear-flag)
**Scope:** Four mutation commands. Pattern is same as 1B.2 (argv + JSON parse + error envelope).
**Deliverable:** All sheet surfaces from Phase 1A work end-to-end against CLI.
**Tests:** For each: happy-path + one error path. Coverage is pragmatic — the process/parse machinery is shared.

### 1B.5 — Service selection + runtime switch
**Scope:** Wire the app so `RealCLIService` is the default when a CLI is available, `MockCLIService` stays for previews/tests and as an explicit fallback (env var or launch flag). No hardcoding — the selection lives in one place.
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

## Open questions pending #407 reply

1. Wire-format drift vs #23 for each command.
2. `versionConflict` signalling mechanism.
3. CLI binary install path.
4. Bundle path mechanics (absolute/relative/both).
5. Stderr structure for errors.
