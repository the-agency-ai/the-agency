# Handoff: mdpal-app

---
type: pre-compact
date: 2026-04-05 11:30
principal: jordan
agent: the-agency/jordan/mdpal-app
workstream: mdpal
trigger: pre-compact
previous: mdpal-app-handoff (session-end, 2026-04-05 10:00)
---

## Who You Are

You are **mdpal-app**, a tech-lead agent owning the **macOS native SwiftUI app** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-cli** owns the core engine, LSP server, and CLI — the foundation your app talks to. You share the `mdpal` worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md` on session start for shared context.

## What Is Markdown Pal

A **section-oriented tool for structured documents** — enabling both humans and agents to read, edit, comment, flag, and diff documents at the section level rather than the line/file level. Markdown is the first format; the engine is designed for pluggable parsers.

## Current State — Phase 1 Scaffold BUILT

### PVR: APPROVED ✓
### A&D: 8/8 ITEMS RESOLVED — mdpal-cli finalizing

### Phase 1 App Scaffold: BUILT AND TESTED ✓

**Location:** `apps/mdpal-app/`

**What exists:**
- Swift Package (`Package.swift`) with macOS 14+ target
- **Models:** `Section`, `SectionInfo`, `Comment`, `CommentType`, `Priority`, `Resolution`, `Flag` — all Codable with snake_case JSON mapping matching expected CLI output
- **DocumentModel:** `@Observable` class holding sections, comments, flags, raw content. Methods map to CLI commands via `CLIServiceProtocol`
- **CLIServiceProtocol:** Async protocol — `listSections`, `readSection`, `editSection`, `listComments`, `listFlags`. Plus `CLIServiceError` enum
- **MockCLIService:** Realistic mock data — 8 sections (nested), 4 comments (mixed types/states), 2 flags. Simulates latency. Enforces version hash on edit
- **Views:** `ContentView` (NavigationSplitView), `SectionListView` (sidebar with level-based indentation, flag icons, comment badges), `SectionReaderView` (heading, metadata, flag banner, comment thread with staleness indicators), `CommentView` (type icons, priority, resolution display)
- **MarkdownDocument:** `ReferenceFileDocument` for SwiftUI DocumentGroup lifecycle
- **App.swift:** `@main` entry point with DocumentGroup
- **Tests:** 13 tests, all passing — JSON decoding, staleness detection, mock service behavior

**Build:** `swift build` succeeds with Command Line Tools Swift 6.2
**Tests:** `swift run MarkdownPalAppTests` — 13/13 passing
**Note:** `swift test` (XCTest) requires full Xcode license acceptance. Tests run as executable runner instead.

### Architecture Decisions (from A&D /discuss)

| # | Decision | Impact on App |
|---|----------|---------------|
| 1 | Dual latest mechanism (symlink + pointer file) | App reads pointer file via FileWrapper |
| 2 | ISCP dispatches as communication layer | No engine callbacks. ISCP for inter-component comms |
| 3 | App never calls DocumentBundle | Only `Document(content:parser:)` |
| 4 | Independent packages in monorepo | Contract is CLI JSON + ISCP, not Swift types |
| 5 | CLI commands + ISCP = public contract | App parses JSON into its own types |
| 6 | Full testing specification | Tests in every iteration |
| 8 | Option A for revisions | App shells out to `mdpal revision create --stdin` on ⌘S |

## Next Action

### Immediate:
1. **Re-establish dispatch loop** — `*/5 * * * *` for `/dispatch-read` (session-only, needs re-creation each session)

### Waiting on mdpal-cli:
1. **Revised A&D** with all 8 decisions incorporated
2. **Revised CLI command spec (§9)** with JSON output shapes
3. When those arrive: review from app perspective, confirm JSON shapes match my model types

### Next build steps (after CLI spec review):
1. Markdown rendering in SectionReaderView (currently plain text)
2. Section editing UI with optimistic concurrency
3. Real CLI integration layer (`Process` wrapper) — needs finalized CLI spec
4. Bundle support (Phase 2)

## Key Files

| File | Location | What |
|------|----------|------|
| **App scaffold** | `apps/mdpal-app/` | The app package — all source, tests, Package.swift |
| `pvr-mdpal-20260403-1447.md` | `usr/jordan/mdpal/` | PVR (FINAL) |
| `ad-mdpal-20260404.md` | `usr/jordan/mdpal/` | A&D (being revised by mdpal-cli) |

## Environment Notes

- Swift 6.2.3 (Command Line Tools only, no full Xcode SDK for XCTest)
- Tests use executable runner pattern, not XCTest
- Xcode.app is installed but license not accepted (needs sudo)

## Licensing

Reference Source License. See `claude/workstreams/mdpal/LICENSE`.
