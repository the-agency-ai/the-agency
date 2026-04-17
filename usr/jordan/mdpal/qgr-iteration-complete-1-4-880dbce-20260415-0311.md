---
type: qgr
boundary: iteration-complete
phase-iteration: "1.4"
stage-hash: 880dbce
date: 2026-04-15
agent: the-agency/jordan/mdpal-cli
---

## Quality Gate Report — Iteration 1.4: Bundle Management (FINAL)

### Issues Found and Fixed

| ID | Category | File | Description | Status |
|----|----------|------|-------------|--------|
| 1 | Code | VersionId.swift | `Int(_:)` accepts leading `+`/`-` signs — `V+001.0003.20260407T1200Z` parsed as version 1 | Added `isASCIIDigit` check before Int() |
| 2 | Code | VersionId.swift | DateFormatter allocated per parse/format call (perf hit on revision walks) | Cached at static scope (thread-safe for read-only formatting) |
| 3 | Code | BundleConfig.swift | `prune.auto` silently defaulted when wrong type — config bugs hidden | Now throws metadataError on non-bool; absent still defaults to false |
| 3a | Code | BundleConfig.swift | `prune.keep` not bounds-checked at parse time (negative or zero passed) | Now throws metadataError on `keep <= 0` |
| 4 | Design | EngineError.swift, DocumentBundle.swift | `bundleConflict` used for path validation (wrong taxonomy) | Added `invalidBundlePath(path:reason:)` case; updated 4 sites |
| 5 | Design | DocumentBundle.swift | `listRevisions` docstring claimed "rejects unrecognized files" but silently skipped | Updated docstring to match actual silent-skip behavior with rationale (users may legitimately drop README.md, .DS_Store) |

### Test Coverage Added

| ID | Test | Description |
|----|------|-------------|
| 7 | `pruneAbortsWhenLatestChangesDuringPrune` | Validates prune gate via sequential prune semantics |
| 8 | `autoPruneTriggersOnCreateRevision` | Sets `auto=true`, creates 5 revisions, asserts only 2 survive |
| 9 | `bundleOpenWithCorruptConfigThrows` | Garbage YAML → metadataError |
| 9a | `bundleOpenWithMissingConfigFieldsThrows` | Valid YAML missing `prune` → metadataError |
| 10 | `reloadAfterWriteSeesNewContent` | Reopens bundle from disk, verifies revision content survived |
| 11 | `listRevisionsSkipsNonRevisionMdFiles` | README.md, notes.md, malformed V*.md all skipped |
| 11a | `listRevisionsSkipsLatestSymlink` | latest.md not counted as a revision |
| 12 | `emptyBundleLatestRevisionReturnsNil` | Empty bundle returns nil |
| 12a | `emptyBundleCurrentDocumentThrows` | currentDocument throws bundleConflict on empty |
| 12b | `bumpVersionOnEmptyBundleStartsAtV1` | bumpVersion on empty starts at V0001.0001 |
| 13 | `revisionRenumbersAfterPreExistingFile` | Auto-renumbers past phantom files (collision avoidance) |
| 14 | `bundleConfigYAMLSnapshotMatchesExpected` | Full literal YAML snapshot equality |
| 14a | `bundleConfigYAMLDefaultsSnapshotMatchesExpected` | Defaults snapshot equality |
| 15 | (covered by 14/14a) | Determinism via literal expected snapshot |
| #1-extra | `versionIdRejectsLeadingPlusSign`, `versionIdRejectsLeadingMinusSign` | Confirm sign rejection |
| #3-extra | `bundleConfigRejectsAutoAsString`, `bundleConfigRejectsAutoAsInt`, `bundleConfigAcceptsAutoAbsentAsFalse`, `bundleConfigRejectsZeroKeep`, `bundleConfigRejectsNegativeKeep` | Confirm strict typing |

### Quality Gate Accountability

| ID | Source | Confidence | Status |
|----|--------|-----------|--------|
| 1 | reviewer-code (1.4 round) | 75 | Fixed |
| 2 | reviewer-design (1.4 round) | 80 | Fixed |
| 3 | reviewer-code | 80 | Fixed |
| 3a | reviewer-security | 70 | Fixed (bonus — fail-fast at parse) |
| 4 | reviewer-design | 75 | Fixed |
| 5 | reviewer-design | 70 | Fixed (docstring corrected; silent-skip is correct V1 behavior) |
| 7-15 | reviewer-test | various | All 9 test gaps covered (some folded together) |

### Coverage Health

| Area | Before | After |
|------|--------|-------|
| VersionId | 5 | 7 (+leading sign rejection) |
| BundleConfig | 5 | 11 (+strict types, +snapshots) |
| DocumentBundle.create | 3 | 3 (kept, error case taxonomy fixed) |
| DocumentBundle.init | 4 | 4 (kept, error case taxonomy fixed) |
| listRevisions | 2 | 4 (+filtering, +symlink skip) |
| Empty bundle paths | 0 | 3 |
| Reload-after-write | 0 | 1 |
| Auto-prune | 0 | 1 |
| Prune renumbering | 0 | 1 |
| Corrupt config | 0 | 2 |
| **Bundle tests in 1.4** | **31** | **51** (+20) |
| **Total** | **155** | **175** |

### Checks

| Check | Result |
|-------|--------|
| `swift build` | Pass |
| `swift test` (175 tests) | Pass |

### Quality Gate Summary

**Stages 1-2 (run in prior session):** 4 reviewers (code, security, design, test) ran in parallel against the iteration 1.4 source. 15 actionable findings identified.

**Stage 3-4 (this session):** Fixed all 6 source/design findings.
- Source: VersionId leading-sign rejection, DateFormatter caching, BundleConfig strict auto + keep>0 validation
- Design: invalidBundlePath error case introduced, 4 sites migrated, listRevisions docstring corrected

**Stage 5-6 (this session):** Wrote 9 missing test scenarios (some folded into combined tests, totaling 20 new test methods).

**Stage 7 (this session):** No new issues surfaced.

**Stage 8 — Confirm Clean:** Build pass, 175/175 tests pass.

### What Was Found and Fixed

This QG round closes out iteration 1.4 by:
1. Hardening the version-ID parser against malformed sign-prefixed strings
2. Making BundleConfig YAML decode strict about field types
3. Introducing a proper error case (`invalidBundlePath`) distinct from runtime `bundleConflict`
4. Adding test coverage for every previously-uncovered code path (corrupt config, empty bundle, auto-prune, reload-after-write, listRevisions filtering, snapshot equality)
5. Caching the DateFormatter for any future hot path

The append-only invariant docstring update was already done in the prior session. The concurrent-write gate is exercised via sequential prune semantics (true concurrency would require thread orchestration).

### Proposed Commit

```
Phase 1.4: feat: bundle management — DocumentBundle, revisions, prune, dual latest

DocumentBundle wraps the .mdpal directory with create/open, listRevisions
(silent-skip non-revision files with documented rationale), createRevision
(refuses overwrite via fileExists guard), bumpVersion, currentDocument,
updateConfig, prune (merges resolved comments forward, gates on concurrent
writers). Dual-latest mechanism: latest.md symlink (atomic POSIX rename) +
.mdpal/latest pointer file (reconciled on open if they diverge after a
crash). BundleConfig with deterministic Yams Node encoding and STRICT type
validation (auto must be bool, keep must be > 0). VersionId helper for
parse/format with explicit ASCII-digit check (rejects +001/-001) and
cached DateFormatter. RevisionInfo and PruneResult value types. Auto-prune
surfaces failures to stderr instead of swallowing them. New EngineError
case invalidBundlePath distinguishes structural validation from runtime
bundleConflict.

Source + 51 bundle tests passing (175 total). Full QG: 6 source/design
findings fixed, 9 test gaps covered. Iteration 1.4 closes Phase 1.

Co-Authored-By: Claude <noreply@anthropic.com>
```
