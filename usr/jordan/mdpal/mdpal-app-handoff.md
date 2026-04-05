# Handoff: mdpal-app

---
type: session-end
date: 2026-04-05 10:00
principal: jordan
agent: the-agency/jordan/mdpal-app
workstream: mdpal
trigger: session-end
previous: mdpal-app-handoff (session-end, 2026-04-04 08:45)
---

## Who You Are

You are **mdpal-app**, a tech-lead agent owning the **macOS native SwiftUI app** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-cli** owns the core engine, LSP server, and CLI — the foundation your app talks to. You share the `mdpal` worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md` on session start for shared context.

## What Is Markdown Pal

A **section-oriented tool for structured documents** — enabling both humans and agents to read, edit, comment, flag, and diff documents at the section level rather than the line/file level. Markdown is the first format; the engine is designed for pluggable parsers supporting source code, log files, and other grammar-defined formats.

**The bigger vision:** A paradigm shift from line-oriented agent tooling (`Read`, `Edit`, `Write` — the `sed` and `cat` of the AI era) to structure-oriented operations.

## Current State — PVR FINAL, A&D Nearing Completion

### PVR Status: APPROVED ✓

All sign-offs complete:
- ✓ mdpal-app (author)
- ✓ mdpal-cli (dispatch sign-off, 2026-04-03)
- ✓ Jordan (principal approval, 2026-04-04)

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` (final)

### A&D Status: 8/8 ITEMS RESOLVED — mdpal-cli revising draft

mdpal-cli completed a full `/discuss` with Jordan resolving all 8 architectural items. **The architecture has shifted significantly from the original draft I reviewed.** Key changes:

#### 6 Major Architectural Decisions (from /discuss)

| # | Decision | Impact on App |
|---|----------|---------------|
| 1 | **Dual latest mechanism** — symlink + `.mdpal/latest` pointer file | App reads pointer file via FileWrapper, not symlink |
| 2 | **ISCP dispatches are the communication layer** — not callbacks/FSEvents | No engine-level change notifications. Communication via ISCP. My §3.5 flag is superseded |
| 3 | **App never calls DocumentBundle** | Only use `Document(content:parser:)`. Bundle is CLI/engine-only |
| 4 | **Independent packages in monorepo** — no direct library linking | Contract is CLI commands (JSON) + ISCP dispatches, not Swift types |
| 5 | **CLI commands + ISCP format = the public contract** | Swift types are engine-internal. App parses JSON output |
| 6 | **Full testing specification** — five layers, QG discipline | Tests in every iteration |

#### Item 8 Resolution (2026-04-05)

**Option A confirmed:** App shells out to `mdpal revision create <bundle> --stdin` on explicit save (⌘S). Auto-save is FileWrapper only — no revision, no CLI call.

### What I've Acknowledged

Sent `dispatch-ad-app-ack-20260405.md` confirming:
- Comfortable with the architectural shift to CLI + ISCP contract
- My original typed-Swift-structs position → now I parse CLI JSON into my own types
- My callback/notification position → superseded by ISCP
- Shared my Phase 1 build order and CLI command priorities

### My Phase 1 Build Order

1. App scaffold — Xcode project, SwiftUI DocumentGroup, ReferenceFileDocument for `.md` files
2. Document model — parse CLI JSON into app-side Swift types
3. Section list view — sidebar from `mdpal sections` output
4. Section reader — main pane from `mdpal read` output
5. CLI integration layer — `Process` wrapper for invoking `mdpal` commands

Items 1-4 can start with mock data. Item 5 needs finalized CLI spec.

### My Phase 1 CLI Priorities

1. `mdpal sections` — list sections (drives sidebar)
2. `mdpal read` — read a section (drives editor pane)
3. `mdpal comments` / `mdpal flags` — display review state
4. `mdpal edit` — section editing with optimistic concurrency

Bundle commands (create, history, prune, diff) are Phase 2 for the app.

## Next Action

### Waiting on mdpal-cli:
1. **Revised A&D** incorporating all 8 decisions — they're writing this now
2. **Revised CLI command spec (§9)** — with JSON output shapes for my Phase 1 commands

### When those arrive:
1. Review the revised A&D from the app's perspective
2. Review CLI spec — confirm JSON shapes work for my document model
3. Push back if anything doesn't fit
4. Then MAR round 2

### Can start immediately:
- App scaffold with mock data (items 1-4 of build order) — Jordan offered, pending decision

## Uncommitted Changes

**`usr/jordan/mdpal/ad-mdpal-20260404.md`** has uncommitted changes — this is **mdpal-cli's revision** of the A&D (158 insertions, 103 deletions incorporating the 8 decisions). This is their work to commit, not mine.

## Dispatches This Session

| File | Direction | What |
|------|-----------|------|
| `dispatch-ad-review-ready-20260405.md` | → cli | Asked if they're ready for 1B1 with Jordan |
| `dispatch-ad-collab-kickoff-20260405.md` | ← cli | 6 major decisions, architecture shift notification |
| `dispatch-ad-app-ack-20260405.md` | → cli | Acknowledged shift, shared Phase 1 plan + CLI priorities |
| `dispatch-ad-item8-resolved-20260405.md` | ← cli | Item 8 resolved (Option A — shell out on save) |

## Key Files

| File | Location | What |
|------|----------|------|
| `pvr-mdpal-20260403-1447.md` | `usr/jordan/mdpal/` | PVR (FINAL) |
| `ad-mdpal-20260404.md` | `usr/jordan/mdpal/` | A&D (being revised by mdpal-cli — uncommitted changes) |
| `dialogue-transcript-20260403.md` | `usr/jordan/mdpal/transcripts/` | My session with Jordan |
| `discuss-swift-crossplatform-20260403.md` | `usr/jordan/mdpal/transcripts/` | mdpal-cli's session with Jordan |
| `markdown-pal-seed-20260329.md` | `usr/jordan/mdpal/seeds/` | Primary design seed |

## Dispatch Loop

Set up a 5-minute recurring dispatch check via `/loop 5m /dispatch-read` (cron job `28497647`). Will need to be re-created next session.

## Flags for Captain

Two flags raised in a previous session (in flag queue):
1. **Bug:** `dispatch-create` resolves `$USER` to `testuser` instead of `jordan` in the mdpal worktree context
2. **Feature:** Dispatch tools need to handle merging to master and pulling from master — currently dispatches between agents on different branches require manual file copying

## Licensing

Reference Source License. See `claude/workstreams/mdpal/LICENSE`.
