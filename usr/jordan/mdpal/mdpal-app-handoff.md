---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-06
trigger: reboot
---

## Identity

the-agency/jordan/mdpal-app — tech-lead agent. Owns the macOS native SwiftUI app for Markdown Pal. You build the face; mdpal-cli builds the brain.

**NEW: You now have your own worktree at `.claude/worktrees/mdpal-app/`.** Previously shared with mdpal-cli — now split. One agent, one worktree. Coordinate with mdpal-cli via dispatches.

## Current State

Implementation Phase 1A in progress. SwiftUI app scaffold shipped: models (Comment, DocumentModel, Flag, Section, ResponseTypes), views (ContentView, MarkdownContentView, MarkdownDocument, SectionListView, SectionReaderView), services (CLIServiceProtocol, MockCLIService), tests (ModelTests — 735 lines). Code is on main (merged from mdpal branch).

Key artifacts:
- PVR: check `usr/jordan/mdpal/` for latest
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md`
- Code: `apps/mdpal-app/` (SwiftUI package)

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

You reviewed both PVR (rounds 1 + 2) and A&D (rounds 1 + 2). Your A&D verdict: "no structural concerns." Best reviewer across both rounds. Read the A&D on startup.

## Active Work

- Phase 1A implementation in progress — models and views scaffolded, iteration work ongoing
- Continue implementing per plan at `usr/jordan/mdpal/plan-mdpal-20260406.md`
- MAR review dispatches fully resolved — no pending reviews

## Key Decisions

- MDPal tray for principal notifications stays in NFR1 — MDPal is an Agency application
- Three-bucket: reviewers give raw feedback, authors triage (you flagged this correction in round 1)
- Cross-workstream RFI works — you tested it with library linking question to mdpal-cli
- Convention-based test scoping: package-level for Swift (`apps/mdpal-app/Sources/` → run tests in `apps/mdpal-app/`)
- Bootstrap handoffs: captain writes them. You suggested clarifying this — incorporated.

## Your Counterpart

mdpal-cli owns the core engine, CLI, and LSP server. Read their handoff at `usr/jordan/mdpal/mdpal-cli-handoff.md`. Coordinate via dispatches — you are now on separate worktrees.

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Read your plan: `usr/jordan/mdpal/plan-mdpal-20260406.md`
6. Continue Phase 1A implementation
