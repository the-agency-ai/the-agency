# Handoff: mdpal-app

---
type: session-end
date: 2026-04-04 08:45
principal: jordan
agent: the-agency/jordan/mdpal-app
workstream: mdpal
trigger: session-end
previous: mdpal-app-handoff (session-end, 2026-04-04 00:20)
---

## Who You Are

You are **mdpal-app**, a tech-lead agent owning the **macOS native SwiftUI app** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-cli** owns the core engine, LSP server, and CLI — the foundation your app talks to. You share the `mdpal` worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md` on session start for shared context.

## What Is Markdown Pal

A **section-oriented tool for structured documents** — enabling both humans and agents to read, edit, comment, flag, and diff documents at the section level rather than the line/file level. Markdown is the first format; the engine is designed for pluggable parsers supporting source code, log files, and other grammar-defined formats.

**The bigger vision:** A paradigm shift from line-oriented agent tooling (`Read`, `Edit`, `Write` — the `sed` and `cat` of the AI era) to structure-oriented operations.

## Current State — PVR FINAL, A&D In Progress

### PVR Status: APPROVED ✓

All sign-offs complete:
- ✓ mdpal-app (author)
- ✓ mdpal-cli (dispatch sign-off, 2026-04-03)
- ✓ Jordan (principal approval, 2026-04-04)

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` (final)

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

### A&D Status: WAITING ON mdpal-cli

mdpal-cli leads A&D. I've sent my response dispatch (`dispatch-ad-app-response-20260404.md`) answering their five questions:

1. **API style:** Typed Swift structs, thrown errors, async for I/O, sync for in-memory
2. **Revisions:** Explicit save only, pruning is user-initiated
3. **Comments/flags:** Typed structs — engine handles YAML internally
4. **File-watching:** Callback/notification model, engine re-parses on change
5. **File I/O:** App owns `FileWrapper`, engine is pure transform. Two modes: CLI owns files, app owns data

**Next from cli:** They will draft the A&D with engine API contract first, then send a dispatch with the API surface for my review.

## Next Action

### Wait for mdpal-cli's API surface dispatch

When it arrives:
1. Read the proposed API surface
2. Evaluate against my five answers above
3. Push back on anything that doesn't fit the app's consumption model
4. Iterate via dispatches, or ask Jordan for a joint `/discuss` if we can't align

### If no dispatch yet

Check `usr/jordan/mdpal/dispatches/` for new files from mdpal-cli. If nothing new, the ball is in their court — nothing to do but wait.

## Key Files

| File | Location | What |
|------|----------|------|
| `pvr-mdpal-20260403-1447.md` | `usr/jordan/mdpal/` | PVR (FINAL) |
| `pvr-mdpal-20260403-1443.md` | `usr/jordan/mdpal/` | PVR (pre-MAR draft) |
| `PVR-markdown-pal.md` | `usr/jordan/mdpal/` | PVR (session 1, items 1-4 only) |
| `dialogue-transcript-20260403.md` | `usr/jordan/mdpal/transcripts/` | My session with Jordan |
| `discuss-swift-crossplatform-20260403.md` | `usr/jordan/mdpal/transcripts/` | mdpal-cli's session with Jordan |
| `PVR-transcript-20260329.md` | `usr/jordan/mdpal/transcripts/` | Session 1 transcript |
| `dispatch-pvr-review-and-completion-process-20260403.md` | `usr/jordan/mdpal/dispatches/` | My initial dispatch to cli |
| `dispatch-pvr-cli-response-20260403.md` | `usr/jordan/mdpal/dispatches/` | cli's PVR input |
| `dispatch-pvr-post-mar-20260403.md` | `usr/jordan/mdpal/dispatches/` | My post-MAR dispatch to cli |
| `dispatch-pvr-cli-signoff-20260403.md` | `usr/jordan/mdpal/dispatches/` | cli's PVR sign-off |
| `dispatch-ad-kickoff-20260404.md` | `usr/jordan/mdpal/dispatches/` | cli's A&D kickoff (READ, answered) |
| `dispatch-ad-app-response-20260404.md` | `usr/jordan/mdpal/dispatches/` | My A&D response (SENT this session) |
| `markdown-pal-seed-20260329.md` | `usr/jordan/mdpal/seeds/` | Primary design seed |

## Flags for Captain

Two flags raised last session (in flag queue):
1. **Bug:** `dispatch-create` resolves `$USER` to `testuser` instead of `jordan` in the mdpal worktree context
2. **Feature:** Dispatch tools need to handle merging to master and pulling from master — currently dispatches between agents on different branches require manual file copying

## Licensing

Reference Source License. See `claude/workstreams/mdpal/LICENSE`.
