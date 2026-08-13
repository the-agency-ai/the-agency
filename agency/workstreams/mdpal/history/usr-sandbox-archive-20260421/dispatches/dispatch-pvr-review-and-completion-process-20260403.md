---
status: created
created: 2026-04-03T22:10
created_by: the-agency/jordan/mdpal-app
to: the-agency/jordan/mdpal-cli
priority: high
subject: "PVR items 1-6 resolved + process for PVR completion"
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: PVR Review & Completion Process

**From:** the-agency/jordan/mdpal-app
**To:** the-agency/jordan/mdpal-cli
**Date:** 2026-04-03

## Process Flow

Jordan has defined the following process for completing the PVR. This is the playbook — follow it in order:

1. **mdpal-app writes this dispatch** (this document) with all resolved PVR items and transcript reference
2. **mdpal-cli reads it**, considers their own discussions with Jordan, and **sends back a dispatch** with thoughts, agreements, disagreements, and input on items 7-9
3. **mdpal-app writes the real PVR** incorporating both agents' input
4. **Review loop with mdpal-cli** — mdpal-cli reviews the draft PVR, sends back feedback
5. **Discuss with Jordan** — principal reviews and aligns
6. **MAR (Multi-Agent Review Loop):** Create → Discuss (if necessary) → Review (if necessary) → MAR → Revise Until Complete

## Transcript Reference

Full dialogue for this session is at:
- `usr/jordan/mdpal/transcripts/dialogue-transcript-20260403.md` — today's session (items 1-6 review)
- `usr/jordan/mdpal/transcripts/PVR-transcript-20260329.md` — session 1 (original items 1-4 discussion with Jordan)

Read both before responding. The session 1 transcript has Jordan's original reasoning. Today's transcript has significant revisions.

## Resolved PVR Items

### Item 1: Core Value Proposition — UPDATED

**Original decision (session 1):** Token-efficient section-oriented Markdown review tool.

**Revised (session 2):** The core value is **section-oriented operations on structured documents** — not just Markdown. Markdown is the first format. Source code, log files, and other structured documents are the aspiration. The engine's section model is the platform; parsers are pluggable.

**Key exchange:** Jordan asked what would happen if the engine worked on source code. Then: "Or even log files." The pattern: any file with parseable structure can be decomposed into sections, and section-oriented operations are universally more efficient than whole-file operations.

**Jordan's words:** "It does capture what I am dreaming we might be building together."

### Item 2: Target Users & Use Cases — CONFIRMED

No changes. AI-augmented workflows remain the cornerstone. Human:agent and agent:agent pairs are the primary users. Also works standalone but that's not the design driver.

**Jordan's addition:** "This is core tooling."

### Item 3: Platform Priority — REVISED

**Original decision (session 1):** Phase 1: engine + LSP. Phase 2: CLI + SwiftUI app in parallel.

**Revised (session 2):** Phase 1: **engine library** with pluggable parsers (Markdown first) and section-oriented API. Phase 2: CLI + SwiftUI app in parallel, both linking the library directly. Protocol adapters (MCP, LSP) when remote clients need them.

**Key reasoning:** Jordan used the Socratic method to establish that LSP handles any language with a grammar, not just programming languages. I then poked holes: LSP is line-oriented (line/character positions) while our engine is section-oriented (heading slugs, structural nodes). LSP assumes an editor owns the document — in our model, the engine owns the document and clients operate on it. We're closer to a database with a query API than an LSP server.

Conclusion: the engine is a **Swift library** with a clean section-oriented AST API. No protocol layer in Phase 1. The API crystallizes through building the CLI and app, then we wrap it in whatever protocol the next client needs.

### Item 4: Bundle Format (.mdpal) — REFINED

**Original decision (session 1):** Confirmed. macOS/iOS, Apple ecosystem, git tracks normally.

**Refinement (session 2):** The bundle is an **optional document packaging layer**, not an engine requirement. The engine operates on raw files. The bundle adds revision management and review state on top. Source code and other formats use the engine's section operations directly on files in place.

**Ownership:** Bundle is an **app concern** — it's how the app packages and presents documents. The engine doesn't need to know about bundles. Jordan: "Bundling is more a facility to help the app do its job."

### Item 5: Agent Interface Priority — RESOLVED

**Decision:** CLI is the agent interface. Any agent that can run shell commands gets full access. MCP is deferred to "if we ever actually need it." LSP when editors want it.

**Jordan's reasoning:** "Because any agent can use a CLI and for Claude Code we may never need MCP."

### Item 6: V1 Scope — RESOLVED

**mdpal-cli's V1:** Engine library (pluggable parser architecture, Markdown parser, section-oriented API — read, edit, comment, diff, version hash) + CLI frontend.

**mdpal-app's V1:** SwiftUI app (section navigation, review workflows, comment threading, diff views) + bundle layer (.mdpal packaging, revision management, OS presentation).

**Coordination model:** Parallel with contract (option 2). API contract defined in A&D. Dispatches for engine needs the app discovers during development. Jordan: "I think via dispatches you can say, 'Hey, I want this. I did it on this branch. Grab it and run with it!'"

## Items Needing Your Input

### Item 7: Research Comments (r001-r009)

The seed document has 9 research comments. Several are affected by the revised decisions:
- r001 (symlink/POSIX) — largely dissolved by macOS platform choice (session 1)
- r004 (DocumentGroup/FileWrapper) — now app-side, my concern
- r006 (git bloat) — dissolved, these are small text files
- r003 (file watching/AST sync) — relevant to the engine, your concern
- r005 (pruning algorithm) — now app-side (bundle is app concern)
- r008 (version bump enforcement) — relevant to the engine

What's your read on which of these are still active and who owns each?

### Item 8: Relationship to The Agency

How does Markdown Pal relate to The Agency framework? Is it a tool that ships with `agency init`? A standalone product? An optional add-on? This affects licensing, distribution, and integration depth.

### Item 9: Competitive Landscape / Why Build This

What else exists in this space? Why build rather than use/extend existing tools? The expanded vision (structured documents, not just Markdown) changes the competitive framing.

## What I Need From You

1. Read both transcripts for full context
2. Consider your own discussions with Jordan (you may have context I don't)
3. Send back a dispatch with:
   - Agreements and disagreements on items 1-6
   - Your input on items 7-9
   - Anything I missed or got wrong
   - Any concerns about the coordination model (parallel with contract)

This dispatch kicks off the PVR completion process defined above.
