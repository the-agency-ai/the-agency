# Handoff: mdpal-cli

---
type: session-handoff
date: 2026-04-04
principal: jordan
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
trigger: mid-session-compact
previous: mdpal-cli-handoff (end-of-day, 2026-04-03)
---

## Who You Are

You are **mdpal-cli**, a tech-lead agent owning the **core engine, CLI, and bundle management operations** for Markdown Pal — a section-oriented tool for structured document operations. You are building the brain; mdpal-app is building the face.

Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-app** owns the macOS native SwiftUI app — the human interface. You share the `mdpal` worktree and branch. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read her handoff at `usr/jordan/mdpal/mdpal-app-handoff.md` on startup for shared context.

## Current State

### PVR: FINAL — signed off by all parties (2026-04-04)

All sign-offs in: mdpal-cli (2026-04-03), mdpal-app (author), Jordan (2026-04-04 morning).
**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`

### A&D: DRAFT — 6 of 8 discussion items resolved, MAR complete

The A&D is drafted and has been through a full 6-agent MAR (structure, feasibility, consistency, clarity, mdpal-app perspective, captain perspective). 25 findings were fixed directly. 8 items went to `/discuss` with Jordan — 6 resolved, 2 parked.

**A&D file:** `usr/jordan/mdpal/ad-mdpal-20260404.md`

### Key Architectural Decisions from Today's /discuss

These decisions **fundamentally reshape the architecture** from the original draft. The A&D needs to be updated to reflect them:

| # | Decision | Impact |
|---|----------|--------|
| 1 | **Dual latest mechanism** — symlink (`latest.md`) for CLI/agents + pointer file (`.mdpal/latest`) for app/FileWrapper | Bundle format change. Engine maintains both atomically. |
| 2 | **ISCP dispatches are the communication layer** — not filesystem notifications, not engine callbacks | File-watching section (3.5) needs complete rewrite. App-engine communication model changes fundamentally. |
| 3 | **App never calls DocumentBundle** — reads via `Document(content:parser:)` through FileWrapper, communicates via ISCP | Bundle API (section 6) becomes CLI/engine-only. App's engine dependency is read-only. |
| 4 | **Independent packages in monorepo** — engine/CLI and app are separate packages, no direct library linking | Package structure (section 10.2) needs restructuring. Research Swift/Xcode monorepo best practices. |
| 5 | **CLI commands + ISCP dispatch format = the contract** — message-based separation, tighten for performance only if needed | Section 3 (Engine API Contract) scope changes — the public contract is CLI + ISCP, not Swift types. Swift types are internal engine API. |
| 6 | **Full testing specification** — five layers (unit, integration, API, end-to-end, performance), QG discipline, tests in every iteration | New section needed in A&D. Jordan proposed a dedicated test agent. |

### Discussion Items Still Open (2 remaining)

| # | Item | Status |
|---|------|--------|
| 7 | Phase sequencing / dependency graph | Parked — next session |
| 8 | Auto-save vs revision decoupling for ReferenceFileDocument | Parked — next session |

### Dispatches

| Dispatch | Status | Notes |
|----------|--------|-------|
| `dispatch-ad-app-response-20260404.md` | Read | mdpal-app's 5 answers to A&D kickoff. Many positions now superseded by today's architectural decisions. |
| `dispatch-iscp-adoption-20260404.md` | Sent (new) | To ISCP agent, CC captain. Expressing intent to build on ISCP dispatch model for agent-principal review workflows. |

## What Was Done This Session (2026-04-04)

1. **Morning bootstrap:** Merged main (clean), read mdpal-app's dispatch, confirmed PVR signed off by Jordan.
2. **A&D draft:** Wrote full 14-section A&D covering: system overview, parser protocol, engine API contract, section addressing, comment/flag data model, bundle operations, concurrent write strategy, version bump enforcement, CLI command spec, technology choices, trade-offs, failure modes, security, open questions.
3. **6-agent MAR:** Structure, feasibility, consistency, clarity, mdpal-app perspective, captain perspective. All Opus. 25 findings fixed directly, 8 sent to /discuss.
4. **MAR fixes applied:** Missing types (DocumentMetadata, DocumentInfo), renamed Bundle→DocumentBundle, added Document.diff(against:), added refreshSection(), clarified editSection scope, fixed contradictions, renamed YAML fields, added implementation notes for swift-markdown serialization, and many more.
5. **/discuss session (6 of 8 items):** Six major architectural decisions that reshape the engine-app relationship. See table above.
6. **ISCP dispatch sent:** Adoption intent dispatch to ISCP agent.
7. **Transcript maintained:** `usr/jordan/mdpal/transcripts/design-transcript-20260404.md`

## What Needs to Happen Next

### Immediate — Update A&D with /discuss Decisions

The A&D draft needs significant revision to incorporate today's 6 decisions. Key changes:

1. **Section 1 (System Overview):** Redraw architecture. App and engine are independent packages. Communication via ISCP dispatches + CLI commands. No direct library linking.
2. **Section 3 (Engine API Contract):** Reframe. The public contract is CLI command interface + ISCP dispatch format. The Swift `Document` type is still useful for the engine's internal API and for the app's read-only parsing, but it's not the inter-component boundary.
3. **Section 3.5 (File-Watching):** Complete rewrite. ISCP dispatches are the communication layer. Delete the filesystem notification discussion.
4. **Section 6 (Bundle Operations):** Add dual latest mechanism (symlink + pointer file). Note DocumentBundle is CLI/engine-only — app never calls it.
5. **Section 10.2 (Package Structure):** Restructure as independent packages. Research Swift/Xcode monorepo best practices first.
6. **New section: Testing Strategy** — five layers, coverage targets, QG discipline, tests in every iteration/phase.
7. **Resolve Items 7 & 8** — phase sequencing and auto-save decoupling.

### Then — Jordan Proposed a Dedicated Test Agent

Jordan asked: "Do we want a dedicated agent to work on tests and building them out for each and every iteration and phase? To review code for testability and review your tests as well as writing their own?"

This needs a decision on whether to create a third agent for the mdpal workstream. Discuss with Jordan next session.

### Then — Send Updated A&D to mdpal-app

After incorporating the /discuss decisions and the remaining 2 items, send a dispatch to mdpal-app with the revised A&D. Many of her original 5 answers are now superseded — she needs to know about the ISCP-based model.

### Then — MAR Round 2

Run another MAR on the revised A&D before Jordan review.

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/ad-mdpal-20260404.md` | A&D draft (needs revision per /discuss decisions) |
| `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` | PVR (final) |
| `usr/jordan/mdpal/transcripts/design-transcript-20260404.md` | Today's design transcript |
| `usr/jordan/mdpal/dispatches/dispatch-ad-app-response-20260404.md` | mdpal-app's A&D input (partially superseded) |
| `usr/jordan/mdpal/dispatches/dispatch-iscp-adoption-20260404.md` | ISCP adoption dispatch (sent today) |
| `usr/jordan/mdpal/dispatches/dispatch-ad-kickoff-20260404.md` | A&D kickoff dispatch (sent yesterday) |
| `claude/workstreams/mdpal/seeds/` | All seed materials (6 files) |
| `claude/workstreams/iscp/KNOWLEDGE.md` | ISCP workstream knowledge (read for context on dispatch model) |
| `usr/jordan/iscp/iscp-handoff.md` | ISCP agent bootstrap handoff |

## Jordan's Voice — Today's Session

- "Remember, our overriding principle that we're building tooling that works equally well for principals, aka humans, and for agents."
- "The bundle thing, that's all about humans. But we shouldn't cripple the agentic experience because we have a great human experience."
- On file-watching: "What I see is that an agent has prepared a PVR, and they want me to review it. Now right now that's a very painful process. So honestly, it doesn't happen."
- On pruning ownership: "You laid claim to pruning and all of this, didn't you? So I think you painted yourself into a corner."
- On testing: "I want tests laid down in each and every iteration and phase."
- On the test agent idea: "Do we want a dedicated agent to work on tests? To review code for testability and review your tests as well as writing their own?"
- "A very pragmatic approach to this implementation. We can tighten it up if we need to for performance, but for right now, I don't see it."
- On pluggable parsers via ISCP: "Also, this approach makes it easy for us to start plugging in other things into it with respect to support for other structured document types."
- "I firmly believe in a monorepo for delivery of a value stream."
