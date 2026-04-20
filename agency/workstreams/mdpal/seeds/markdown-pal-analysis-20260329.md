# Markdown Pal — Analysis

**Date:** 2026-03-29
**Seed:** `markdown-pal-seed-20260329.md` (design doc v0001.0003)

## What Is It?

Markdown Pal is a section-oriented review tool for structured markdown documents. It tracks review comments, unresolved questions, and design decisions as YAML metadata embedded in the document itself.

The key insight: **the document IS the review artifact**. No separate review tool, no external system. The review lives inside the document, using markdown-pal's own conventions.

## Relationship to Agency 2.0

Markdown Pal is complementary to the Agency's ref-injector and document lifecycle patterns:
- Agency uses refs (QUALITY-GATE.md, etc.) for process documentation
- Markdown Pal could provide structured review OF those refs
- The YAML metadata block pattern could inform how we track design decisions (DD-N)

## Architecture Notes

- Swift/SwiftUI native (macOS + iOS)
- Document bundle format (`.mdpal` package)
- Uses Apple's `ReferenceFileDocument` + `FileWrapper`
- On-device processing, no cloud dependency
- Open research items on: symlink fallback (r001), DocumentGroup + UTType (r004), git integration (r006)

## Key Open Questions from Seed

1. **Bundle feasibility** — Can SwiftUI's document APIs handle package documents cleanly on both macOS and iOS? (r004)
2. **Git integration** — Is it redundant to track revisions in-app when git provides version history? (r006)
3. **PROP-0008 overlap** — PROP-0008 is a web-based markdown review tool. Markdown Pal is CLI/LSP-native. They're complementary, not competing.

## Next Steps

1. Resolve the 9 research comments (r001-r009) in the seed document
2. Determine which platform to start with (macOS CLI vs. native app)
3. Design the CLI/LSP interface for Claude Code integration
