---
type: plan
workstream: mdslidepal
platform: mac
date: 2026-04-11
author: the-agency/jordan/mdslidepal-mac-planner
principal: jordan
status: draft-for-review
contract_version: v1.2
contract_ref: seed-mdslidepal-contract-20260411.md
license: MIT
version: 0.1.0
---

# mdslidepal-mac — PVR + A&D + Plan

This document plans the macOS native implementation of **mdslidepal**. It honors the shared contract (`seed-mdslidepal-contract-20260411.md`, v1.2) without the Monday deadline constraints applied to the web agent. The Mac MVP implements the **full contract** — both themes, YAML front-matter, per-slide metadata, speaker notes with presenter view, multi-display support, and PDF export.

---

## 1. PVR (Product Vision & Requirements)

### 1.1 Problem (Mac-scoped)

Jordan needs a proper native macOS authoring and presentation environment for markdown-first decks. The web version (reveal.js-wrapped) is the Monday workshop safety net, but it is not the long-term authoring home. Browser-based slides have quirks: tab focus loss, browser chrome, finicky multi-display, no real file integration, no Quick Look, no Services menu, no reliable offline behavior, no native print-to-PDF fidelity. Jordan authors decks on a MacBook; the primary experience should feel like Keynote-by-markdown — file-oriented, keyboard-first, offline-first, and fully at home on macOS.

### 1.2 Vision

mdslidepal-mac is a single `.app` bundle that opens any `.md` file as a slide deck. It runs entirely offline with zero network dependencies. It looks and feels like a native macOS 14+ application: standard menus, keyboard shortcuts, window restoration, recent-files submenu, drag-and-drop, Quick Look-style preview, and true full-screen presenter mode that routes the audience view to an external display while the presenter sees notes, timer, and next-slide preview on the laptop. Source files are plain markdown on disk — no proprietary format, no database, no sync.

The application is a reader/renderer, not an editor (per contract §14). Authors use their preferred editor (Zed, VS Code, Sublime, BBEdit) and mdslidepal-mac live-reloads on file change.

### 1.3 Functional requirements

Derived from contract §1–§12. Mac MVP is the full contract:

- **FR-1. Input** — open single `.md` files (contract §1). GFM-mandatory parsing via `swift-markdown`. YAML front-matter at offset 0 (contract §1).
- **FR-2. Slide boundaries** — AST-based `ThematicBreak` detection at document top level. Thematic breaks inside code/lists/quotes/HTML blocks are NOT slide breaks (contract §2). All degenerate cases handled (empty file, lone `---`, adjacent `---`, trailing `---`).
- **FR-3. Per-slide metadata** — `<!-- slide: ... -->` block with YAML 1.2 body, only recognized as first non-whitespace after a slide break (contract §3). Reserved keys: `background`, `transition`, `class`. `layout` and `notes_file` deferred.
- **FR-4. Speaker notes** — reveal.js bare marker `Notes:` / `Note:` (case-insensitive). Rendered in presenter view only (contract §4).
- **FR-5. Images** — local paths relative to source `.md`; remote http/https loaded directly; path-traversal (`..` escaping source dir) refused (contract §5, §11).
- **FR-6. Code blocks** — fenced blocks with language ID, syntax-highlighted via `HighlightSwift`. Minimum languages: bash, js, ts, python, swift, go, rust, markdown, json, yaml, html, css (contract §6).
- **FR-7. Commands** — `render` (File → Export → HTML or Image), `present` (File → Present / ⌘P), `export` (File → Export → PDF) (contract §7).
- **FR-8. Output** — native SwiftUI window renderer, not a WebView wrapper (contract §8).
- **FR-9. Themes** — consume `themes/agency-default.json` AND `themes/agency-dark.json` from the workstream-level directory. Implement a theme loader that maps the JSON schema to SwiftUI environment values / token struct (contract §9). 16:9 logical 1920×1080.
- **FR-10. Keyboard nav** — full set from contract §10: Right/Space/`n`, Left/`p`, Home, End, Esc, `f`, `s`, `b`/`.`, `?`.
- **FR-11. Error handling** — every error class from contract §11 table implemented as a non-modal alert (banner in main window, not a blocking modal). Slide-overflow 20% threshold honored.
- **FR-12. Fixture acceptance** — all 8 fixtures in `fixtures/` render correctly (contract §12), including `06-front-matter.md` and `07-speaker-notes.md` which are web-deferred but Mac-MVP.

### 1.4 Non-functional requirements

- **NFR-1. Performance** — cold open of a 50-slide deck < 500ms on M-series Mac. Slide transitions < 16ms (60fps). Re-render on file change < 100ms for typical decks.
- **NFR-2. Offline-first** — zero network for any MVP feature. All dependencies vendored via SPM; no runtime downloads. Remote image loading is opt-in per-image and degrades to placeholder on failure.
- **NFR-3. Native feel** — standard macOS menu bar (File/Edit/View/Window/Help), keyboard shortcuts honor Mac conventions (⌘O, ⌘W, ⌘P, ⌘,, ⌘Q), window state restored on relaunch via `SceneStorage`, File → Open Recent via `NSDocumentController`.
- **NFR-4. Accessibility** — VoiceOver labels on slide content, Increase Contrast honored (theme-aware), Dynamic Type for presenter notes pane, keyboard-only navigation for all commands.
- **NFR-5. Target** — macOS 14 (Sonoma) minimum. Universal binary (x86_64 + arm64). Signed and notarizable (actual signing credentials are a post-MVP deployment concern).
- **NFR-6. Packaging** — single `.app` bundle, SPM-managed, buildable from `swift build` or Xcode 15+.

### 1.5 What's IN MVP vs Phase 2

**MVP (Phases 1–4):** full contract §1–§12, all 8 fixtures, both themes, presenter mode with multi-display, PDF export, live-reload on file change.

**Phase 2 (deferred per contract):**
- `auto_break_on_h1` mode (contract §2)
- `layout:` slide layouts (contract §3)
- `notes_file` external notes (contract §3)
- Directory-of-files loader (contract §1)
- Custom themes beyond `agency-default`/`agency-dark` (contract §9)
- Mermaid/PlantUML diagrams (contract §14)
- mdpal AST integration (contract §"mdpal integration")
- Real-time collaboration, cloud sync, plugin system, theme marketplace (contract "Non-goals")

### 1.6 Acceptance criteria

MVP is complete when:
1. All 8 fixtures in `claude/workstreams/mdslidepal/fixtures/` open, parse, and render without errors.
2. Fixture 06 (front-matter) exposes `title`, `author`, `theme`, `date` to the theme engine and honors `theme: agency-dark` as a theme switch.
3. Fixture 07 (speaker notes) shows notes in presenter view and NEVER in the audience view.
4. Fixture 08 (edge cases) produces the expected slide count (no phantom empty slides from trailing `---`, no slide breaks from `---` inside fenced code blocks).
5. A two-display workshop rehearsal: audience view on external display, presenter view on laptop, keyboard nav works from either display, Esc returns both windows to non-presentation state.
6. File → Export → PDF produces one page per slide at 1920×1080 with correct theme colors and embedded fonts.
7. Live-reload: editing the source `.md` in an external editor updates the rendered deck within 500ms.
8. Cold start with `mdslidepal sample.md` (or double-click a `.md` file bound to the app) opens the deck in < 1s.

---

## 2. A&D (Architecture & Design)

### 2.1 High-level architecture

```
MdSlidepalApp (SwiftUI @main App)
  └── WindowGroup("Deck")
       └── DeckWindowView
            ├── FileLoader ──┐
            │                ├─> DeckDocument (Observable)
            │                │     ├── frontMatter: FrontMatter
            │                │     ├── slides: [Slide]
            │                │     └── diagnostics: [Diagnostic]
            │                │
            ├── ThemeLoader ─┘     (Slide = { index, metadata, markupNodes, notes })
            │     └── Theme (token struct, injected via @Environment)
            │
            ├── SlideListSidebar (NavigationSplitView primary)
            └── SlidePreviewPane (NavigationSplitView detail)
                  └── SlideView(slide, theme)

  └── WindowGroup("Presenter", id: "presenter", for: DeckSessionID.self)
       └── PresenterWindowView  (opened by PresentationCoordinator)
            ├── CurrentSlideView
            ├── NextSlideView
            ├── NotesPane (rendered markdown of slide.notes)
            └── TimerView

  └── AppKit interop layer (PresentationCoordinator)
       ├── NSScreen enumeration & selection
       ├── NSWindow promotion to full-screen on target display
       └── Global key event routing (main ↔ presenter)
```

**Data flow:** `FileLoader` reads the `.md` file → `MarkdownParser` (thin wrapper over `swift-markdown`) produces a `Document` AST → `FrontMatterExtractor` pulls YAML front-matter from offset 0 (if any) → `SlideSplitter` walks the AST top-level children and partitions on `ThematicBreak` nodes → `SlideMetadataExtractor` and `NotesExtractor` run per slide → `DeckDocument` published to views. `ThemeLoader` reads the JSON theme file (resolved from front-matter `theme:` or default), decodes into a `Theme` struct, and injects via `@Environment(\.theme)`.

### 2.2 Tech stack decisions

| Decision | Choice | Justification (and what was rejected) |
|---|---|---|
| UI framework | **SwiftUI-first, AppKit interop** (contract §mac, §8) | SwiftUI is the 2026 default for new macOS apps. AppKit interop is the idiomatic way to cover gaps: `fullScreenCover()` is macOS-unavailable, `NSScreen`-precise window routing is still clunky in pure SwiftUI, and global key-event capture requires `NSEvent.addLocalMonitorForEvents`. |
| Dependency manager | **Swift Package Manager** (contract §mac) | Zero CocoaPods. `Package.swift` at repo root. All deps are SPM-native. |
| Target | **macOS 14.0** (contract §mac) | Sonoma gives us `Observable` macro, `NavigationSplitView` stability, improved `AsyncImage`, and `.fileImporter` maturity. Dropping 13 removes significant SwiftUI workarounds. |
| Markdown parser | **`swift-markdown`** (`swiftlang/swift-markdown`) | Contract §1 locks this. cmark-gfm-backed, Apple-maintained, AST-native. `Ink` is stagnant and explicitly disqualified; `MarkdownUI` is a renderer (not a parser) and in maintenance mode — also explicitly disqualified. |
| GFM extension | `Markdown.ParseOptions.parseBlockDirectives` + default GFM (tables, strikethrough, task lists all built into `swift-markdown`'s cmark-gfm backend) | Contract §1 requires GFM mandatory. |
| Syntax highlighter | **`HighlightSwift`** (`appstefan/HighlightSwift`) | Contract §6 + §mac locks this. Actively maintained, SwiftUI-native, supports all contract-required languages. `Highlightr` explicitly disqualified (unmaintained in 2026). `Splash` is Swift-only, insufficient. |
| YAML parser | **`Yams`** (`jpsim/Yams`) | YAML 1.2, pure-Swift, SPM-native. Used for both front-matter and per-slide `<!-- slide: -->` bodies. |
| JSON decoding | `Foundation.JSONDecoder` with `Codable` | Zero deps. Used for theme files. |
| Image loading (remote) | Native `AsyncImage` on macOS 14+ | Built in, no deps. |
| PDF export | **PDFKit + SwiftUI `ImageRenderer`** | `ImageRenderer` (macOS 13+) renders SwiftUI views to `CGImage`/`PDFPage`; PDFKit assembles pages. Chosen over `NSPrintOperation` because we need precise control (1920×1080 per page, theme colors, no print dialog). |
| Live reload | `DispatchSource.makeFileSystemObjectSource` on source file descriptor | Native, no deps. Notify on `.write` / `.rename`; debounce 100ms; re-parse. |
| Testing | **XCTest** (unit) + **ViewInspector** (SwiftUI view tree assertions) + fixture-based snapshot comparison (text/structure, not pixels) | Vanilla Apple + one focused SwiftUI test dep. |

**Rejected alternatives:**
- **WebView wrapping reveal.js** — contract §8 explicitly forbids ("Mac agent should NOT try to build a web view wrapping reveal.js").
- **`Ink` parser** — contract §1 disqualifies.
- **`MarkdownUI` renderer** — contract §1 disqualifies; it's a renderer not a parser, and it's in maintenance mode.
- **`Highlightr`** — contract §6/§mac disqualifies.
- **Line-based slide splitting** — contract §2 requires AST-based detection. Splitting on `---` before parsing would falsely break slides on thematic breaks inside fenced code blocks (exactly what fixture 08 tests).

### 2.3 AST-based slide detection

Per contract §2: slide boundary detection runs on the AST post-parse. Algorithm:

1. `swift-markdown` parses the source to a `Markdown.Document`.
2. If front-matter is present (first line is `---`, followed by YAML keys, closed by second `---`), `FrontMatterExtractor` strips it from the source text BEFORE passing to `swift-markdown`. (This is the Jekyll/Hugo convention. `swift-markdown` does not parse YAML front-matter natively; we handle it at the file-read layer.) The terminating `---` of the front-matter is NOT a ThematicBreak because it was never seen by the parser.
3. `SlideSplitter.split(document:)` iterates `document.children` (top-level only). It accumulates child nodes into a `currentSlide` until it encounters a `ThematicBreak` node at the top level, at which point it emits the current slide and starts a new one. Because we iterate `document.children` (not descendants), thematic breaks inside code blocks, lists, block quotes, and HTML blocks are automatically ignored — they are never top-level.
4. Degenerate cases (contract §2):
   - Empty document after front-matter → emit one placeholder slide with title.
   - Lone top-level ThematicBreak with no content around it → one empty slide.
   - Two adjacent ThematicBreaks → one empty slide (collapse).
   - Trailing ThematicBreak → absorbed (do not emit a phantom final slide).
5. For each slide, `SlideMetadataExtractor` inspects the first non-whitespace child: if it's an `HTMLBlock` matching `^<!--\s*slide:\s*\n(.*?)\n-->$` (DOTALL), decode the body with Yams, validate against the reserved-keys set, and attach as `slide.metadata`. Malformed → warn in `diagnostics`, slide renders with defaults (contract §11).
6. `NotesExtractor` scans each slide's nodes for a `Paragraph` whose first line matches `^\s*Notes?:\s*$` (case-insensitive). From that paragraph onward, everything becomes `slide.notes` (a sub-document) and is removed from `slide.body`. This matches the reveal.js bare marker convention (contract §4).

### 2.4 Slide overflow handling

Per contract §11: auto-scale if < 20% overflow, vertical scroll if ≥ 20%. Implementation:

- `SlideView` measures its natural content size via `GeometryReader` + a hidden measurement pass.
- If natural size ≤ logical (1920×1080) → render at scale to fit rendering surface.
- If natural size overflows by < 20% in either dimension → apply `.scaleEffect(scale)` with `scale = min(1920/naturalW, 1080/naturalH)`, uniform.
- If overflow ≥ 20% → wrap content in `ScrollView(.vertical)` within the logical box, scale the scroll container to fit the surface. No crop, no paginate (contract §11).

### 2.5 Theme loader

`Theme` is a pure Swift struct conforming to `Codable`, shaped exactly to `themes/theme-schema.json`:

```swift
struct Theme: Codable, Equatable {
    let name: String
    let version: String
    let logicalDimensions: LogicalDimensions
    let colors: ColorPalette
    let fonts: FontStack
    let headingScale: HeadingScale
    let bodySize: Int
    let lineHeight: Double
    let spacingUnit: Int
    let slidePadding: EdgeInsets4
    let codeTheme: CodeTheme
    let transitions: Transitions
    // ... with Codable + CodingKeys mapping snake_case JSON to camelCase Swift
}
```

`ThemeLoader.load(name:)` resolves `name` to `themes/{name}.json` (bundled in `Resources/`), decodes via `JSONDecoder`, and caches by name. Hex color strings parse via a small `Color(hex:)` extension. Font stacks are split on `,`, trimmed, and passed to SwiftUI via `.font(.custom(name, size: CGFloat))` with fallback to `.system`.

The theme is injected via an `EnvironmentKey`:

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = Theme.agencyDefault  // default fallback bundled constant
}
```

Every `SlideView`, `CodeBlockView`, `HeadingView` reads `@Environment(\.theme)` and uses its tokens — no hardcoded colors, no hardcoded sizes (contract §9).

### 2.6 Presenter mode architecture

Per contract §mac ("presenter mode and multi-display window management MAY require NSViewRepresentable / NSWindow interop"):

**Two windows:**
- **Audience window** — `WindowGroup("Deck")`, content is `SlideView` only, chrome-minimal. In present mode, promoted to full-screen on the target display.
- **Presenter window** — separate `WindowGroup(id: "presenter", for: DeckSessionID.self)` opened via `@Environment(\.openWindow)`. Contains `CurrentSlideView` (scaled-down), `NextSlideView`, `NotesPane`, `TimerView`, and a thin status bar showing slide index and elapsed time.

**PresentationCoordinator** (an `@Observable` class):
- Holds a reference to both windows via `NSApplication.shared.windows` lookup keyed on window identifier.
- On `enterPresent()`: enumerates `NSScreen.screens`, picks the non-main display if present (heuristic: first screen whose `frame != NSScreen.main?.frame`), moves the audience window there via `window.setFrame(screen.frame, display: true)`, then `window.toggleFullScreen(nil)`. Presenter window stays on laptop display.
- Single-display fallback: audience window goes full-screen on the main display; presenter window is not shown (keyboard `s` toggles a combined overlay). Or, if user presses `s` explicitly, we open the presenter window on top of the audience window and the user can drag it — degraded but functional.
- Global key handler: `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` in the app delegate so keyboard navigation works regardless of which window has focus. Key codes routed to `PresentationCoordinator.handle(key:)`.
- On `exitPresent()` (Esc): exit full-screen, close presenter window, restore both windows to non-present state.

**Why AppKit interop here:** pure SwiftUI on macOS 14 cannot (a) target a specific `NSScreen` for full-screen, (b) capture keystrokes globally across two windows reliably, (c) toggle full-screen programmatically with `toggleFullScreen(nil)`. The interop is ~150 LOC concentrated in `PresentationCoordinator.swift`.

### 2.7 File layout (SPM project structure)

```
apps/mdslidepal-mac/                    (Mac app lives in apps/, not workstreams/)
├── Package.swift
├── README.md
├── Sources/
│   └── MdSlidepal/
│       ├── App/
│       │   ├── MdSlidepalApp.swift          (@main)
│       │   ├── AppCommands.swift            (menu bar commands)
│       │   └── PresentationCoordinator.swift (AppKit interop)
│       ├── Model/
│       │   ├── DeckDocument.swift            (@Observable)
│       │   ├── Slide.swift
│       │   ├── FrontMatter.swift
│       │   ├── SlideMetadata.swift
│       │   └── Diagnostic.swift
│       ├── Parser/
│       │   ├── MarkdownParser.swift          (wraps swift-markdown)
│       │   ├── FrontMatterExtractor.swift    (Yams)
│       │   ├── SlideSplitter.swift           (AST walk, contract §2)
│       │   ├── SlideMetadataExtractor.swift  (<!-- slide: --> parsing)
│       │   └── NotesExtractor.swift          (Notes: marker)
│       ├── Theme/
│       │   ├── Theme.swift                   (Codable struct)
│       │   ├── ThemeLoader.swift
│       │   ├── ColorHex.swift
│       │   └── ThemeEnvironment.swift
│       ├── Render/
│       │   ├── SlideView.swift
│       │   ├── HeadingView.swift
│       │   ├── ParagraphView.swift
│       │   ├── CodeBlockView.swift           (HighlightSwift)
│       │   ├── ListView.swift
│       │   ├── TableView.swift
│       │   ├── ImageView.swift               (local + remote, placeholders)
│       │   └── SlideScaler.swift             (overflow policy §11)
│       ├── UI/
│       │   ├── DeckWindowView.swift
│       │   ├── SlideListSidebar.swift
│       │   ├── SlidePreviewPane.swift
│       │   ├── PresenterWindowView.swift
│       │   ├── NotesPane.swift
│       │   └── TimerView.swift
│       ├── IO/
│       │   ├── FileLoader.swift
│       │   ├── FileWatcher.swift             (DispatchSource)
│       │   └── RecentFiles.swift             (NSDocumentController bridge)
│       └── Export/
│           ├── PDFExporter.swift             (ImageRenderer + PDFKit)
│           └── HTMLExporter.swift            (Phase 5, stub in MVP)
├── Resources/
│   └── Themes/
│       ├── agency-default.json               (symlink → workstream)
│       └── agency-dark.json                  (symlink → workstream)
└── Tests/
    └── MdSlidepalTests/
        ├── ParserTests.swift                 (fixtures 01, 02, 08)
        ├── FrontMatterTests.swift            (fixture 06)
        ├── NotesExtractionTests.swift        (fixture 07)
        ├── SlideSplitterTests.swift          (AST edge cases)
        ├── ThemeLoaderTests.swift
        ├── CodeBlockTests.swift              (fixture 03)
        ├── ImageTests.swift                  (fixture 04)
        ├── TableListTests.swift              (fixture 05)
        └── FixtureAcceptanceTests.swift      (all 8 fixtures, slide-count + structural)
```

**Resource symlinks to workstream themes:** the build script copies (or symlinks at dev time) `claude/workstreams/mdslidepal/themes/*.json` into `Resources/Themes/` so the `.app` bundle ships them. Source of truth remains the workstream directory (contract §9).

---

## 3. Plan — Phases and iterations

Five phases, sequential. Each phase ends in `/phase-complete` with full QG. Estimates are working days for a single agent.

### Phase 1: Core renderer + slide model + theme loader (4 days)

**Goal:** parse a `.md` file, produce a `[Slide]` array, render slides to a SwiftUI view in a window. No file picker yet — load from a hardcoded path or CLI arg.

- **1.1** — SPM scaffold, `Package.swift` with `swift-markdown`, `HighlightSwift`, `Yams`, `ViewInspector`. Empty `MdSlidepalApp` that opens a window. Theme JSON symlinked into `Resources/`.
- **1.2** — `Theme` struct + `ThemeLoader` + `ThemeEnvironment`. Unit test: load both `agency-default.json` and `agency-dark.json`, assert every field decodes. Bundle fallback `Theme.agencyDefault` constant.
- **1.3** — `MarkdownParser` wrapper + `FrontMatterExtractor` (skips if no leading `---` at offset 0; parses via Yams otherwise). Tests against fixture 06.
- **1.4** — `SlideSplitter` with AST-based top-level ThematicBreak detection. Tests against fixtures 01, 02, 08 (especially 08 — `---` in code blocks, empty slides, trailing separators). Degenerate cases from contract §2 all tested.
- **1.5** — `SlideView` + `HeadingView` + `ParagraphView` + `ListView` + `TableView` + `CodeBlockView` (HighlightSwift integration). Render fixtures 01, 02, 03, 05 to screen. Overflow policy (`SlideScaler`) implemented but only smoke-tested.
- **1.6** — `SlideMetadataExtractor` + `NotesExtractor`. Unit tests against fixture 07 (notes) and a synthetic fixture for `<!-- slide: -->` blocks.

**Acceptance:** fixtures 01, 02, 03, 05 render in a window (hardcoded path); fixture 08 passes parser-level slide-count assertions; fixtures 06, 07 parse metadata and notes correctly (rendering comes later).

### Phase 2: Window and file-load UI (3 days)

**Goal:** real app — open files via the UI, browse slides, live-reload on change, render all document features.

- **2.1** — `DeckWindowView` with `NavigationSplitView` (sidebar: slide thumbnails; detail: `SlidePreviewPane`). Sidebar uses native list styling; selection drives detail view.
- **2.2** — `FileLoader` + `.fileImporter` for File → Open (⌘O). `NSDocumentController` for File → Open Recent. Drag-and-drop `.md` onto window.
- **2.3** — `FileWatcher` via `DispatchSource.makeFileSystemObjectSource`. Debounced 100ms re-parse on file change. Diagnostics surface in a banner above the preview pane.
- **2.4** — `ImageView` — local (path relative to source file), remote (`AsyncImage`), placeholder on failure with alt text. Path-traversal refusal (contract §11).
- **2.5** — `AppCommands` — menu bar with File/Edit/View/Window/Help. Recent files, Open, Close, Reload (⌘R).

**Acceptance:** open any fixture via ⌘O. Fixture 04 (images) and fixture 06 (front-matter with theme switch to `agency-dark`) fully render. Editing the file in another editor triggers re-render within 500ms.

### Phase 3: Presentation and presenter mode (4 days)

**Goal:** full-screen presentation with multi-display presenter view, all keyboard nav, notes in presenter only.

- **3.1** — `PresentationCoordinator` skeleton: enter/exit present state, current slide index, keyboard routing via `NSEvent.addLocalMonitorForEvents`.
- **3.2** — Single-display full-screen path: `NSWindow.toggleFullScreen(nil)` on audience window, Esc exits. All nav keys working (Right/Space/`n`, Left/`p`, Home, End).
- **3.3** — `b`/`.` black screen toggle, `f` full-screen toggle, `?` help overlay sheet.
- **3.4** — Multi-display: `NSScreen` enumeration, audience window moved to external screen via `setFrame` + `toggleFullScreen`. `PresenterWindowView` opens on main display via `@Environment(\.openWindow)`.
- **3.5** — `PresenterWindowView` content: current slide (scaled), next slide preview, notes pane (rendered markdown via a reused `SlideView`-like renderer for notes), `TimerView` (elapsed since present start).
- **3.6** — `s` key toggles presenter window in single-display mode (overlay).

**Acceptance:** two-display rehearsal passes — audience on external, presenter on laptop, keyboard nav works, Esc cleanly exits both. Fixture 07 speaker notes appear ONLY in presenter view, never in audience view. All 10 keyboard shortcuts from contract §10 work.

### Phase 4: PDF export (2 days)

**Goal:** File → Export → PDF produces one page per slide at 1920×1080 with theme colors.

- **4.1** — `PDFExporter` uses SwiftUI `ImageRenderer` to render each `SlideView` at logical size (1920×1080) to a `CGImage`.
- **4.2** — Assemble pages with PDFKit: `PDFDocument` + `PDFPage(image:)` per slide. Embed metadata (title, author) from front-matter.
- **4.3** — File → Export → PDF menu item with `NSSavePanel`. Progress indicator for decks > 20 slides.
- **4.4** — Handle speaker notes: option "Include speaker notes" writes a second section with notes per slide (Phase 4.1 vs. default audience-only).

**Acceptance:** all 8 fixtures export to PDF. Visual check: theme colors preserved, code blocks highlighted, fonts embedded (or substituted with system). PDF opens in Preview and Quick Look.

### Phase 5: Additional theming + Phase 2 contract parity (3 days)

**Goal:** polish, additional themes, and any Phase 2 contract items that naturally flow from MVP work. Also lands any web-parity catch-up if web is being iterated in parallel.

- **5.1** — Custom theme loading from arbitrary paths (File → Load Theme or front-matter `theme: /path/to/theme.json`).
- **5.2** — `render` command (File → Export → HTML) as a minimal self-contained HTML output, reusing slide markup rendered to strings. Primarily to reach parity with contract §7; not the primary Mac use case.
- **5.3** — Live-reload for theme files (in addition to source `.md`).
- **5.4** — Diagnostics pane (View → Diagnostics) showing warnings accumulated in `DeckDocument.diagnostics`.
- **5.5** — Fixture 08 edge cases should already pass from Phase 1.4; Phase 5 adds regression tests for any discovered issues.
- **5.6** — Pre-release polish: app icon, Info.plist, UTI for `.md`, "Open With" binding, Services menu integration.

**Acceptance:** custom theme file loads and renders; HTML export works for fixtures 01–05; app is ready for TestFlight / notarized distribution (signing is out of scope for MVP plan).

### Sequencing & dependencies

```
P1 (parser + render) ─┬─> P2 (UI) ──> P3 (present) ──> P4 (PDF)
                      └─> (P2 depends only on P1 parser output)
                                      P3 depends on P2 (needs window)
                                      P4 depends on P1 rendering (ImageRenderer over SlideView)
                                      P5 depends on everything
```

Phase 4 can begin in parallel with late Phase 3 (PDF export only needs the renderer, not presenter mode). Phase 5 strictly last.

**Total estimate: ~16 working days.** Add 2 days buffer for QG fix cycles = **~18 working days** to MVP completion.

---

## 4. Open questions for the principal

1. **App bundle location in repo.** Plan puts the Mac app at `apps/mdslidepal-mac/`. Contract does not mandate a location. Is `apps/` the right top-level for platform implementations, or should they live under `claude/workstreams/mdslidepal/mac/`? (The workstream location mingles framework and app code; `apps/` keeps them cleanly separated. Check with licensing model — Reference Source License for apps per repo CLAUDE.md.)

2. **Licensing.** Contract sets `license: MIT` for mdslidepal. Repo CLAUDE.md says "App workstreams (mdpal, mock-and-mark) — Reference Source License." Is mdslidepal framework-tier (MIT) or app-tier (RSL)? This plan assumes MIT per contract; confirm or correct.

3. **Signing and notarization.** Phase 5 stops at "ready for notarization." Does MVP include an actual notarized/signed build, or is local `swift build` + `open .build/release/...` sufficient for Jordan's personal use? Signing credentials and Apple Developer account setup are not planned here.

4. **CLI entry point.** Contract §7 lists `render` / `present` / `export` as commands. Mac surfaces these as menu items, but should there also be a command-line binary (`mdslidepal render input.md --output out.pdf`) built alongside the `.app`? SPM makes both trivial; adding a CLI target is ~0.5 days. Recommend yes for parity with web, but flagging because it's not strictly required by contract §7 (the table shows Mac as "Menu: ...").

5. **Live-reload debounce strategy on rapid saves.** `DispatchSource` fires multiple events for atomic saves (editors that write to temp then rename). 100ms debounce is a reasonable default, but some editors (Zed, BBEdit) produce rename-rename patterns. Should the file watcher re-open the file descriptor on rename, or watch the directory inode? The plan assumes "watch-and-reopen" — confirm if this causes surprises during dogfooding.

6. **`<!-- slide: -->` block HTML parsing in `swift-markdown`.** `swift-markdown` exposes HTML blocks as `HTMLBlock` nodes containing raw text; the plan extracts the body and parses with Yams. However, `swift-markdown` may merge adjacent HTML comments into a single block, and comment boundaries inside the body may confuse the regex. Plan asserts this is tractable but flags as a **risk point** — may need AppKit fallback to manual text scanning if AST-level extraction proves flaky. (Estimate risk: low; mitigation: falls back to pre-parse text regex with a blanket "not inside a fenced code block" guard, which we already compute for the splitter.)

7. **Remote image loading in offline-first mode.** NFR-2 says offline-first. A fixture with an `http://` image URL will try to load. Should the default behavior be:
   - (a) always attempt, placeholder on failure (current plan), or
   - (b) Settings toggle "Allow remote images" defaulting OFF?
   Contract §5 says "Remote URLs are loaded directly" with "No caching mandated" — recommend (a) with a future Settings toggle in Phase 5.

8. **SwiftUI gap concerns beyond anticipated interop.** Known gaps requiring AppKit interop: multi-display full-screen routing, global key capture. Additional potential gaps worth flagging:
   - **Printing / PDF pagination** — `ImageRenderer` path avoids `NSPrintOperation`, so this is fine.
   - **Drag-and-drop of `.md` onto app icon in Dock** — requires `application(_:open:)` AppDelegate method; SwiftUI `.onOpenURL` covers most cases but Dock drops need the classic AppDelegate path on older macOS; macOS 14+ is believed to handle this in pure SwiftUI via `WindowGroup(for: URL.self)`. **Verify in Phase 2** — if it fails, add an `NSApplicationDelegateAdaptor`.
   - **Live text/translation Services** — not planned; macOS provides for free on any `Text` view.

9. **Live-reload + presenter mode interaction.** If Jordan edits the source during presentation, should slides re-render live (disruptive) or freeze until Esc (safe)? Plan default: freeze file watcher while in present mode, replay on Esc. Confirm.

10. **Phase 2 "layout:" field.** Contract §3 defers it. But if we plan the `SlideMetadata` struct to include a `layout: String?` field from MVP (unused), we avoid a schema migration later. Plan assumes yes (forward-compatible schema). Confirm.

---

*Planning deliverable — no code written. Await principal review before Phase 1 kickoff.*
