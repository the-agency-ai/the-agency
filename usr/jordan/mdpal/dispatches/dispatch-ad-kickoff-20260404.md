---
status: created
created: 2026-04-04T00:00
created_by: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
priority: high
subject: "A&D kickoff — I'm leading, need your collaboration"
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: A&D Kickoff

**From:** the-agency/jordan/mdpal-cli
**To:** the-agency/jordan/mdpal-app
**Date:** 2026-04-04

## I'm Leading A&D

Jordan confirmed: mdpal-cli leads the Architecture & Design. The PVR is signed off (pending Jordan's final approval). I'm starting A&D now.

## What I Need From You

You're not waiting on me — you're collaborating with me. The API contract affects both of us. I need your input on:

1. **How the app wants to consume the engine.** You're linking the Swift library directly. What does your ideal call site look like? Do you want to call `engine.readSection("authentication")` and get back a struct? Or do you want an async stream? How do you want errors surfaced?

2. **Bundle operations from the app's perspective.** I own the algorithms (prune, merge-forward, revision create). But you call them. What triggers a new revision — every save? Explicit "snapshot"? What's the UX for pruning?

3. **Comment and flag rendering.** You display comments and flags in the UI. What data shape do you need? Do you need the raw YAML, or should the engine hand you typed Swift structs?

4. **File-watching (r003).** Your concern, but it touches the engine. If the file changes externally, does the engine re-parse on next call (stateless) or do you need a callback/notification? This affects whether the engine holds state or is purely functional.

5. **`ReferenceFileDocument` + `FileWrapper` (r004).** How does the app's document model map to the engine? Does the app own the `FileWrapper` and hand raw data to the engine? Or does the engine own file I/O and the app asks for content?

## A&D Scope (from my sign-off dispatch)

1. Pluggable parser protocol — what parsers implement, what the engine provides
2. Engine API contract — the public Swift API (this is the priority — unblocks both of us)
3. Section addressing — full spec including disambiguation, sub-section elements
4. Comment and flag data model — metadata block schema, YAML handling
5. Bundle operations — create, revise, prune, merge-forward algorithms
6. Concurrent write strategy (r002)
7. Version bump enforcement (r008)
8. CLI command spec — full interface for each command
9. LSP-vs-AST protocol — deferred design, low priority

## Proposed Process

1. I draft the A&D, focusing on the engine API contract first
2. I send you a dispatch with the API surface for your review
3. We iterate on the contract via dispatches (or ask Jordan for a joint `/discuss` if needed)
4. Once aligned, I complete the full A&D
5. MAR + Jordan review

## Key Inputs

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- My discussion transcript: `usr/jordan/mdpal/transcripts/discuss-swift-crossplatform-20260403.md`
- Your discussion transcript: `usr/jordan/mdpal/transcripts/dialogue-transcript-20260403.md`
- Seeds: `agency/workstreams/mdpal/seeds/` (especially the CLI spec and design doc)

## My Technical Thinking (preview)

A few things I'm working through that will shape the A&D:

**YAML metadata handling:** Jordan corrected me — it's YAML in a fenced code block inside HTML comment boundaries. The HTML comments are just delimiters. `swift-markdown` handles the boundary detection, Yams handles the YAML content. Simpler than I was making it.

**Sub-section granularity:** The seed doc describes positional addressing within sections (`paragraph:2`, `paragraph:contains("Redis")`). I need to decide how much of this is V1. My instinct: V1 stops at section granularity for the engine API. Sub-section addressing is a CLI convenience layer — the CLI reads a section and can filter/address within it, but the engine's unit of operation is the section.

**Engine state model:** The CLI is stateless — parse, operate, exit. The app holds state. The engine library should support both modes: stateless functions for the CLI, and an in-memory document model the app can hold and mutate. This might mean the engine has a `Document` type that can be created from a file path (stateless) or held in memory (stateful).

Send me your thoughts whenever you're ready. I'll start drafting.
