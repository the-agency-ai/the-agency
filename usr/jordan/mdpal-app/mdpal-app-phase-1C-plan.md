---
type: plan
phase: 1C
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-17
captain_directive: dispatch #380 (phase scope), #399 (PR cadence), #566 (queue position)
---

# Phase 1C — Persistence + 1B carry-forwards

## Goal

Land the persistence layer: save/restore bundle state via `mdpal revision create` + `mdpal history` + `mdpal version {show,bump}`. Absorb the carry-forward items that accumulated during Phase 1B QGs so they don't rot.

Per captain #399: this phase's completion is the **second mdpal-app PR**.

## Non-goals

- **Live NSTextView selection** — Phase 2.
- **Diff-in-conflict alert** — Phase 2.
- **Per-error-type alert styling** — Phase 2.
- **XCUITest harness** — Phase 2.
- **Sync between bundles** (cloud, git-backed) — future phase, not enumerated.

## Inputs

- `CLIServiceProtocol` — Phase 1B made all 9 methods real; Phase 1C EXTENDS the protocol with persistence-related methods (see iteration 1C.3 below).
- mdpal-cli Phase 2.3 shipped (per #179). Phase 2.4 (create, history, version, revision, diff, prune, refresh) is next per mdpal-cli #579 — will land in parallel; 1C iterations that depend on specific commands will be ordered against mdpal-cli's 2.4 progress.
- Dispatch #23 wire format remains authoritative. `mdpal revision create` returns `{versionId, version, revision, timestamp, filePath}` on success, `bundleConflict` envelope on exit 4 when `--base-revision` is stale.
- Models in place: `BundlePath`, `EditResult`, etc. New models needed: `BundleInfo` / `RevisionInfo` / `VersionInfo`.

## Dependencies / blockers

- **mdpal-cli Phase 2.4** for end-to-end validation of revision/history commands. Not blocking: 1C iterations draft against dispatch #23 spec with `FakeProcessRunner` + canned JSON (same pattern as 1B).
- **The existing `mdpal edit` path** creates a revision implicitly (engine side). Phase 1C's `mdpal revision create` is for explicit user-driven revision points.

## Iteration plan

All iterations on the `mdpal-app` branch. PR lands after phase-complete.

### 1C.1 — `cliResolution` UI banner (carry-forward from 1B.6)
**Scope:** `MarkdownDocument.cliResolution` is plumbed but unused. Add a thin banner above `ContentView` when resolution is `.mockRequested` or `.mockFallback`. Banner text is case-specific: "Running in mock mode" for requested, "`mdpal` CLI not found — running with mock data" for fallback.
**Deliverable:** visible indicator whenever the app is NOT on real CLI.
**Tests:** pure function deriving banner text from Resolution.

### 1C.2 — `commentNotFound` typed mapping (carry-forward from 1B.5)
**Scope:** mdpal-cli #579 confirmed `commentNotFound` envelope shipped in Phase 2.3 (exit 3, `{error:"commentNotFound", details:{commentId:...}}`). Add `.commentNotFound(commentId:)` to `CLIServiceError`; extend `CLIErrorDetails` with matching case; wire `resolveComment` to use `runCommandWithEnvelope` with a mapper.
**Deliverable:** typed error reaches `DocumentModel.resolveComment` → UI can render a useful message.
**Tests:** envelope decode, service mapping, model propagation.

### 1C.3 — Protocol extension: revision + history + version
**Scope:** Add to `CLIServiceProtocol`:
```swift
func createRevision(bundle: BundlePath, content: String, baseRevision: String?) async throws -> RevisionInfo
func listHistory(bundle: BundlePath) async throws -> [RevisionInfo]
func showVersion(bundle: BundlePath) async throws -> VersionInfo
func bumpVersion(bundle: BundlePath) async throws -> VersionInfo
```
Add models `RevisionInfo`, `VersionInfo`, `HistoryResponse`. `MockCLIService` implements stubs returning realistic canned data; `RealCLIService` implements against dispatch #23 wire format.

### 1C.4 — Save flow: DocumentModel.createRevision wiring
**Scope:** `MarkdownDocument.fileWrapper` (explicit save) calls `model.createRevision(...)` which routes through CLIServiceProtocol. Auto-save (FileWrapper only) stays CLI-free per A&D. `bundleConflict` on exit 4 → typed `.bundleConflict` → UI prompt to reload/retry.
**Deliverable:** Cmd+S creates a revision, history entry appears.
**Tests:** save-path happy, bundleConflict envelope, stale base-revision handling.

### 1C.5 — History drawer UI
**Scope:** Minimal drawer/sheet showing revision list (version, revision, timestamp). Clicking a revision shows an alert with `filePath` — no diff, no rollback yet (Phase 2).
**Deliverable:** user can see the bundle's revision history.
**Tests:** HistoryView tests pending XCUITest harness; service-level coverage via 1C.3.

### 1C.6 — Housekeeping + service selection tests + phase-close
**Scope:** adopt `--text-stdin` / `--response-stdin` for long bodies (carry-forward from 1B QG); finalize any loose ends; `/phase-complete`.

## Cross-repo items still pending

- `--` separator adoption (decide during 1C if we actually need it; mdpal-cli treats via ArgumentParser natively).
- `--text-stdin` / `--response-stdin` adoption (lands in 1C.6).
- `.notImplemented` error case — decide whether to introduce in 1C (only useful if new stubs land; the current 9 methods are all real).
- Task-cancellation → child-process-termination in `DefaultProcessRunner` — lands alongside the first actually-cancellable caller (e.g., a background `mdpal prune` for very large bundles; probably Phase 2).

## Quality-gate policy

Same as 1B: general-purpose reviewer substitutes for iteration QGs (captain #380 interim); formal reviewer-* via captain general-purpose escalation for phase QG if available.
