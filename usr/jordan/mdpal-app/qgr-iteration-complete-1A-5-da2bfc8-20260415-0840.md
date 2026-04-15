# Quality Gate Report — iteration-complete 1A.5

**Boundary:** iteration-complete
**Phase/Iteration:** 1A.5 — Add-Comment context picker (clipboard-backed prefill)
**Stage hash:** `da2bfc8`
**Date:** 2026-04-15 08:40

## Issues Found and Fixed

| ID | Category | Severity | Description | Fix |
|----|----------|----------|-------------|-----|
| — | — | — | None found | N/A |

## Quality Gate Accountability

| Finding | Raised By | Scored By | Bug-exposing test | Fix verified |
|---------|-----------|-----------|-------------------|--------------|
| N/A — no findings | Own review (reviewer-* agents not invocable from this agent class) | N/A | N/A | N/A |

## Coverage Health

| Aspect | Before | After | Delta |
|--------|--------|-------|-------|
| Total tests | 38 | 43 | +5 |
| SelectionContext tests | 0 | 5 | +5 (nil, empty, non-matching, matching trim, substring) |
| SwiftUI menu / sheet view tests | 0 | 0 | unchanged — no XCUITest harness |

## Checks

| Check | Result | Notes |
|-------|--------|-------|
| `swift build` | PASS | Clean, zero warnings |
| `swift run MarkdownPalAppTests` | PASS | 43/43 passing |
| Format / Lint | N/A | No Swift tooling configured |
| Typecheck | PASS | Part of `swift build` |
| Failing | **0** | |

## Quality Gate Summary

**Stage 1 — Parallel Review**
- reviewer-* / reviewer-scorer: not invoked (agent-class constraint).
- Own review: examined AddCommentSheet prefill init, toolbar Menu, SelectionContext + ClipboardReader helpers, and 5 new tests.

**Stage 2 — Scoring & consolidation**
- 0 findings.

**Stage 3–4 — Bug-exposing tests / Fixes**
- N/A.

**Stage 5–6 — Coverage tests**
- `SelectionContext.extract` exercised across five cases: nil input, empty/whitespace input, non-matching clipboard (the safety case — rejects unrelated URLs/secrets), matching clipboard (trims whitespace/newlines), and substring across words. These are the exact behaviors the "Comment on Selection" menu action depends on.

**Stage 7 — New issues**
- None.

**Stage 8 — Clean**
- Build clean, 43/43 passing.

## What Was Found and Fixed

Iteration 1A.5 adds a "Comment on Selection" path: user copies selected text (Cmd-C), opens the Add-Comment menu, and chooses "Comment on Selection" to pre-fill the comment's `context` field with their selection.

Design decisions:

1. **Clipboard, not live selection.** SwiftUI `Text` with `.textSelection(.enabled)` doesn't expose the current selection to code. NSViewRepresentable wrapping NSTextView would work but expands scope beyond this iteration. The clipboard path is discoverable, explicit (user controls when their selection becomes context), and avoids fighting SwiftUI. NSTextView-based live selection is deferred to Phase 2.

2. **Safety gate.** `SelectionContext.extract` only returns a prefill if the clipboard string is non-empty AND appears as a substring of the current section's content. This prevents unrelated clipboard contents (URLs, passwords, Slack messages) from leaking into a comment if a user clicks "Comment on Selection" without a relevant copy.

3. **`ClipboardReader` indirection.** NSPasteboard is wrapped so tests can substitute a fake reader. Today's tests drive `SelectionContext.extract` directly (pure function) — the reader is there for when view-level tests arrive.

4. **Toolbar Menu over two buttons.** Single primary-action menu with "Add Comment" (empty context) and "Comment on Selection" (prefilled). The second item disables itself when nothing usable is on the clipboard — the affordance stays visible but communicates unavailability. This is cleaner than cluttering the toolbar with two same-icon buttons.

5. **AddCommentSheet prefill init.** Takes optional `prefillContext`, seeds its `@State context` with that value via a custom initializer so the prefill appears on first render. A caption hint ("· prefilled from your selection") appears next to the context label when prefilled, so the user knows why the field isn't empty.

Own-review observations (none fix-worthy):
1. Substring matching is exact-case. Fine for Phase 1A; case/whitespace-insensitive matching can come later if users report friction.
2. `ClipboardReader.current` is a mutable static for test swapping — typical SwiftUI testability pattern, no concurrency hazard since view code reads on MainActor and tests are single-threaded per case.
3. `canImport(AppKit)` guard is there so the library could compile on a non-AppKit platform in the future; today it always resolves to the AppKit path on macOS.
4. View-level tests for the menu / disabled-state / sheet prefill path remain deferred (no XCUITest harness).

## Deferred findings (not blockers)

- **Live selection capture via NSTextView**: Phase 2, when an editor-grade reader lands.
- **Fuzzy / case-insensitive matching**: wait for user signal.
- **SwiftUI view tests**: awaits XCUITest harness.

## Proposed Commit

```
Phase 1A.5: feat: Add-Comment context picker — clipboard-backed prefill

Add a "Comment on Selection" path to the Add-Comment toolbar menu.
The user selects text in the reader, copies (Cmd-C), opens the
Add Comment menu, and chooses "Comment on Selection" — the comment
sheet opens with the `context` field pre-filled from their selection.

- New `SelectionContext.extract(from:within:)` pure helper — gatekeeps
  clipboard text to values that appear inside the current section,
  preventing unrelated clipboard contents (URLs, passwords) from leaking
  into comments.
- New `ClipboardReader` indirection around NSPasteboard — tests substitute
  a fake; production reads from NSPasteboard.general.
- SectionReaderView: Add-Comment toolbar becomes a Menu with two actions
  (plain Add Comment / Comment on Selection); the second disables when
  clipboard has nothing usable for this section.
- AddCommentSheet: new `prefillContext: String?` parameter, seeded into
  @State context at init; caption hint appears when prefilled.
- Tests (+5, 43 total): SelectionContext.extract across nil/empty/
  non-matching/matching-trim/substring cases.

QGR: usr/jordan/mdpal-app/qgr-iteration-complete-1A-5-da2bfc8-20260415-0840.md

Files:
- apps/mdpal-app/Sources/MarkdownPalApp/Views/SectionReaderView.swift
- apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift
```
