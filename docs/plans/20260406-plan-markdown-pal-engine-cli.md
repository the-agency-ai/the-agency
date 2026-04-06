---
title: "Plan: Markdown Pal Engine + CLI"
slug: plan-markdown-pal-engine-cli
path: docs/plans/20260406-plan-markdown-pal-engine-cli.md
date: 2026-04-06
status: draft
branch: mdpal
worktree: mdpal
prototype: mdpal
authors:
  - Test User (principal)
  - Claude Code
session: ac938883-a8cd-4d17-9006-54a052802d66
tags: [Backend, Infra]
---

# Plan: Markdown Pal Engine + CLI

---
title: "Plan: Markdown Pal Engine + CLI"
slug: plan-mdpal-cli
date: 2026-04-06
status: draft
branch: mdpal
principal: jordan
agent: the-agency/jordan/mdpal-cli
pvr: usr/jordan/mdpal/pvr-mdpal-20260403-1447.md
ad: usr/jordan/mdpal/ad-mdpal-20260404.md
---

## Context

Markdown Pal is a section-oriented document engine + CLI for structured operations on Markdown files. The engine provides parser-agnostic section operations (read, edit, comment, flag, diff); the CLI is the public contract consumed by both humans and agents. The macOS app (mdpal-app) is a separate package that communicates via CLI JSON output + ISCP dispatches — no direct library linking.

PVR is final. A&D is revised + MAR'd with all 8 architectural decisions resolved. mdpal-app has already scaffolded (13/13 tests passing) and is idle waiting on the CLI command spec (now dispatched) and this plan.

**Goal:** Build the engine core and CLI through Phase 1 (core operations) → Phase 2 (bundle operations) → Phase 3 (performance + advanced features). Phase 1 is collaborative with mdpal-app.

## Package Location

`apps/mdpal/` — independent Swift package in the monorepo.

```
apps/mdpal/
├── Package.swift
├── Sources/
│   ├── MarkdownPalEngine/
│   │   ├── Core/
│   │   │   ├── Document.swift
│   │   │   ├── SectionTree.swift
│   │   │   ├── SectionNode.swift
│   │   │   ├── Comment.swift
│   │   │   ├── Flag.swift
│   │   │   ├── DocumentMetadata.swift
│   │   │   └── EngineError.swift
│   │   ├── Parser/
│   │   │   ├── DocumentParser.swift       (protocol)
│   │   │   └── MarkdownParser.swift       (V1 impl)
│   │   └── Bundle/
│   │       ├── DocumentBundle.swift
│   │       ├── BundleConfig.swift
│   │       ├── RevisionManager.swift
│   │       └── PruneManager.swift
│   └── mdpal/
│       ├── main.swift
│       └── Commands/
│           ├── CreateCommand.swift
│           ├── SectionsCommand.swift
│           ├── ReadCommand.swift
│           ├── EditCommand.swift
│           ├── CommentCommand.swift
│           ├── FlagCommand.swift
│           ├── DiffCommand.swift
│           ├── HistoryCommand.swift
│           ├── PruneCommand.swift
│           ├── VersionCommand.swift
│           ├── RevisionCommand.swift
│           └── RefreshCommand.swift
└── Tests/
    ├── MarkdownPalEngineTests/
    └── mdpalCLITests/
```

## Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| `apple/swift-markdown` | Markdown parsing + AST | Latest |
| `apple/swift-argument-parser` | CLI argument parsing | Latest |
| `jpsim/Yams` | YAML serialization | Latest |

---

## Phase 1: Engine Core + CLI Basics

**Scope:** Parser, Document, section tree, comments, flags + CLI commands `sections`, `read`, `edit`, `comment`, `comments`, `resolve`, `flag`, `flags`, `clear-flag`. These are mdpal-app's Phase 1 priorities.

### Iteration 1.1: Package Scaffold + Parser Foundation

**Build:**
- `Package.swift` with `MarkdownPalEngine` library + `mdpal` executable targets
- `DocumentParser` protocol (A&D §4):
  ```swift
  protocol DocumentParser {
      func parse(_ content: String) throws -> SectionTree
      func serialize(_ tree: SectionTree, metadata: DocumentMetadata) -> String
  }
  ```
- `MarkdownParser` — V1 implementation using `swift-markdown` AST
- `SectionTree` — the tree structure holding `SectionNode` instances
- `SectionNode` — slug, heading, level, content, versionHash, children
- Slug computation: heading → lowercase → hyphens → path-style nesting
- Version hash: deterministic hash of section content (for optimistic concurrency)

**Test:**
- Unit: parse simple document → correct tree structure
- Unit: parse nested headings → correct parent/child relationships
- Unit: slug computation edge cases (special chars, code in headings, consecutive hyphens)
- Unit: version hash stability (same content → same hash)
- Unit: serialize round-trip (parse → serialize → parse → identical tree)

**Delivers:** Parser that can turn Markdown into a section tree and back.

### Iteration 1.2: Document + Metadata

**Build:**
- `Document` class (reference type per A&D §11.3) — wraps SectionTree + DocumentMetadata
- `DocumentMetadata` — comments, flags, config stored in YAML metadata block at end of document
- `Comment` — id, slug, type, author, text, context, priority, tags, timestamp, resolved, resolution
- `Flag` — slug, author, note, timestamp
- `EngineError` — enumeration: parseError, metadataError, sectionNotFound, versionConflict, bundleConflict
- Metadata serialization/deserialization via Yams
- `Document(contentsOfFile:)` initializer — read file, parse, extract metadata

**Test:**
- Unit: metadata round-trip (serialize → deserialize → identical)
- Unit: comment lifecycle (create → read → resolve)
- Unit: flag lifecycle (create → read → clear)
- Integration: parse document with metadata block → Document with comments + flags
- Integration: Document(contentsOfFile:) on test fixture → correct state

**Delivers:** Full in-memory document model with metadata.

### Iteration 1.3: Section Operations

**Build:**
- `Document.sections()` → section list with slugs, levels, hashes
- `Document.read(slug:)` → section content + hash
- `Document.edit(slug:content:version:)` → edit with optimistic concurrency (version conflict → EngineError.versionConflict with current content)
- `Document.addComment(slug:type:author:text:context:priority:tags:)` → add comment
- `Document.comments(section:type:resolved:)` → filtered comment list
- `Document.resolveComment(id:response:by:)` → resolve comment
- `Document.flag(slug:author:note:)` → flag section
- `Document.flags()` → flagged sections list
- `Document.clearFlag(slug:)` → clear flag
- Path-style slug resolution for nested sections (`authentication/oauth`)
- Section-not-found error with available slugs for suggestion

**Test:**
- Unit: sections() returns correct tree
- Unit: read() returns content + hash
- Unit: edit() with correct version succeeds, returns new hash
- Unit: edit() with stale version → versionConflict with current content
- Unit: nested slug resolution (parent/child)
- Unit: section not found → error with suggestions
- Integration: full workflow — read → edit → verify hash changed → read again

**Delivers:** All section operations the CLI needs.

### Iteration 1.4: CLI Framework + First Commands

**Build:**
- `main.swift` with ArgumentParser root command
- JSON output infrastructure (shared encoder, `--format text` flag)
- Structured error output on stderr
- Exit code mapping (0/1/2/3/4)
- `SectionsCommand` — `mdpal sections <bundle>` → JSON tree
- `ReadCommand` — `mdpal read <slug> <bundle>` → JSON section
- Bundle path resolution (accept `.mdpal` dir or relative path, resolve `latest.md`)

**Test:**
- API: `mdpal sections` on fixture bundle → correct JSON shape
- API: `mdpal read introduction` → correct content + hash
- API: `mdpal read nonexistent` → exit 3, error JSON on stderr
- API: `--format text` outputs human-readable text
- Unit: JSON output matches spec shapes (from dispatch to mdpal-app)

**Delivers:** First working CLI commands. mdpal-app can start integrating.

### Iteration 1.5: Edit + Comment + Flag Commands

**Build:**
- `EditCommand` — `mdpal edit <slug> --version <hash> <bundle> [--content | --stdin]`
- `CommentCommand` — `mdpal comment <slug> <bundle> --type --author --text [--context] [--priority] [--tags]`
- `CommentsCommand` — `mdpal comments <bundle> [--section] [--type] [--unresolved] [--resolved]`
- `ResolveCommand` — `mdpal resolve <comment-id> <bundle> --response --by`
- `FlagCommand` — `mdpal flag <slug> <bundle> --author [--note]`
- `FlagsCommand` — `mdpal flags <bundle>`
- `ClearFlagCommand` — `mdpal clear-flag <slug> <bundle>`

**Test:**
- API: edit with correct version → success JSON, exit 0
- API: edit with stale version → conflict JSON on stderr, exit 2
- API: edit via stdin piping
- API: comment → returns comment JSON with auto-ID
- API: comments with filters
- API: resolve → resolved comment JSON
- API: flag/flags/clear-flag round-trip
- End-to-end: create fixture → sections → read → edit → comment → flag → verify state

**Delivers:** Complete Phase 1 CLI command set. mdpal-app can integrate all commands.

### Iteration 1.6: Phase 1 Hardening

**Build:**
- Fix any issues found during integration testing
- Performance baseline: parse 1MB document, time section operations
- Edge cases: empty documents, single-section documents, deeply nested headings (6 levels)
- Front matter handling: preserve but don't interpret `---` blocks at document start
- Dispatch to mdpal-app: "Phase 1 CLI complete, swap stubs for real Process calls"

**Test:**
- End-to-end: full lifecycle scenario (create → multiple edits → comments → flags → verify integrity)
- Performance: 1MB document parses in <1s, section operations complete in <100ms
- Edge case tests for all identified boundary conditions
- Coverage check: ≥90% engine core, ≥80% CLI commands

**Delivers:** Phase 1 complete. All core section operations working end-to-end.

---

## Phase 2: Bundle Operations + Advanced CLI

**Scope:** DocumentBundle, revisions, pruning, diff, history + CLI commands `create`, `history`, `prune`, `diff`, `version show/bump`, `revision create`, `refresh`.

### Iteration 2.1: DocumentBundle + Revision Management

**Build:**
- `DocumentBundle` — manages `.mdpal` directory (config.yaml, revision files, latest.md symlink, .mdpal/latest pointer file)
- `BundleConfig` — YAML config: keepRevisions, version
- `RevisionManager` — create/list/read revisions, manage symlink + pointer file
- Dual latest mechanism (A&D §6.6): symlink for CLI/agents, `.mdpal/latest` pointer for app/FileWrapper
- Version ID format: `V{NNNN}.{NNNN}.{YYYYMMDDTHHMMSSZ}`

**Test:**
- Unit: bundle creation → correct directory structure
- Unit: revision creation → new file + symlink update + pointer update
- Unit: revision listing → correct order, latest flag
- Integration: create bundle → add revisions → verify symlink chain
- Unit: crash recovery — symlink authoritative over pointer file

### Iteration 2.2: Bundle CLI Commands

**Build:**
- `CreateCommand` — `mdpal create <name> [--dir]`
- `HistoryCommand` — `mdpal history <bundle>`
- `VersionCommand` — `mdpal version show/bump <bundle>`
- `RevisionCommand` — `mdpal revision create <bundle> [--content | --stdin] [--base-revision]`
- Base revision conflict detection (exit 4)

**Test:**
- API: create → bundle directory + initial revision + JSON
- API: history → revision list JSON
- API: version show/bump → correct version IDs
- API: revision create via stdin → new revision JSON
- API: revision create with stale base-revision → exit 4

### Iteration 2.3: Diff + Prune + Refresh

**Build:**
- `DiffCommand` — `mdpal diff <rev1> <rev2> <bundle>` (section-level diff)
- `PruneCommand` — `mdpal prune <bundle> [--keep <n>]` (with comment merge-forward)
- `PruneManager` — handles comment history preservation during pruning
- `RefreshCommand` — `mdpal refresh <slug> <bundle>`

**Test:**
- API: diff between two revisions → changes JSON
- API: prune with keep count → correct files removed, comments preserved
- API: refresh → updated hash, stale comments updated
- Integration: create → multiple revisions → prune → verify comments survived

### Iteration 2.4: Phase 2 Hardening

**Build:**
- Fix integration issues
- 100-revision bundle performance test
- Concurrent CLI invocation test
- Dispatch to mdpal-app: "Phase 2 CLI complete — bundle commands ready"

**Test:**
- End-to-end: full bundle lifecycle
- Performance: 100-revision operations within targets
- Coverage check: ≥90% engine, ≥80% CLI

**Delivers:** Phase 2 complete. All bundle operations working.

---

## Phase 3: Performance + Advanced Features

**Scope:** Performance optimization, advanced parser exploration, MCP/LSP adapter groundwork.

### Iteration 3.1: Performance Optimization

**Build:**
- Profile and optimize hot paths (parsing, serialization, section lookup)
- Lazy section loading for large documents
- Bundle index caching for revision lookups

**Test:**
- Performance regression suite
- 1MB document benchmarks

### Iteration 3.2: Advanced Parsers (Exploration)

**Build:**
- Evaluate parser protocol extensibility with non-Markdown formats
- Prototype a structured data parser (YAML/TOML sections)
- Document findings for future work

**Test:**
- Unit: prototype parser produces valid section tree

### Iteration 3.3: Protocol Adapter Groundwork

**Build:**
- Evaluate MCP/LSP wrapping of CLI commands
- Design adapter interface (if warranted)
- Document decision for A&D update

**Delivers:** Phase 3 complete. V1 shipped.

---

## Coordination with mdpal-app

- **CLI JSON spec dispatched** (dispatch #23, 2026-04-06) — mdpal-app can build model types
- **Phase 1 commands land in iteration order:** 1.4 delivers `sections`/`read`, 1.5 delivers `edit`/`comment`/`flag`
- **Contract changes via dispatch** — any JSON shape changes are communicated before implementation
- **Phase boundary dispatches** — mdpal-cli notifies mdpal-app at each phase completion

## Testing Strategy (A&D §14)

- **Five layers:** Unit, Integration, API (CLI), End-to-end, Performance
- **Coverage targets:** ≥90% engine core, ≥80% CLI
- **QG discipline:** Red-green cycle, tests in every iteration, deep QG at phase boundaries
- **Swift Testing framework** with `@Test` macros
- **Fixture bundles** for deterministic testing
- **No mocks for engine core** — real parser, real file I/O

## Verification

After each iteration:
1. `swift build` — compiles clean
2. `swift test` — all tests pass
3. Manual smoke test of new CLI commands against fixture bundles
4. JSON output validates against dispatched spec shapes

After each phase:
1. Full test suite green
2. Coverage meets targets
3. Performance benchmarks within envelope
4. Dispatch to mdpal-app with completion status
