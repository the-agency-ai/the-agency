# Design Transcript — mdpal A&D Kickoff

**Date:** 2026-04-04
**Mode:** design
**Agent:** the-agency/jordan/mdpal-cli
**Principal:** Jordan
**Project:** mdpal

---

## Session Context

Morning session resuming from end-of-day handoff (2026-04-03). PVR signed off by all parties (Jordan approved this morning). mdpal-app responded to A&D kickoff dispatch with five answers on engine consumption. mdpal-cli leading A&D, engine API contract is priority.

---

## Entry 1 — Morning Bootstrap

**mdpal-cli:** Resumed from handoff. Checked state per morning plan:
1. Merged main — picked up ISCP workstream, new hookify rules, captain session work (clean merge).
2. Found mdpal-app's end-of-day handoff (b9ef538) — she had answers to all 5 A&D questions prepared but hadn't sent a dispatch yet.
3. Then found her dispatch: `dispatch-ad-app-response-20260404.md` — sent at 08:30, high priority, responding to A&D kickoff.

**mdpal-cli:** Summarized dispatch contents for Jordan:
- **PVR:** Final. Signed off by mdpal-cli (2026-04-03), mdpal-app (author), Jordan (2026-04-04 morning).
- **mdpal-app's 5 answers:**
  1. Typed Swift structs, `async throws` for I/O, sync for in-memory. No streams for core API.
  2. Explicit save triggers revision (not auto-save). Pruning is user-initiated.
  3. Engine owns YAML round-tripping, app sees clean `Comment`/`Flag` structs — never sees YAML.
  4. Callback/notification model for file-watching. Engine notifies, app decides (may ignore if unsaved changes).
  5. App owns `FileWrapper` (non-negotiable for SwiftUI). Engine is pure transform for app; CLI does own I/O. Two init paths: `Document(contentsOfFile:)` vs `Document(data:)`.
- **Agreements:** Sub-section granularity deferred to CLI convenience, `Document` dual-mode confirmed, YAML handling straightforward.
- **No pushback needed** — all positions compatible with engine design.

**Jordan:** "I think you have a dispatch. Read it?"

**mdpal-cli:** Confirmed already read it — that was the summary above.

**Jordan:** "Nope, that was it."

---

## Entry 2 — A&D Process Decision

**mdpal-cli:** "Ready to start the A&D draft. The engine API contract is the priority since it unblocks mdpal-app. Shall I dive in, or do you want to /discuss any A&D topics first?"

**Jordan:** "Do you want a /discuss to clarify or do you want to draft and then do a 1B1 for input (or even draft, MAR, and then a discuss)?"

**mdpal-cli:** Proposed draft-first approach. Reasoning:
- mdpal-app's answers are clear and compatible — no open conflicts to resolve before drafting
- PVR is solid and final — the "what" is settled
- 6 concrete technical notes from handoff ready to work through
- A draft gives something concrete to react to vs. discussing in the abstract

Proposed flow: (1) draft A&D, engine API contract first, (2) 1B1 with Jordan on draft, (3) dispatch API surface to mdpal-app, (4) MAR after both rounds of feedback.

**Jordan:** "You should be doing a transcript here."

**mdpal-cli:** Started transcript. Asked to also capture the material up to this point.

**Jordan:** "Please add the material up to here to the transcript? And then draft it."

**Decision:** A&D process will be: (1) draft A&D with engine API contract first, (2) 1B1 with Jordan on draft, (3) dispatch API surface to mdpal-app, (4) MAR after both rounds of feedback. Transcript running throughout.

---

## Entry 3 — A&D Draft Complete

**mdpal-cli:** Drafted the full A&D at `usr/jordan/mdpal/ad-mdpal-20260404.md`. 14 sections covering:

1. System Overview — three-component architecture diagram
2. Pluggable Parser Protocol — `DocumentParser` protocol, structural model (`SectionTree`, `SectionNode`), validation sketch (Swift source parser), Markdown parser implementation notes
3. Engine API Contract — `Document` class (central type), dual initialization (file path vs raw data), section CRUD, comment/flag operations, diff, serialization. Full data types: `Section`, `SectionInfo`, `Comment`, `NewComment`, `Flag`, `CommentFilter`, `SectionDiff`. Error model with 8 cases including `versionConflict` and `bundleConflict`.
4. Section Addressing — slug computation, path-style nesting, duplicate disambiguation (`examples`, `examples-2`), sub-section granularity deferred
5. Comment and Flag Data Model — metadata block format (YAML in fenced code block in HTML comments), round-tripping strategy, comment ID generation, staleness detection, context capture, flag storage
6. Bundle Operations — structure, config, version ID format, Bundle API, pruning algorithm (5-step with metadata merge-forward), symlink management, revision triggers (app vs CLI)
7. Concurrent Write Strategy (r002) — threat model, V1 file-level optimistic concurrency, Phase 2 advisory lock file
8. Version Bump Enforcement (r008) — convention not enforcement
9. CLI Command Specification — 15 commands with full signatures
10. Technology Choices — Swift packages, package structure
11. Trade-offs — 4 alternatives considered with rationale
12. Failure Modes — 9 failure scenarios with detection and response
13. Security Considerations — input validation, no network access, bundle integrity
14. Open Questions — 4 non-blocking items for implementation

**Key design decisions in the draft:**
- `Document` as a class (reference type) — app needs mutable in-memory model
- File-watching is app concern, not engine — keeps engine as pure transform layer, avoids Foundation coupling for Linux
- YAML reformats on write (no formatting preservation) — metadata is machine-managed
- Advisory lock file for Phase 2 concurrent access — simple, cross-platform
- Version bump is convention, not enforcement — no caller identity in engine

**Jordan:** "Go for it. And if you want to do an MAR before our /discuss, do so. Might be good seed to things. We will also want to pull captain into the review cycle as well."

**Jordan:** "And mdpal-app"

**Decision:** Run MAR before the `/discuss` with Jordan. Review agents: standard MAR agents + mdpal-app perspective + captain perspective.

---

## Entry 4 — MAR Results

**mdpal-cli:** Ran 6-agent MAR in parallel:
1. Structure review (Opus)
2. Feasibility review (Opus)
3. Consistency review (Opus)
4. Clarity review (Opus)
5. mdpal-app perspective (Opus)
6. Captain perspective (Opus)

### Findings Fixed Directly (22 items)

These were unambiguous fixes — no design decision needed:

1. Added missing `DocumentMetadata` and `DocumentInfo` type definitions (critical gap)
2. Renamed `Bundle` → `DocumentBundle` to avoid shadowing Foundation.Bundle
3. Added `Document.diff(against:)` method for Document-to-Document comparison (mdpal-app need)
4. Added `refreshSection()` method to Document API (backing for CLI `refresh` command)
5. Clarified `editSection` content scope: replaces body only, preserves heading, re-parses children
6. Added `Document.write()` vs `DocumentBundle` coordination note for CLI write flow
7. Fixed malformed metadata contradiction between sections 5.2 and 12 (engine throws, caller decides recovery)
8. Renamed `Comment.date` → `Comment.timestamp` for consistency with Flag.timestamp
9. Added blank line requirement for metadata block (CommonMark spec requirement for HTMLBlock)
10. Added byte-range slicing implementation note for serialization (swift-markdown has no round-trip serializer)
11. Added parser registry mechanism note for `Document(content:fileExtension:)` init
12. Added root node semantics: empty heading, preamble content, headless documents
13. Made all file I/O methods synchronous (local file I/O doesn't benefit from async)
14. Fixed CLI output default: JSON always, `--format text` for human. Dropped `isatty()` auto-detection
15. Noted `SectionNode`/`SectionTree` as engine-internal (not public API)
16. Documented priority default (.normal) and tags default ([])
17. Documented `.note` as the catch-all comment type
18. Added TOCTOU race acknowledgment for V1 concurrent writes
19. Added slug disambiguation stability note (positional, recomputed on parse)
20. Cross-referenced comment ID collision to r002 concurrent write strategy
21. Added `bundleConflict` exit code (4) to CLI spec
22. Renamed YAML `version` field to `version_hash` to avoid confusion with document version
23. Added revision-gating to pruning algorithm (abort if symlink changed during prune)
24. Added nested backtick edge case for metadata block (use longer fences)
25. Changed `SectionNode.range` to `sourceRange: Range<String.Index>` with UTF-8 note

### Findings Needing Discussion (8 items — for /discuss with Jordan)

These require design decisions:

1. **FileWrapper + symlinks incompatibility** (critical) — `FileWrapper` dereferences symlinks. `latest.md` mechanism breaks in the app.
2. **File-watching: engine callbacks vs app-owns-it-all** (major) — mdpal-app asked for engine callbacks; A&D pushes all responsibility to app without acknowledging the override.
3. **Bundle API path-based vs FileWrapper-based** (major) — `DocumentBundle` assumes file paths, but sandboxed SwiftUI apps work with `FileWrapper`.
4. **App package location in repo** (critical for coordination) — where does MarkdownPalApp live? Local path dependency?
5. **API contract change protocol** (major) — how are breaking changes communicated between agents?
6. **Testing strategy** (major) — no discussion of what gets tested, how, or what coverage.
7. **Phase sequencing / dependency graph** (major) — which pieces are built in what order? When do the two agents' work first compile together?
8. **Auto-save vs revision decoupling for ReferenceFileDocument** (minor) — SwiftUI auto-save writes to original location, not a scratch location.

---

## Entry 5 — /discuss Session (8 Items, 6 Resolved)

### Item 1: FileWrapper + symlinks

**Decision:** Dual mechanism — `latest.md` symlink for CLI/agent use (Unix-native), `.mdpal/latest` pointer file for app/FileWrapper use. Engine maintains both atomically. If they diverge, pointer file wins, engine repairs symlink.

**Jordan's principle:** "Remember, our overriding principle that we're building tooling that works equally well for principals, aka humans, and for agents. The bundle thing, that's all about humans. But we shouldn't cripple the agentic experience because we have a great human experience."

### Item 2: File-watching scope

**Decision:** File-watching is the wrong abstraction. The communication layer between agents and the app is **ISCP dispatches**, not filesystem notifications. Jordan described the full workflow: agent dispatches a review request → appears in mdpal app tray → principal reads, comments, flags → feedback flows back as ISCP dispatches → agent picks them up via CLI.

**Jordan:** "What I see is the fact that here's talk about a workflow here. An agent has prepared a PVR, and they want me to review it. Now right now that's a very painful process. So honestly, it doesn't happen. I don't read everything the way it is because it's a pain in the ass to do it in the terminal."

**Action:** Sent dispatch to ISCP agent (`dispatch-iscp-adoption-20260404.md`) expressing intent to build on ISCP dispatch model. Captain CC'd.

### Item 3: Bundle API for app

**Decision:** App never calls `DocumentBundle` directly. Bundle operations (revision creation, pruning, merge-forward) are engine/CLI operations. App reads via `Document(content:parser:)` through `FileWrapper`, communicates with engine via ISCP dispatches. `DocumentBundle` stays path-based — it's a CLI/engine tool, not an app API.

**Jordan:** "You laid claim to pruning and all of this, didn't you? So I think you painted yourself into a corner. That is part of the engine. It's a facility. It's not in the app."

### Item 4: App package location

**Decision:** Same monorepo (the-agency), but engine/CLI and app are **independent packages** that evolve separately. No direct library linking. They interact through ISCP dispatches and exposed commands. Both under `agency/workstreams/mdpal/`.

**Jordan:** "I firmly believe in a monorepo for delivery of a value stream."

**Action:** Research Swift/Xcode best practices for structuring engine, CLI, and app as independent packages in a monorepo.

### Item 5: API contract change protocol

**Decision:** API contract is CLI command interface + ISCP dispatch message format. Changes communicated via dispatches (standard Agency protocol). Clean message-based separation. If performance requires tighter integration later, revisit then. This approach also enables the pluggable parser vision — new formats plug into the engine, app remains format-agnostic.

**Jordan:** "A very pragmatic approach to this implementation. We can tighten it up if we need to for performance, but for right now, I don't see it."

**Jordan:** "Also, this approach makes it easy for us to start plugging in other things into it with respect to support for other structured document types."

### Item 6: Testing strategy

**Decision:** Full testing specification in the A&D covering five layers (unit, integration, API, end-to-end, performance). Coverage targets. QG discipline — bug-exposing tests before fixes, red-green cycle, every iteration and phase. Tests baked into development process, not bolted on.

**Jordan proposed:** A dedicated test agent for the mdpal workstream — reviews code for testability, writes tests, reviews mdpal-cli's tests, owns performance benchmarks. "The builder doesn't grade their own homework."

**Jordan:** "I want tests laid down in each and every iteration and phase."

### Items 7 & 8: Not reached — parked for next session

Phase sequencing and auto-save vs revision decoupling remain open.

---
