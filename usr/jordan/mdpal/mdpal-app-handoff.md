# Handoff: mdpal-app — Bootstrap

---
type: agency-bootstrap
date: 2026-04-03 18:45
principal: jordan
agent: the-agency/jordan/mdpal-app
workstream: mdpal
---

## Who You Are

You are **mdpal-app**, a tech-lead agent owning the **macOS native SwiftUI app** for Markdown Pal. Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-cli** owns the core engine, LSP server, and CLI — the foundation your app talks to. You share this worktree. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md` on session start for shared context.

## What Is Markdown Pal

A **section-oriented Markdown review tool** for human:agent and agent:agent collaboration. Agents rewrite entire documents when they should be doing scoped, section-level edits. Markdown Pal fixes this with token-efficient, section-oriented operations.

**Your scope:** macOS native SwiftUI app — a rich GUI client of the engine/LSP that mdpal-cli builds. Section navigation, visual review workflows, comment threading, diff views. Apple ecosystem: FileWrapper, UTTypes, `.mdpal` bundle presentation.

**Licensing:** Reference Source License. See `claude/workstreams/mdpal/LICENSE`.

## PVR Status — 4 of 9 Items Resolved

| # | Item | Status | Decision |
|---|------|--------|----------|
| 1 | Core Value Proposition | Resolved | Token-efficient section-oriented review |
| 2 | Target Users | Resolved | Human:agent pairs + agent:agent pairs |
| 3 | Platform Priority | Resolved | Phase 1: engine + LSP. Phase 2: CLI + SwiftUI in parallel |
| 4 | Bundle Format (.mdpal) | Resolved | Confirmed. Apple ecosystem, git-tracked normally |
| 5 | Agent Interface Priority | **Active** | Was in progress when session ended |
| 6 | V1 Scope | Pending | |
| 7 | Research Comments | Pending | |
| 8 | Relationship to The Agency | Pending | |
| 9 | Competitive Landscape | Pending | |

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/PVR-markdown-pal.md` | PVR (in progress) |
| `usr/jordan/mdpal/transcripts/PVR-transcript-20260329.md` | Discussion transcript |
| `usr/jordan/mdpal/seeds/` | Seed materials |
| `usr/jordan/mdpal/seeds/markdown-pal-seed-20260329.md` | Primary design seed — architecture, LSP, CLI, bundle format |
| `claude/workstreams/mdpal/KNOWLEDGE.md` | Workstream knowledge |

## Next Action

You are blocked on mdpal-cli — the engine/LSP must exist before you can build a client for it. Your first work will come after PVR completion when the A&D defines the app's architecture. For now, read the PVR and seeds to build context. You can contribute to PVR items 5-9 (especially V1 Scope and Agent Interface Priority, which affect your surface).
