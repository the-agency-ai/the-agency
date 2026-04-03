# Handoff: mdpal-app

---
type: session-end
date: 2026-04-04 00:20
principal: jordan
agent: the-agency/jordan/mdpal-app
workstream: mdpal
trigger: session-end
previous: mdpal-app-handoff (bootstrap, 2026-04-03)
---

## Who You Are

You are **mdpal-app**, a tech-lead agent owning the **macOS native SwiftUI app** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-cli** owns the core engine, LSP server, and CLI — the foundation your app talks to. You share the `mdpal` worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md` on session start for shared context.

## What Is Markdown Pal

A **section-oriented tool for structured documents** — enabling both humans and agents to read, edit, comment, flag, and diff documents at the section level rather than the line/file level. Markdown is the first format; the engine is designed for pluggable parsers supporting source code, log files, and other grammar-defined formats.

**The bigger vision:** A paradigm shift from line-oriented agent tooling (`Read`, `Edit`, `Write` — the `sed` and `cat` of the AI era) to structure-oriented operations.

## Current State — PVR Complete, A&D Starting

### PVR Status: SIGNED OFF by mdpal-cli, pending Jordan's final approval

The PVR went through:
1. Two sessions with Jordan (mdpal-app session: items 1-6 review + revisions; mdpal-cli session: Swift, structured editing, items 5-9)
2. Dispatch exchange between agents (my dispatch → cli response → my PVR draft)
3. Two MAR rounds (6 review agents total, 15+7 findings, all addressed or KIV'd)
4. mdpal-cli review and sign-off

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` (post-MAR, on worktree)

### Key PVR Decisions

| # | Item | Decision |
|---|------|----------|
| 1 | Core Value Prop | Section-oriented ops on structured documents, Markdown first |
| 2 | Target Users | AI-augmented pairs (human:agent, agent:agent), core tooling |
| 3 | Platform Priority | Engine library first (Phase 1), CLI + app in parallel (Phase 2). No protocol layer — library-first |
| 4 | Bundle Format | Core for Markdown Pal V1; optional for future non-Markdown formats. Engine owns bundle ops, app owns presentation |
| 5 | Agent Interface | CLI is the agent interface. MCP/LSP deferred |
| 6 | V1 Scope | Five capabilities: read, edit, comment, flag, diff. Symmetric for agents (CLI) and principals (app) |
| 7 | Research Comments | r001/r006/r009 dissolved/deferred. r003/r004 → me. r002/r005/r008 → mdpal-cli. All in A&D |
| 8 | Relationship to Agency | Infrastructure for Agency workflows — solves review/feedback friction |
| 9 | Competitive Landscape | Nothing fills the gap |
| — | Language | Swift. macOS first, Linux second, Windows deferred |
| — | Platform Versions | macOS 14+ (Sonoma), Swift 5.9+ |

### A&D Status: KICKOFF — mdpal-cli leads

mdpal-cli sent `dispatch-ad-kickoff-20260404.md` with five questions for me. **This is the morning's first task.**

## Next Action — Morning Plan

### Step 1: Get Jordan's PVR sign-off
The PVR is ready. Ask Jordan to review `pvr-mdpal-20260403-1447.md` and sign off. Quick — mdpal-cli already approved.

### Step 2: Respond to mdpal-cli's A&D kickoff dispatch
Send a dispatch answering their five questions about how the app wants to consume the engine:

1. **Engine API call style:** I want typed Swift structs. `engine.readSection("authentication")` returns a `Section` struct with content, slug, version hash, child sections. Errors as Swift `Result` types or thrown errors, not return codes. Async where file I/O is involved.

2. **Bundle revision triggers:** New revision on explicit save (not auto-save). The app holds the document in memory, user saves → engine creates new revision. Pruning is a user action (menu item or preference-driven auto-prune).

3. **Comment and flag data shape:** Typed Swift structs, not raw YAML. `Comment` struct with id, type, author, section, version hash, context, text, resolution. `Flag` struct with section slug, optional note, timestamp. The engine parses YAML internally and hands me clean types.

4. **File-watching (r003):** I want a callback/notification model. The engine should support registering a watcher — when the file changes externally, the engine notifies the app so it can re-render. The engine re-parses on notification, not on every call. This is important for the app holding a persistent document model.

5. **File I/O ownership (r004):** The app owns the `FileWrapper` (SwiftUI's `DocumentGroup` requires this). The app reads raw data from the `FileWrapper` and hands it to the engine for parsing. The engine returns modified content; the app writes it back via `FileWrapper`. The engine doesn't touch the filesystem directly when used by the app — it's a pure transform layer. (The CLI uses a different path where the engine does its own file I/O.)

### Step 3: Continue A&D collaboration
mdpal-cli will draft the A&D focusing on the engine API contract first. When they send the API surface for review, evaluate it against my answers above. Iterate via dispatches or ask Jordan for a joint `/discuss` if needed.

## Key Files

| File | Location | What |
|------|----------|------|
| `pvr-mdpal-20260403-1447.md` | `usr/jordan/mdpal/` | PVR (post-MAR, current) |
| `pvr-mdpal-20260403-1443.md` | `usr/jordan/mdpal/` | PVR (pre-MAR draft) |
| `PVR-markdown-pal.md` | `usr/jordan/mdpal/` | PVR (session 1, items 1-4 only) |
| `dialogue-transcript-20260403.md` | `usr/jordan/mdpal/transcripts/` | My session with Jordan |
| `discuss-swift-crossplatform-20260403.md` | `usr/jordan/mdpal/transcripts/` | mdpal-cli's session with Jordan |
| `PVR-transcript-20260329.md` | `usr/jordan/mdpal/transcripts/` | Session 1 transcript |
| `dispatch-pvr-review-and-completion-process-20260403.md` | `usr/jordan/mdpal/dispatches/` | My initial dispatch to cli |
| `dispatch-pvr-cli-response-20260403.md` | `usr/jordan/mdpal/dispatches/` | cli's PVR input |
| `dispatch-pvr-post-mar-20260403.md` | `usr/jordan/mdpal/dispatches/` | My post-MAR dispatch to cli |
| `dispatch-pvr-cli-signoff-20260403.md` | `usr/jordan/mdpal/dispatches/` | cli's PVR sign-off |
| `dispatch-ad-kickoff-20260404.md` | `usr/jordan/mdpal/dispatches/` | cli's A&D kickoff (UNREAD — answer this first) |
| `markdown-pal-seed-20260329.md` | `usr/jordan/mdpal/seeds/` | Primary design seed |

## Flags for Captain

Two flags raised this session (in flag queue):
1. **Bug:** `dispatch-create` resolves `$USER` to `testuser` instead of `jordan` in the mdpal worktree context
2. **Feature:** Dispatch tools need to handle merging to master and pulling from master — currently dispatches between agents on different branches require manual file copying

## Licensing

Reference Source License. See `claude/workstreams/mdpal/LICENSE`.
