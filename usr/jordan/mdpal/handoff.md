# Handoff: Markdown Pal — Bootstrap

---
type: agency-bootstrap
date: 2026-04-03 18:30
principal: jordan
agent: the-agency/jordan/mdpal
workstream: mdpal
---

## What Is Markdown Pal

A **section-oriented Markdown review tool** for human:agent and agent:agent collaboration. The core insight: agents rewrite entire documents when they should be doing scoped, section-level edits. Markdown Pal fixes this with token-efficient, section-oriented operations.

**Two deliverables:**
- **Engine + CLI** (`mdpal-cli` agent) — core library + LSP server + CLI
- **macOS native app** (`mdpal-app` agent) — SwiftUI client of the engine/LSP

**Licensing:** Reference Source License (view, contribute, no commercial redistribution). See `claude/workstreams/mdpal/LICENSE`.

## PVR Status — 4 of 9 Items Resolved

The PVR discussion (`/discuss`) completed items 1-4. Items 5-9 remain.

**Resolved decisions:**
1. **Core Value Proposition** — Token-efficient section-oriented review. Agents shouldn't rewrite whole documents to change one section.
2. **Target Users** — Human:agent pairs (human reviews in GUI, agent via CLI/MCP) and agent:agent pairs (structured, token-efficient operations).
3. **Platform Priority** — Phase 1: Core engine + LSP server (the brain). Phase 2: CLI and SwiftUI app in parallel (both are clients).
4. **Bundle Format (.mdpal)** — Confirmed. Apple ecosystem (macOS/iOS), symlinks, FileWrapper, package UTTypes all natively supported. Small text files, track in git normally.

**Remaining items:**
5. Agent Interface Priority (CLI / MCP / LSP) — was active when session ended
6. V1 Scope
7. Research Comments (r001-r009) resolution strategy
8. Relationship to The Agency
9. Competitive Landscape / Why Build This

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/PVR-markdown-pal.md` | PVR (in progress) |
| `usr/jordan/mdpal/transcripts/PVR-transcript-20260329.md` | Discussion transcript |
| `claude/workstreams/mdpal/KNOWLEDGE.md` | Workstream knowledge |
| `claude/workstreams/mdpal/seeds/` | Seed materials (analysis, chatlog, CLI spec, prompt, seed) |
| `claude/workstreams/mdpal/seeds/markdown-pal-seed-20260329.md` | Primary design seed (architecture, LSP, CLI, bundle format) |
| `claude/workstreams/mdpal/seeds/markdown-pal-analysis-20260329.md` | CoS analysis of seeds |

## Your Worktree

You are on branch `mdpal` in a worktree at `.claude/worktrees/mdpal/`. Work here, commit at boundaries via `/iteration-complete`. Land on master via `/phase-complete`.

## Next Action

Resume PVR at item 5 (Agent Interface Priority) via `/discuss`. Read the PVR, transcript, and seeds before continuing — the transcript has the full reasoning behind items 1-4.
