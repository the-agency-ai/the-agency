---
type: handoff
agent: the-agency/jordan/mdslidepal-mac
workstream: mdslidepal
date: 2026-04-12
trigger: initial-setup
---

## Resume — mdslidepal-mac Initial Handoff

### Immediate — Phase 1 (no Monday deadline)

**Your mission:** Build mdslidepal-mac — a native macOS slide presentation app. You have no hard deadline. Plan properly, execute properly, ship quality.

### What to do FIRST

1. Read the plan: `claude/workstreams/mdslidepal/plan-mdslidepal-mac-20260411.md` — this has your PVR, A&D, and 5-phase plan. Follow it.
2. Read the contract: `claude/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` (v1.3) — this is THE spec. You honor the FULL contract (not the web MVP subset).
3. Look at the fixtures: `claude/workstreams/mdslidepal/fixtures/` — your MVP must pass ALL 8 fixtures across your 5 phases.
4. Look at the themes: `claude/workstreams/mdslidepal/themes/` — you must consume both `agency-default.json` and `agency-dark.json`.

### Source tree

Create your code at `apps/mdslidepal-mac/`. This is your implementation directory (RSL licensed). Follow the SPM layout matching `apps/mdpal-app/` precedent: `Package.swift`, `Sources/`, `Tests/`.

### Tech stack (locked per plan and contract)

- SwiftUI-first + AppKit interop for multi-display presenter mode
- `swift-markdown` (Apple, cmark-gfm) — Ink and MarkdownUI DISQUALIFIED
- `HighlightSwift` — Highlightr DISQUALIFIED
- `Yams` for YAML front-matter
- `PDFKit` + SwiftUI `ImageRenderer` for PDF export
- SPM-managed, macOS 14+ (Sonoma) target
- Single `.app` bundle, universal binary (x86_64 + arm64)
- GUI only for MVP — no companion CLI binary (Decision 4)

### Key constraints

- **AST-based slide detection.** Walk `swift-markdown`'s `document.children` for top-level `ThematicBreak` nodes. Do NOT use line-based splitting.
- **Front-matter pre-extraction.** Strip `---…---` at offset 0 before passing to swift-markdown parser (it doesn't handle YAML front-matter natively). The closing `---` must NOT become a slide break.
- **Theme loader.** Read JSON from `claude/workstreams/mdslidepal/themes/{name}.json`, map to SwiftUI environment values or a `Theme: Codable` struct.
- **Both themes.** `agency-default` AND `agency-dark` in your MVP.
- **Presenter mode.** Multi-display via AppKit interop (`NSScreen`/`NSWindow`). Two `WindowGroup`s: audience view + presenter view.
- **All 8 fixtures.** Your MVP passes every fixture in the corpus.

### 5-Phase plan (from your plan document)

1. Core renderer + slide model + theme loader (fixtures 01, 02, 03, 05)
2. Window and file-load UI (fixtures 04, 06)
3. Presentation + presenter mode with multi-display (fixture 07)
4. PDF export
5. Additional themes + polish + Phase 2 contract parity

### Commit protocol

Use `/iteration-complete` at iteration boundaries. Commit to your branch (`mdslidepal-mac`). Captain will review and merge via PR.
