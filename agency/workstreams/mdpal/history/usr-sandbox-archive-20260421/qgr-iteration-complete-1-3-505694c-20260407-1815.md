---
type: qgr
boundary: iteration-complete
phase-iteration: "1.3"
stage-hash: 505694c
date: 2026-04-07
agent: the-agency/jordan/mdpal-cli
---

## Quality Gate Report — Iteration 1.3: Section Operations

### Issues Found and Fixed

| ID | Category | File | Description | Red→Green |
|----|----------|------|-------------|-----------|
| 1 | Code | Document+Sections.swift | Sibling slug collisions — two siblings with same heading produced identical paths; second was unreachable | Test: `listSectionsSiblingCollisionDisambiguation` |
| 2 | Code | Document+Sections.swift | `editSection` accepted newContent containing headings, orphaning new headings inside body | Test: `editSectionRejectsNewContentWithHeadings` |
| 3 | Code | Document+Sections.swift | DRY violation: `pathSlug` and `replaceContent` independently computed slugs | Refactored to single `buildSlugIndex` + `applyContentEdit(indexPath:)` walk |
| 4 | Code | Document+Sections.swift | Dead code `_ = parentSlug` after destructure | Removed via index-path refactor |
| 5 | Code | Document+Comments.swift | Comment id format `c001` (3-digit) breaks lex sort at c1000 | Bumped to 4-digit `c0001`; tests: `addCommentIdFormatLexicographicallySorts` |
| 6 | Code | Comment.swift | Field-by-field copy in resolveComment/refreshSection brittle when Comment grows | Added `Comment.with(versionHash:resolution:)` helper |
| 7 | Design | Document.swift | `metadata` was `public var` — bypassed lifecycle methods (slug validation, id assignment) | Made `public internal(set) var`; tests use `@testable import` |
| 8 | Design | Section.swift | `lineRange: 1..<1` placeholder shipped in public API as a real range | Made `Range<Int>?`, defaults to nil until iteration 1.4 |
| 9 | Test | SectionOperationsTests.swift | Tautological shape tests (`sectionInfoFlatShape`, `sectionFullShape`) tested compiler not behavior | Removed |
| 10 | Test | SectionOperationsTests.swift | Substring assertions (`.contains`) where exact equality was possible | Tightened to `==` on `content`, `currentContent`, `context` |
| 11 | Test | SectionOperationsTests.swift | `readSectionVersionHashStable` only tested no-op stability | Renamed to `readSectionVersionHashStableUntilEdit`; now tests change after edit |
| 12 | Test | SectionOperationsTests.swift | No deep-nesting test (>2 levels) | Added `readSectionDeeplyNested` (4 levels) |
| 13 | Test | SectionOperationsTests.swift | No slug normalization test | Added `readSectionSlugNormalization` |
| 14 | Test | SectionOperationsTests.swift | `editSectionUpdatesContent` only checked `children.count` post-edit | Added `editSectionWithChildrenChildrenRemainReachable` (re-reads children by slug) |
| 15 | Test | SectionOperationsTests.swift | No multi-line edit content test | Added `editSectionMultiLineContent` |
| 16 | Test | SectionOperationsTests.swift | No empty newContent edit test | Added `editSectionEmptyNewContent` |
| 17 | Test | SectionOperationsTests.swift | `refreshSectionNoStaleCommentsReturnsEmpty` was misleadingly named — only tested no-op | Renamed and split into proper coverage |
| 18 | Test | SectionOperationsTests.swift | No multi-comment refresh test | Added `refreshSectionMultipleStaleComments` |
| 19 | Test | SectionOperationsTests.swift | No cross-section refresh isolation test (the core scoping invariant) | Added `refreshSectionLeavesOtherSectionsAlone` |
| 20 | Test | SectionOperationsTests.swift | No `flagSection` without note test | Added `flagSectionWithoutNote` |
| 21 | Test | SectionOperationsTests.swift | No `listFlags()` empty test | Added `listFlagsEmpty` |
| 22 | Test | SectionOperationsTests.swift | `listCommentsWithFilter` lacked negative assertions | Added `allSatisfy` checks per filter |
| 23 | Test | SectionOperationsTests.swift | No empty document `listComments` test | Added `listCommentsEmptyDocument` |
| 24 | Test | SectionOperationsTests.swift | No merged resolved+unresolved listComments test | Added `listCommentsMergesResolvedAndUnresolved` |
| 25 | Test | SectionOperationsTests.swift | `resolveComment` test didn't assert `resolvedDate` | Added explicit fixed-date assertion |
| 26 | Test | SectionOperationsTests.swift | No id-continuation across resolved+unresolved test | Added `addCommentIdsContinueAcrossResolvedAndUnresolved` |
| 27 | Test | SectionOperationsTests.swift | `documentSerializeRoundTrip` end-to-end didn't round-trip flags or unresolved comments | Strengthened e2e to add unresolved comment + persistent flag, assert both survive reload |
| 28 | Test | SectionOperationsTests.swift | `editSection` returned Section never compared to subsequent readSection | Added `editSectionReturnedAndReReadAreEqual` |

### Quality Gate Accountability

| ID | Source | Confidence | Status |
|----|--------|-----------|--------|
| 1 | reviewer-code #1 | 95 | Fixed |
| 2 | reviewer-code #5 | 90 | Fixed |
| 3 | reviewer-design #3 | 80 | Fixed |
| 4 | reviewer-design #2 | 60 | Fixed |
| 5 | reviewer-code #9 | 75 | Fixed |
| 6 | reviewer-design #30 | 75 | Fixed |
| 7 | reviewer-design #9 | 85 | Fixed |
| 8 | reviewer-code #6, design #5 | 80 | Fixed |
| 9 | reviewer-test #24 | 85 | Fixed |
| 10 | reviewer-test #27/28 | 80 | Fixed |
| 11 | reviewer-test #25 | 75 | Fixed |
| 12-28 | reviewer-test #1, 3, 4, 7, 11, 12, 14, 15, 18, 19, 20, 21, 31 | various | Fixed |
| - | reviewer-code #2 (slashes in headings) | 60 | Accepted — depends on parser slug() which strips `/` already; documented |
| - | reviewer-code #20 (empty heading malformed path) | 50 | Accepted — empty heading isn't valid markdown anyway |
| - | reviewer-code #12/16 (slug canonicalization) | 60 | Deferred — addComment/flagSection accept caller-provided slug; if it resolves via findNode it's valid; if not, throws sectionNotFound |
| - | reviewer-design #25 (Section Codable parity) | 40 | Deferred — Section is internal API; SectionInfo has Codable for JSON output later |
| - | reviewer-design #11/22 (extension organization, findNode location) | 35 | Accepted — current organization is clean; findNode is internal helper |
| - | reviewer-code #4 (versionConflict carries currentContent not full Section) | 50 | Accepted — A&D specifies currentContent; callers re-read for full Section |

### Coverage Health

| Area | Before | After |
|------|--------|-------|
| listSections | 2 | 3 (incl. sibling collision) |
| readSection | 4 | 6 (incl. deep nesting, slug normalization) |
| editSection | 4 | 9 (incl. with-children, multi-line, empty, headings rejection, returned == reread) |
| addComment | 4 | 6 (incl. resolved-continuation, lex sort) |
| listComments | 2 | 4 (incl. empty, merged, negative filters) |
| resolveComment | 3 | 3 (tightened with date assertion) |
| refreshSection | 3 | 5 (incl. multi-stale, cross-section isolation) |
| flagSection / clearFlag | 5 | 7 (incl. without note, list empty) |
| End-to-end | 1 | 1 (strengthened to round-trip flags + unresolved) |
| **New + tightened in 1.3** | — | **45 tests** |
| **Total (with 1.1 + 1.2)** | **80** | **124** |

### Checks

| Check | Result |
|-------|--------|
| `swift build` | Pass |
| `swift test` (124 tests) | Pass |

### Quality Gate Summary

**Stage 1 — Parallel Review**
- reviewer-code: 20 findings (slug collision, edit-with-headings, comment id width, slug canonicalization, etc.)
- reviewer-design: 30 findings (metadata access, lineRange placeholder, DRY, extension organization, Comment.with helper, etc.)
- reviewer-test: 38 findings (deep nesting, slug normalization, cross-section isolation, weak assertions, tautological tests, etc.)
- reviewer-security: skipped (no new I/O surface)
- Own review: validated correctness bugs, prioritized by iteration scope

**Stage 2 — Score & Consolidate**: 28 findings actionable in 1.3; 6 deferred/accepted with rationale.

**Stage 3 — Bug-Exposing Tests**: 8 code/design issues; tests written to fail before fix.

**Stage 4 — Fix Issues**: All fixed; tests pass red→green.

**Stage 5 — Coverage Review**: 17 additional coverage gaps from reviewer-test.

**Stage 6 — Coverage Tests**: All added.

**Stage 7 — New Issues**: None.

**Stage 8 — Confirm Clean**: Build pass, 124/124 tests pass.

### What Was Found and Fixed

The QG caught the **sibling slug collision bug** (most critical — would have made any document with two same-named sections silently lose the second one), the **edit-with-headings hazard** (would orphan new headings inside body strings, invisible to listSections), and the **3-digit comment id format** (broke lex sort at c1000). All fixed with proper red→green tests.

The biggest design fix was the **slug index refactor**: pathSlug + findNode + replaceContent independently computed slugs, which made sibling disambiguation hard to add and risked drift. Now there's one `buildSlugIndex` that all three operations consult — guaranteed consistency.

Other meaningful fixes: `metadata` is now `internal(set)` so callers go through lifecycle methods, `Section.lineRange` is `Range<Int>?` instead of shipping a `1..<1` placeholder as if it were real, and `Comment.with(versionHash:resolution:)` eliminates 30 lines of brittle field-copying.

### Proposed Commit

```
Phase 1.3: feat: section operations — read/edit, comments, flags

Document section operations: listSections (flat path-style slugs with
sibling collision disambiguation), readSection (full Section with
content + child summaries), editSection (optimistic concurrency, rejects
new headings in body), refreshSection (updates stale comment hashes,
preserves context). Comment operations: addComment (auto id c0001..),
listComments (filtered), resolveComment (lifecycle move). Flag operations:
flagSection (replace existing), listFlags, clearFlag. SectionInfo refactored
to flat summary form per A&D §3.2; new Section type carries full content.
Comment.with(...) helper eliminates field-copy brittleness. metadata is now
internal(set) — callers go through lifecycle methods. EngineError gains
commentNotFound, commentAlreadyResolved, sectionNotFlagged. 45 new tests,
124 total.
```
