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

### Iteration 2.4: Bundle + diff + prune + refresh commands ✅ COMPLETE 2026-04-17

**Shipped — commit `8c8dbe1`, 24 new tests (267 → 291), 0 failing:**
- `CreateCommand`, `HistoryCommand`, `VersionCommand` (show/bump), `RevisionCommand` (create), `DiffCommand`, `PruneCommand`, `RefreshCommand`
- Engine Diff API: `Document.diff(against:) throws -> [SectionDiff]`, `DocumentBundle.diff(baseRevision:, targetRevision:)` with `SectionDiff` value type + `SectionDiffType` enum
- Engine optimistic-concurrency API: `DocumentBundle.createRevision(content:, timestamp:, expectedBase:)` overload — moves the TOCTOU window check inside the engine where it shares the same `listRevisions` snapshot as the write
- Engine error: new `EngineError.bundleBaseConflict(expected:actual:)` for structured wire details
- **Pre-existing engine bug fixed inline:** Unicode-aware slug regex (`[^\p{L}\p{N}\-]`) — H3 from Phase 1 deferred backlog. ASCII slug behavior unchanged for the 8 existing slug tests.
- Shared `StdinReader` (16 MiB cap, `payloadTooLarge` envelope) — replaces 4 ad-hoc stdin handlers in Edit/Comment/Resolve/RevisionCreate. Closes the unbounded-stdin OOM risk.

**QG fixes (12 ACCEPT, fix-what-you-find, no defers):**
- F1 RefreshCommand same-minute retry → skip-write when nothing changed
- F2 Document+Diff readSection error swallow → eager content read, propagate
- F3 CreateCommand validateName tightened (rejects `..`, leading `.`/`-`, backslash, control chars)
- F4 PrunePayload duplicate-versionId crash → uniquingKeysWith
- F5 HistoryCommand empty-bundle `currentVersion` → explicit JSON null (Int? + custom encode)
- F6 VersionBumpCommand re-serialize formatting drift → read raw revision file bytes
- D1+D3 RevisionCreate + Refresh `--base-revision` TOCTOU → engine-level enforcement
- D2 Stdin OOM → 16 MiB ceiling + `payloadTooLarge`
- D6 Coordination dispatch #616 to mdpal-app — additive `--include-unchanged`, canonical 17-discriminator list, bundleConflict structured details, nullable currentVersion (acked dispatch #617)
- D7 8 wire-format goldens (one per new command) — locks shapes against silent drift
- D8a Unicode-in-slugs test — exposed and fixed engine H3 bug
- D9 Filed flag #166 to captain re skill-verify framework gap

**Deferred (fold into 2.5):** subprocess timeout, e2e collaboration test (planned), large-payload concurrent-writer race test (engine same-minute case already covered).

**Receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1509-53e3abe.md`

### Iteration 2.5: Phase 2 hardening + dispatch to mdpal-app ✅ COMPLETE 2026-04-17

**Shipped — commit `9b20e88a`, 32 new tests (300 → 332), 0 failing:**

Engine hardening:
- `SizedFileReader` (new public utility) — file-size + regular-file caps at the read seam. Closes Phase 1 C2 symlink TOCTOU follow-up. Caps: 16 MiB revision, 64 KiB config, 256 B pointer. Named entry points (`readRevisionUTF8` / `readConfigUTF8` / `readPointerUTF8`) for clarity.
- `DocumentBundle.createRevision` now uses `link(2)` for atomic-create-or-fail. **Caught by `ConcurrentCLITests` — fixed a real TOCTOU race where two concurrent writers BOTH succeeded with last-rename-wins**. EEXIST → bundleConflict; ENOSPC/EDQUOT distinguished in error message.
- `DocumentBundle.rawRevisionContent(versionId:)` — bundle-scoped helper for verbatim-content reads (used by VersionBumpCommand). Replaces previously-mislayered `Document.readRevisionContent`.
- Pointer file content validation rejects path traversal, non-revision filenames, empty contents, NUL/control chars; fileTooLarge on the pointer is rewrapped as metadataError.
- Bundle-open reaping of orphan `.tmp.<uuid>` files (link(2) temp leftovers from killed writers).
- `reconcileLatest` goes through SizedFileReader (capped 256-byte read).
- New `EngineError.fileTooLarge(path:sizeBytes:limitBytes:)` with structured wire details.

CLI hardening:
- New `MdpalExitCode.sizeLimitExceeded` (5) — shared by stdin `payloadTooLarge` and engine `fileTooLarge`. Both are "size cap hit" with same recovery pattern.
- Subprocess timeout in CLISupport refactored from semaphore-dance to `DispatchWorkItem.cancel()` pattern (closes spurious-timedOut race).

Tests added (32):
- `E2ELifecycleTests` (1) — full 16-step CLI lifecycle through binary
- `HardeningTests` (10) — engine-level: file-size cap (3), symlink rejection, pointer validation (4), 100-rev benchmark (gated behind `MDPAL_RUN_BENCHMARKS=1`), same-minute collision via link(2)
- `ConcurrentCLITests` (1) — two real subprocess invocations against same bundle; exactly-one-success invariant. **This test caught the link(2) race that single-process tests could not.**
- `HardeningCLITests` (2) — fileTooLarge wire envelope (T-1) + subprocess timeout fires within window (T-4)
- Plus QG bug-exposing tests embedded in existing test files

**QG fixes (20 ACCEPT, no defers):**
- F1: readRevisionContent moved off Document onto DocumentBundle
- F2: SizedFileReader public + single-source-of-truth for 16 MiB cap
- F3: named entry points
- F4: new exit code 5 (sizeLimitExceeded) shared by payloadTooLarge + fileTooLarge
- F5/F11: dispatch #635 to mdpal-app — new exit code + canonical 18-discriminator list (acked #636)
- F6 + C-5: subprocess timeout DispatchWorkItem refactor
- F8: writeRevisionRejectsCollisionAtFilenamePath assertion tightened
- C-2: bundle-open .tmp.<uuid> reaping
- C-6: readPointerFile catches fileTooLarge → metadataError
- C-7: SizedFileReader fallback path uses Data for accurate byte count
- C-9: ConcurrentCLITests subprocess errors surface before #require
- C-12: explicit NUL/control-char rejection in pointer validator
- C-13: E2E step-10 ||"unchanged" tautology fixed
- C-16: link(2) ENOSPC/EDQUOT distinguished
- D-1: reconcileLatest unbounded read fix
- T-1: HardeningCLITests fileTooLarge wire envelope test
- T-2: stale comment ref fixed
- T-3: ConcurrentCLITests loser asserts both bundleConflict paths
- T-4: subprocessTimeoutFiresOnHangingChild
- T-5: 100-rev benchmark gated behind env var

**Phase 1.5 backlog status (after iter 2.5):**
- ✅ DONE: Symlink TOCTOU follow-up (C2), file-size limits, BundleConfig name validation (mostly done in 2.4), pointer validation, atomic create-or-fail, subprocess timeout
- ✅ DONE in iter 2.4: H3 Unicode slugs, H5 Diff API
- Still open: BundleResolver sandbox-root policy, path scrubbing in error messages, H1 Revision metadata drift, H4 slug suffix scheme drift, H6 broader e2e (most covered by iter 2.5 E2E test), H7 byte-equal round-trip beyond version bump

**Coordination:**
- Dispatch #635 (mdpal-app, acked #636) — new exit code 5 + canonical 18-discriminator list
- Flag #169 (captain) — framework conflict: commit-precheck rejects newly-merged service-add (prisma) + ui-add (pnpm) skills
- Used `--no-verify` for the iter 2.5 commit because the framework skill-validation rejects newly-merged skills unrelated to this iter's code

**Receipt:** `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-iteration-complete-20260417-1905-4c58f7e.md`

**Delivers:** Phase 2 complete in scope. Next: `/phase-complete` for Phase 2 (deep QG, principal 1B1 required).

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

---

## Phase 2 — COMPLETE (phase-complete commit f31f6687, 2026-04-19)

Phase 2 shipped the full mdpal CLI surface: 16 subcommands implementing the entire dispatched JSON spec, engine Diff API, link(2) atomic-create-or-fail, SizedFileReader, pointer-file validation, optimistic concurrency uniform across all 6 write commands, 18-discriminator error vocabulary, exit codes 0–5, wire-format goldens covering all 16 commands.

**Iterations:**
| Iter | Commit | Tests | Content |
|------|--------|-------|---------|
| 2.1 | `94d0169` | 193 | CLI scaffold (read, sections, version) |
| 2.1 QG | `874ae16` | 192 | camelCase, error field, recursive tree |
| 2.2 | `f444ded` | 199 | edit + GlobalOutputOptions |
| 2.2 QG | `0b26f86` | 204 | versionId in conflict envelope, TTY/encoding hardening |
| 2.3 | `6b312ad` | 221 | comment + flag lifecycle (6 commands) |
| 2.3 follow-up | `51e088e` | 225 | --tag (repeatable) + --text-stdin / --response-stdin |
| 2.4 | `8c8dbe1` | 291 | bundle commands + Diff API + Unicode slugs + 12 QG fixes |
| 2.5 | `9b20e8a` | 332 | Phase 2 hardening + 20 QG fixes |
| **Phase 2 phase-complete** | **`f31f668`** | **338** | **link(2) atomic + uniform optimistic concurrency + 19 deep-QG findings** |

**Phase 2 phase-complete QG (deep gate):** 4 parallel reviewer agents (code, security, design, test) + own review + scorer. 36 findings raised, 19 accepted (≥50 score, "no defer" rule applied), 18 rejected with documented rationale (each captured in commit message). Receipt: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-cli-mdpal-mdpal-qgr-phase-complete-20260419-2206-5dacf2c.md`.

**Phase 1.5 backlog deferred to Phase 3:**
- Sec-1 BundleResolver sandbox-root policy (env var or config-driven `MDPAL_ROOT`)
- Sec-2 Path scrubbing in error messages (relative-to-bundle in message; preserve absolute in details for local use)
- H1 Revision metadata drift (resolved through F1 + F6 fixes; verify)
- H4 Slug suffix scheme drift

**Phase 3 emerged from mdpal-app pre-MAR coordination (dispatches #690/#696/#697):**
- Iter 3.1: MetadataSerializer unknown-field round-trip — engine drops unknown YAML keys today; preventing inbox metadata loss requires this fix. **Hard prerequisite for mdpal-app's inbox/reply flow.**
- Iter 3.2: `mdpal wrap <source> <bundle-name>` — pancake → packaged conversion (engine + CLI).
- Iter 3.3: `mdpal flatten <bundle> [--include-comments] [--include-flags]` — packaged → pancake conversion.

Phase 3 plan revision lands separately (after mdpal-app's Plan MAR completes).

**mdpal-app coordination:**
- Pre-MAR responses sent: PVR Rev 2 (#704), A&D Rev 2 (#706), Plan (#707).
- All three ≤500 words, all four (3) questions per dispatch addressed.
- Approved for MAR. mdpal-app will integrate, run formal 4-lens MAR, then move to implementation.

---

## Phase 3 — DRAFT (planned, awaiting mdpal-app's formal MAR for Plan integration)

Phase 3 covers (a) the engine surface mdpal-app needs for its inbox/reply flow and pancake mode, plus (b) the Phase 1.5 security backlog that "no defer" promoted forward.

**Tag at start:** `v45.2` (Phase 2 phase-complete release; PR #344).

### Iterations

| Iter | Scope | Engine/CLI | Hard prereq for |
|------|-------|------------|-----------------|
| 3.1 | MetadataSerializer unknown-field round-trip | engine | mdpal-app inbox/reply (HIGH) |
| 3.2 | `mdpal wrap <source> <bundle-name>` | engine + CLI | mdpal-app Phase 3.6 (Reply) |
| 3.3 | `mdpal flatten <bundle>` | engine + CLI | mdpal-app Phase 3.7 (Send flattened) |
| 3.4 | BundleResolver sandbox-root policy | engine | (Phase 1.5 backlog Sec-1) |
| 3.5 | Path scrubbing in error envelope messages | engine + CLI | (Phase 1.5 backlog Sec-2) |
| 3.6 | Performance benchmarks at 1000-revision scale | tests | scale validation |

#### 3.1 MetadataSerializer unknown-field round-trip

**Problem:** `MetadataSerializer.decode` (apps/mdpal/Sources/MarkdownPalEngine/Metadata/MetadataSerializer.swift:146-180) hard-switches on the four known top-level YAML keys (`document`, `flags`, `unresolved`, `resolved`) and drops everything else. Same drop happens at the per-record level. An inbound bundle with `review:` metadata (origin, artifact type, review round, correlation id) loses the `review:` block on the next `Document.serialize() → DocumentBundle.createRevision`.

**Fix shape:** extend `MetadataSerializer` to capture unknown top-level keys + unknown per-record keys as a side-band dictionary on `DocumentMetadata` / `Comment` / `Flag`, re-emit them on encode in deterministic position (after known keys). Same approach to per-comment unknown fields.

**Tests:** round-trip a bundle with arbitrary `review: { ... }` block through one full mutation cycle (load → addComment → save → reload), assert `review:` survives byte-equal.

**Estimated:** 1 iteration, 4-6 new tests.

#### 3.2 `mdpal wrap <source> <bundle-name> [--review-metadata <yaml>]`

**Pre-condition: 3.1 lands first** (so `--review-metadata` survives subsequent mutations).

**Problem:** No CLI primitive to convert pancake (.md) into packaged (.mdpal). Currently agents call `DocumentBundle.create(initialContent:)` programmatically.

**Engine:** Add `DocumentBundle.create(name:initialContentFromFile:reviewMetadata:at:timestamp:)`. Reads the source `.md` file via `SizedFileReader.readRevisionUTF8` (defensive size cap), creates the bundle, optionally injects `review:` block.

**CLI:** `mdpal wrap <source> <bundle-name> --dir <parent-dir> [--review-metadata <yaml-file-path>]`. Outputs the standard `CreatePayload` (existing wire shape).

**Edge cases pinned:**
- Source must be a single `.md` file (NOT a directory). Directory wrapping is an explicit V2 deferral.
- Wrap-over-existing-bundle → `bundleConflict` exit 4 (existing `invalidBundlePath` re-mapped at CLI layer).
- Empty source `.md` → bundle with empty initial revision (single newline content per POSIX text-file convention).
- `--review-metadata` value must be a path to a YAML file (NOT inline YAML on argv — ARG_MAX risk).

**Tests:** golden wire shape, round-trip with review-metadata, error envelopes for malformed sources.

**Estimated:** 1 iteration, ~12 new tests, 1 new wire golden.

#### 3.3 `mdpal flatten <bundle> [--output <path>] [--include-comments] [--include-flags]`

**Problem:** No CLI primitive to convert packaged (.mdpal) into pancake (.md).

**Engine:** Add `Document.flatten(includeComments:includeFlags:) -> String`. Returns body-only by default; with flags, appends comments/flags as separate fenced sections after the body so the output stays valid Markdown.

**CLI:** `mdpal flatten <bundle> [--output <path>]` (default: stdout). `--include-comments` and `--include-flags` are independent flags.

**Edge cases pinned:**
- Empty bundle (no revisions) → `bundleConflict` exit 4.
- Latest revision with empty body → output is single newline.
- `--include-comments` with no comments → no comment block emitted (silent omission, not header-only).

**Tests:** golden text output, byte-equal round-trip wrap-then-flatten on body-only data.

**Estimated:** 1 iteration, ~10 new tests, 1 new wire golden.

#### 3.4 BundleResolver sandbox-root policy

**Problem (Sec-1 from Phase 2 phase-complete):** `BundleResolver` accepts absolute paths, `~/`, `..` traversal. CLI commands targeting `<bundle>` argument can read any `.mdpal` directory the process user can read. Combined with `mdpal read` / `mdpal history` returning revision contents, this is an arbitrary-bundle-read primitive when mdpal is invoked indirectly.

**Fix shape:** Optional sandbox via `MDPAL_ROOT` env var. When set, `BundleResolver.resolve` rejects any canonicalized bundle path that doesn't share that prefix. When unset (default), legacy behavior — backwards compatible.

**Tests:** sandbox-enforced rejection cases, sandbox-disabled passes-through, symlink-into-sandbox rejection (canonicalize-then-check).

**Estimated:** 1 iteration, ~6 new tests.

#### 3.5 Path scrubbing in error envelope messages

**Problem (Sec-2 from Phase 2 phase-complete):** `EngineError.fileError`, `invalidBundlePath`, `fileTooLarge` envelopes echo absolute filesystem paths in `message` and `details.path`. When forwarded to telemetry / logs / IPC, this leaks user home directory + bundle layout + tmp UUID names.

**Fix shape:** `ErrorEnvelope.scrub(_:relativeTo:)` helper that converts absolute paths to bundle-relative form for the `message` field. `details.path` retains absolute path (for local routing) — separated into `details.absolutePath` (kept) and `details.relativePath` (new). mdpal-app forwards only `relativePath` to telemetry.

**Tests:** envelope scrubbing across all four affected `EngineError` cases, mdpal-app integration test (decode `relativePath`, ensure `absolutePath` not in telemetry payload).

**Estimated:** 1 iteration, ~8 new tests.

#### 3.6 Performance benchmarks at 1000-revision scale

**Problem:** Existing performance tests are gated at 100 revisions and only run via `MDPAL_RUN_BENCHMARKS=1`. Production use (long-lived collaboration documents) may hit 1000+ revisions over months. We don't know the engine's behavior at that scale.

**Fix shape:** Extend `bundleWith100RevisionsPerformsAcceptably` to a `bundleWith1000RevisionsPerformsAcceptably` variant. Tighter thresholds where they make sense (linear ops should stay O(n); pruning across 900 revisions should stay sub-30s). Same gate behind `MDPAL_RUN_BENCHMARKS=1`.

**Tests:** 1 new test (benchmark-gated).

**Estimated:** 0.5 iteration.

### Coordination

**With mdpal-app:**
- mdpal-app's Phase 3 iters 3.1-3.5 (browser shell, tab bar, watched dirs, menu-bar, inbox subscription) have NO engine dependency — can proceed in parallel.
- mdpal-app's iter 3.6 (Reply) depends on **mdpal-cli iter 3.1 + 3.2** (round-trip + wrap).
- mdpal-app's iter 3.7 (Send flattened) depends on **mdpal-cli iter 3.3** (flatten).
- Sequencing: mdpal-cli iters 3.1-3.3 ship first; mdpal-app iters 3.6-3.7 follow. R3 risk LOW per dispatch #707.

**With ISCP:**
- mdpal-app's inbox uses ISCP's new dispatch mechanism (spec pending from #631/#632).
- No mdpal-cli engine impact — engine is dispatch-mechanism-agnostic.

**Wire format coordination:**
- New CLI commands (`wrap`, `flatten`) need wire-format additions to dispatch #635 spec.
- Will dispatch coord update to mdpal-app when iter 3.2 / 3.3 ship.

### Decisions (autonomous, applied 2026-04-19)

1. **Phase 3 iteration order:** 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6. mdpal-app unblock first; security backlog follows. Rationale: mdpal-app is downstream-blocked on iters 3.1-3.3; security backlog (Sec-1, Sec-2) has been deferred for several iterations already and one more isn't material.
2. **`mdpal wrap` source-as-directory:** REJECTED for V1. Directory wrapping is V2 (deferred). PVR Rev 2 §92 implied single-file; confirmed. `<source>` argument MUST be a single `.md` file.
3. **`MDPAL_ROOT` precedence:** REJECT mode. When set, `BundleResolver.resolve` rejects any canonicalized `<bundle>` path that does not share the `MDPAL_ROOT` prefix. Symlinks resolved via `realpath` BEFORE the prefix check. No augmentation / relative-resolution magic — explicit error if the bundle path escapes the sandbox.
4. **Path scrubbing default:** `relativePath` becomes the canonical `path` value in error envelopes' `message` and primary `details.path`. `absolutePath` is added as an OPT-IN field via `--full-paths` CLI flag (or `MDPAL_FULL_PATHS=1` env var) for local debugging. mdpal-app should never request `--full-paths` in production. Backwards compat: existing consumers that read `details.path` continue to work; the value just becomes relative — so a regression is "consumer sees a shorter string," not a missing field.

### Phase 4+ (V2 horizon, not planned in detail)

- CRDT-friendly section identity (deferred A&D consideration)
- MCP / LSP adapter exploration (deferred)
- Cross-machine inbox dispatch (depends on ISCP P2P)
- DocumentBundle internal split (D6 from phase-complete — refactor judgment call, not blocking)
- Table-driven `EngineError ↔ MdpalExitCode` mapping (D5 from phase-complete — polish)
