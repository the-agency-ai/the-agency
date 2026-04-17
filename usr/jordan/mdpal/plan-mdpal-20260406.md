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

### Phase 1 Completion — 2026-04-16

**Status: COMPLETE (engine-only MVP)**

Phase 1 scope diverged from the original plan. The engine core (iterations 1.1–1.4) shipped as a library — CLI commands (original iterations 1.4–1.6) are deferred to Phase 2.

**What shipped:**
| Iteration | Commit | Tests | Content |
|-----------|--------|-------|---------|
| 1.1 | `9cf480b` | 33 | Core types, Markdown parser, section tree |
| 1.2 | `abbc746` | 80 | Document model, comments, flags, YAML metadata |
| 1.3 | `904131e` | 124 | Section operations (read/edit), comment lifecycle, flag lifecycle |
| 1.4 | `1a18718` | 175 | DocumentBundle, revisions, prune, dual-latest mechanism |
| Phase QG | `2a80f21` | 179 | C1 append-only fix + C2 symlink attack fix |

**Phase QG findings — 2 CRITICAL fixed, 7 HIGH deferred:**
- C1 FIXED: prune() violated append-only invariant by re-serializing whole document
- C2 FIXED: symlink-as-revision attack — listRevisions followed symlinks
- H1 DEFERRED: Revision metadata drift — createRevision doesn't update DocumentInfo
- H2 DEFERRED: DocumentInfo.blank() non-POSIX DateFormatter
- H3 DEFERRED: Empty slug for non-ASCII headings
- H4 DEFERRED: Slug suffix scheme drift (-1,-2 vs A&D -2,-3)
- H5 DEFERRED: Diff API missing (blocks Phase 2 CLI)
- H6 DEFERRED: No end-to-end Bundle+Document integration test
- H7 DEFERRED: Byte-equal round-trip not asserted

**QGR receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-phase-complete-20260416-1901-f1656c3.md`

---

## Phase 2: CLI Commands

**Scope:** Build the `mdpal` binary on top of the Phase 1 engine library. Deliver every command in the dispatched JSON spec to mdpal-app
(`usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md`).

**Plan note (2026-04-17):** Iteration 2.1 in the original plan was DocumentBundle/RevisionManager, which already shipped in Phase 1. Phase 2 iterations are renumbered below to reflect the actual CLI work that remains.

### Iteration 2.1: CLI framework + read-side commands ✅ COMPLETE 2026-04-17

**Built:**
- ArgumentParser scaffold (`main.swift`, `Mdpal` root command)
- Wire-format infrastructure: `JSONOutput` (camelCase encoder, ISO8601 dates, sorted keys), `MdpalExitCode` (5 canonical exit codes), `OutputFormat` (json|text)
- `ErrorEnvelope` + `EngineErrorMapper` — every `EngineError` case maps to a camelCase symbol-style discriminator under the `error` field (matches dispatched spec)
- `BundleResolver` — tilde expansion, relative-to-cwd resolution, `..` normalization
- `SectionsCommand` — recursive tree with top-level `count` + `versionId`
- `ReadCommand` — full section payload with `versionHash` + `versionId`
- Tool version exposed via root `--version` flag (frees `version` for `version show/bump` later)

**Tests built:**
- `mdpalCLITests` target added to `Package.swift`
- `CLISupport` infrastructure: binary location, fixture creation with safe cleanup, subprocess invocation, error types with proper diagnostics
- 12 CLI integration tests covering wire-format shape, recursive tree, empty bundle, missing bundle, near-miss suggestions, text format, root help/version

**QG findings:**
- 2 CRITICAL contract drift caught + fixed: snake_case → camelCase wire format, `code` → `error` envelope field. Shipping the original implementation would have broken mdpal-app's RealCLIService integration.
- 1 HIGH structural drift caught + fixed: flat sections list → recursive tree + count + versionId
- Other supporting fixes (BundleResolver path normalization, ErrorEnvelope fallback preserving error+message, test infrastructure improvements)

**Tests:** 192 passing (180 engine + 12 CLI).

**Commits:**
| Commit | Content |
|--------|---------|
| `94d0169` | Phase 2.1 staging — initial implementation (with snake_case drift) |
| `874ae16` | QG fixes — wire-format alignment with dispatched spec |

**QGR receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1312-fb1f7e3.md`

### Iteration 2.2: Section-write commands ✅ COMPLETE 2026-04-17

**Built:**
- `EditCommand` — `mdpal edit <slug> --version <hash> <bundle> [--content <text> | --stdin]`
- Optimistic-concurrency wire shape: success `{slug, versionHash, versionId, bytesWritten}`; conflict exit 2 with `{error: "versionConflict", details: {slug, expectedHash, currentHash, currentContent, versionId}}`
- `GlobalOutputOptions` — `--format` flag via `@OptionGroup` (refactored existing commands)
- Persistence path: editSection → serialize → createRevision (preserves append-only invariant)

**QG hardening:**
- `versionId` enrichment in conflict envelope (engine's EngineError.versionConflict doesn't carry it; CLI adds it at the catch boundary)
- isatty check rejects interactive `--stdin` with `stdinIsTTY` envelope (would hang otherwise)
- `invalidEncoding` envelope for non-UTF-8 stdin (no longer silent empty-content)
- `bytesWritten` reports on-disk size via `attributesOfItem(.size)`, not in-memory `utf8.count`

**Tests:** 204 passing (180 engine + 24 CLI). 12 EditCommand tests covering success/conflict/stdin/heading-rejection/empty-content/empty-stdin/text-format/filesystem-revision-count/versionId-in-envelope.

**Commits:**
| Commit | Content |
|--------|---------|
| `f444ded` | Phase 2.2 staging — EditCommand + GlobalOutputOptions |
| `0b26f86` | QG fixes — versionId + TTY/encoding/bytes hardening |

**QGR receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1325-0374c18.md`

**Deferred (fold into 2.3):** subprocess timeout, slug edge cases (empty slug, leading slash), no-op edit semantics, exact bytesWritten pin, invalidBundlePath in edit, text format ordering.

### Iteration 2.3: Comment + flag commands + Wire/ refactor ✅ COMPLETE 2026-04-17

**Built:**
- 6 commands per dispatched spec: `comment`, `comments`, `resolve`, `flag`, `flags`, `clear-flag`
- Wire/ directory created with `CommentPayload`, `ResolutionPayload`, `FlagPayload`, `FlagListEntryPayload`, `ClearFlagPayload`, `FlagsListPayload`
- Field-name mapping at the wire boundary (engine's `id`→`commentId`, `sectionSlug`→`slug`, `isResolved`→`resolved`, `resolvedBy`→`by`, `resolvedDate`→`timestamp`)
- Custom `encode(to:)` on FlagPayload, FlagListEntryPayload, CommentPayload, ResolvePayload, FiltersEcho — emits nil optionals as explicit JSON `null` (Swift's synthesized Encodable would omit; spec requires explicit null)
- Persistence: each mutating command serializes + createRevision (append-only)

**Wire format (matches dispatched spec):**
- Comment: `{commentId, slug, type, author, text, context, priority, tags, timestamp, resolved, resolution}`
- Resolution: `{response, by, timestamp}`
- Comments list: `{comments, count, filters: {section, type, resolved}}` — all filter fields explicit null when unset
- Flag: `{slug, flagged: true, author, note, timestamp}` — note is explicit null when absent
- Flags list: `{flags: [{slug, author, note, timestamp}], count}` — list entries omit `flagged` (implicit)
- Clear-flag: `{slug, flagged: false}`
- Resolve: `{commentId, resolved: true, resolution: {response, by, timestamp}}`

**QG (self-review against established 2.1/2.2 patterns):**
- 1 CRITICAL caught + fixed inline: nil-optional encoding (custom encode(to:) on 5 types)
- Wire-format renames verified test-by-test (engine field names asserted absent)

**Tests:** 221 passing (180 engine + 41 CLI). 17 new (10 comment lifecycle + 7 flag lifecycle).

**Commit:** `6b312ad`

**QGR receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1334-d57306b.md`

**Deferred (fold into 2.4):** subprocess timeout, slug edge cases, e2e collaboration test, wire-format goldens.

### Iteration 2.4: Bundle + diff + prune + refresh commands

**Build:**
- `CreateCommand` — `mdpal create <name> [--dir]`
- `HistoryCommand` — `mdpal history <bundle>` (revision list)
- `version show/bump` subcommand group (now that the leaf was reserved in Iter 2.1)
- `RevisionCommand` — `mdpal revision create <bundle> [--content | --stdin] [--base-revision]`
- `DiffCommand` — requires building the deferred Diff API in the engine (H5 from Phase 1.5 backlog)
- `PruneCommand` — `mdpal prune <bundle> [--keep <n>]`
- `RefreshCommand` — `mdpal refresh <slug> <bundle>`

**Test:**
- API: create → bundle directory + initial revision + JSON
- API: history → revision list JSON ordered newest-first
- API: version show/bump → correct version IDs
- API: revision create via stdin → new revision JSON
- API: revision create with stale base-revision → exit 4 bundleConflict
- API: diff → changes array
- API: prune → kept + prunedCount + commentsPreserved
- API: refresh → updated hash + commentsUpdated count

### Iteration 2.5: Phase 2 hardening + dispatch to mdpal-app

**Build:**
- E2E test: full create → edit → comment → flag → prune → diff lifecycle through CLI
- Performance: 100-revision bundle benchmarks
- Concurrent CLI invocation test (multi-process)
- Address Phase 1.5 deferred items that still apply: file-size limits, name validation, CSV-style YAML billion-laughs guard
- Dispatch to mdpal-app: "Phase 2 CLI complete — all commands ready"

**Test:**
- Coverage: ≥90% engine, ≥80% CLI
- Performance benchmarks within envelope
- Wire-format goldens — assert byte-equal JSON payloads against fixture for stable mdpal-app integration

**Delivers:** Phase 2 complete. mdpal-app unblocked.

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
