---
type: qgr
boundary: iteration-complete
phase-iteration: "1.2"
stage-hash: f65a963
date: 2026-04-07
agent: the-agency/jordan/mdpal-cli
---

## Quality Gate Report — Iteration 1.2: Document + Metadata

### Issues Found and Fixed

| ID | Category | File | Description | Red→Green |
|----|----------|------|-------------|-----------|
| 1 | Code | MetadataSerializer.swift | YAML key order non-deterministic via `[String: Any]` — broke diff stability | Tests: `metadataSerializerDeterministicKeyOrder`, `metadataSerializerKeyOrderWithFullData`, `documentSerializeIdempotent` |
| 2 | Code | MetadataSerializer.swift | Numeric type casts (`as? Int`) failed for Yams' Int64/UInt/NSNumber | Test: `metadataSerializerAcceptsStringifiedVersion` (parseInt accepts multiple types) |
| 3 | Code | MetadataSerializer.swift | Resolved/unresolved detection by `response` field promoted unresolved comments with stray fields | Test: `metadataSerializerUnresolvedListIgnoresStrayResponseField` |
| 4 | Code | Document.swift | Empty file extension produced confusing `"."` lookup | Test: `documentContentsOfFileExtensionlessThrowsUnsupportedFormat` |
| 5 | Code | MetadataSerializer.swift | DateFormatter without POSIX locale could produce wrong years on non-Gregorian default calendars | Fixed in `makeDateOnlyFormatter` |
| 6 | Design | Document.swift | Two designated initializers duplicated metadata extraction + parse logic | Refactored to one designated init with optional `filePath` |
| 7 | Design | Core/EngineError.swift | Comment* error cases declared but never thrown — dead code | Removed; will land in iteration 1.3 with section operations |
| 8 | Design | Core/EngineError.swift | `fileError(path: "<no file>")` for save() without path was misleading | Added `noFilePath` case |
| 9 | Test | DocumentTests.swift | Tautological EngineError tests (constructed enum cases and pattern-matched same case) | Replaced with production-throwing tests asserting specific cases |
| 10 | Test | DocumentTests.swift | Round-trip test only checked count + text — silent field loss possible | Tightened to assert every field on comments, flags, and resolution |
| 11 | Test | MetadataSerializer.swift | Unknown Priority silently fell back to `.normal` | Now throws metadataError; test: `metadataSerializerRejectsUnknownPriority` |
| 12 | Test | DocumentTests.swift | Stale 2024 timestamp labeled as 2026 in round-trip fixture | Fixed: 1_775_390_400 = actual 2026-04-07T12:00:00Z |
| 13 | Code | Document.swift | Trailing newline trim was fragile (`while hasSuffix("\\n\\n\\n")`) | Replaced with deterministic strip-all-whitespace + append `\n` |

### Quality Gate Accountability

| ID | Source | Confidence | Status |
|----|--------|-----------|--------|
| 1 | reviewer-code #6, reviewer-design #7 | 95 | Fixed |
| 2 | reviewer-code #9 | 80 | Fixed |
| 3 | reviewer-code #10 | 85 | Fixed |
| 4 | reviewer-code #1, reviewer-design #4 | 75 | Fixed |
| 5 | reviewer-code #13 | 70 | Fixed |
| 6 | reviewer-design #3 | 80 | Fixed |
| 7 | reviewer-test #1 (dead code) | 85 | Fixed (deferred to 1.3) |
| 8 | reviewer-design #18 | 65 | Fixed |
| 9 | reviewer-test #1 | 90 | Fixed |
| 10 | reviewer-test #5 | 85 | Fixed |
| 11 | reviewer-test #20 | 70 | Fixed |
| 12 | reviewer-test #8 | 70 | Fixed |
| 13 | reviewer-code #2, reviewer-design #16 | 70 | Fixed |
| - | reviewer-design #1,2 (ParserRegistry singleton) | 60 | Accepted — works for 1.2 scope; testability concerns deferred |
| - | reviewer-security #1 (path validation) | 50 | Deferred — A&D note: local CLI trust boundary |
| - | reviewer-security #3 (YAML size cap) | 50 | Deferred — local CLI trust boundary |
| - | reviewer-design #15 (Flag/ folder for 1 file) | 30 | Rejected — parallel structure with Comment/ is fine |
| - | reviewer-design #17 (DocumentInfo naming) | 25 | Rejected — A&D specifies the name |

### Coverage Health

| Area | Before | After |
|------|--------|-------|
| CommentType + Priority | 0 | 3 |
| Comment + Resolution | 0 | 2 |
| CommentFilter | 0 | 7 (incl. author, combined AND, by section/type/priority) |
| Flag | 0 | 1 |
| DocumentInfo + DocumentMetadata | 0 | 3 |
| MetadataSerializer round-trip | 0 | 4 |
| MetadataSerializer key ordering | 0 | 2 |
| MetadataSerializer error paths | 0 | 9 (malformed, missing fields, unknown enums, type mismatches) |
| MetadataSerializer list-membership semantics | 0 | 2 |
| Document init (library mode) | 0 | 2 |
| Document file I/O | 0 | 4 (read+save, save(to:), file-not-found, unsupported format, extensionless, save without path) |
| Document serialize round-trip | 0 | 2 (round-trip + idempotent) |
| ParserRegistry | 0 | 4 |
| EngineError specific cases | 0 | 5 (production-thrown) |
| **New tests in 1.2** | **0** | **47** |
| **Total (with 1.1)** | **33** | **80** |

### Checks

| Check | Result |
|-------|--------|
| `swift build` | Pass |
| `swift test` (80 tests) | Pass |

### Quality Gate Summary

**Stage 1 — Parallel Review**
- reviewer-code: 18 findings (YAML key ordering, numeric casts, list-membership bug, dot handling, locale, trailing trim, etc.)
- reviewer-security: 7 findings (path validation, YAML size, file overwrite — mostly deferred for local CLI scope)
- reviewer-design: 17 findings (init duplication, ParserRegistry singleton, naming, mutual exclusion in CommentFilter, etc.)
- reviewer-test: 27 findings (tautological tests, weak assertions, missing-field coverage gaps, type mismatches, stale timestamp)
- reviewer-scorer: filtered against ≥50 confidence threshold; pragmatic acceptance based on iteration scope
- Own review: validated bugs, identified iteration boundaries (defer 1.3-scope items)

**Stage 2 — Score & Consolidate**: 13 findings actionable in 1.2; 4 deferred with rationale; 2 rejected.

**Stage 3 — Bug-Exposing Tests**: 13 issues. For code issues, wrote tests that fail before the fix.

**Stage 4 — Fix Issues**: All 13 fixed; tests confirm green.

**Stage 5 — Coverage Review**: Identified 10 additional coverage gaps from reviewer-test.

**Stage 6 — Coverage Tests**: All 10 added.

**Stage 7 — New Issues**: None — all new tests pass on first run.

**Stage 8 — Confirm Clean**: Build pass, 80/80 tests pass.

### What Was Found and Fixed

The QG caught the **deterministic YAML output bug** (most critical — would have caused dirty diffs and test flakiness on every save), the **resolved/unresolved list-membership bug** (which would have silently moved comments between lists on round-trip), and 11 other code/test/design issues.

A meaningful chunk of design feedback was about **dead code from forward-looking error cases** (`commentNotFound`, `commentAlreadyResolved`, `sectionNotFlagged`) that were defined for iteration 1.3 but landed in 1.2. Per "no dead code," removed them — they'll be added back in 1.3 when the operations that throw them land.

Security review found path/YAML/file-overwrite concerns that are appropriate to defer for a local CLI v1 — added to the iteration 1.3 / future hardening backlog.

### Proposed Commit

```
Phase 1.2: feat: Document model with comments, flags, and YAML metadata

Document reference type wraps the section tree, DocumentMetadata
(unresolved/resolved comments, flags, document info), and a parser. Library
mode (content+parser) and CLI mode (contentsOfFile via ParserRegistry).
Comment value type with type/priority/tags/resolution. Flag value type.
MetadataSerializer with deterministic Yams Node output, list-membership
semantics for resolved/unresolved, robust numeric/date parsing, and POSIX
locale. EngineError expanded with unsupportedFormat and noFilePath cases.
47 new tests, 80 total. Iteration 1.1 SectionInfo design retained for 1.3.
```

### Files

NEW (12):
- apps/mdpal/Sources/MarkdownPalEngine/Comment/Comment.swift
- apps/mdpal/Sources/MarkdownPalEngine/Comment/CommentFilter.swift
- apps/mdpal/Sources/MarkdownPalEngine/Comment/CommentType.swift
- apps/mdpal/Sources/MarkdownPalEngine/Comment/NewComment.swift
- apps/mdpal/Sources/MarkdownPalEngine/Comment/Priority.swift
- apps/mdpal/Sources/MarkdownPalEngine/Comment/Resolution.swift
- apps/mdpal/Sources/MarkdownPalEngine/Document/Document.swift
- apps/mdpal/Sources/MarkdownPalEngine/Document/DocumentInfo.swift
- apps/mdpal/Sources/MarkdownPalEngine/Document/DocumentMetadata.swift
- apps/mdpal/Sources/MarkdownPalEngine/Document/ParserRegistry.swift
- apps/mdpal/Sources/MarkdownPalEngine/Flag/Flag.swift
- apps/mdpal/Sources/MarkdownPalEngine/Metadata/MetadataSerializer.swift

MODIFIED (3):
- apps/mdpal/Sources/MarkdownPalEngine/Core/EngineError.swift (expanded cases)
- apps/mdpal/Sources/MarkdownPalEngine/Parser/MarkdownParser.swift (Markdown.Document qualification)
- apps/mdpal/Tests/MarkdownPalEngineTests/DocumentTests.swift (47 new tests)

ALSO STAGED:
- apps/mdpal/Package.resolved (Yams already in deps; resolved file may have updated)
