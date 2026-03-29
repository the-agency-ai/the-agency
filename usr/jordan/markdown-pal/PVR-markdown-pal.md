# PVR: Markdown Pal

**Date:** 2026-03-29
**Principal:** jordan
**Agent:** markdown-pal
**Status:** In Progress
**Transcript:** PVR-transcript-20260329.md

## Item 1: Core Value Proposition — ✓ RESOLVED

**Origin:** Token economics — agents rewrite entire documents when they should be doing scoped edits.

**Value prop:** A section-oriented Markdown review tool that supports:
- Structured navigation of document structure
- Scoped commenting and iteration (review state lives in the document)
- Diffing and AI-powered version comparison
- Dual-audience workflows (human GUI + agent CLI/MCP)
- Token-efficient operations (section-level reads/writes, self-contained comments)

**Scope:** General-purpose — any Markdown file that benefits from structured review (AIADLC artifacts, articles, reports, book chapters, etc.)

**Founding motivation:** Token efficiency. Agents shouldn't rewrite whole documents to change one section.

## Item 2: Target Users & Use Cases — ✓ RESOLVED

**Cornerstone:** AI-augmented workflows. Every design decision serves human:agent and agent:agent collaboration.

**Primary users:**
- **Human:agent pairs** — human reviews/directs in GUI, agent operates via CLI/MCP
- **Agent:agent pairs** — agents reviewing each other's work with structured, token-efficient operations

**Use cases:** Any Markdown artifact being collaboratively iterated — AIADLC artifacts, articles, reports, book chapters. Almost always AI-augmented.

**Also works as** a standalone Markdown editor, but that's not the design driver.

## Item 3: Platform Priority — ✓ RESOLVED

**Phase 1:** Core engine + LSP server — the foundation everything else talks to.

**Phase 2:** CLI and SwiftUI app in parallel — both are clients of the engine/LSP.

**Rationale:** Engine is the brain, CLI and app are surfaces. Build the brain first, then the interfaces simultaneously.

## Item 4: Bundle Format (.mdpal) — ✓ RESOLVED

**Go.** The `.mdpal` bundle format is confirmed.

**Platform:** macOS (and possibly iOS) — Apple ecosystem, so symlinks, FileWrapper, and package UTTypes are all natively supported.

**Git:** Track everything normally. These are small text files (~20-30K). No special strategy needed.

**Feasibility concerns (r001, r004, r006):** Largely dissolved by the platform choice. Don't solve problems that don't exist yet.

## Item 5: Agent Interface Priority (CLI / MCP / LSP)

*Active — in progress*

## Item 6: V1 Scope

*Pending*

## Item 7: Research Comments (r001-r009) — Resolution Strategy

*Pending*

## Item 8: Relationship to The Agency

*Pending*

## Item 9: Competitive Landscape / Why Build This

*Pending*
