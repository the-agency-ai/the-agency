---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-06
trigger: reboot
---

## Identity

the-agency/jordan/mdpal-cli — tech-lead agent. Owns the core engine, CLI, and bundle management for Markdown Pal. You are building the brain; mdpal-app builds the face.

**NEW: You now have your own worktree at `.claude/worktrees/mdpal-cli/`.** Previously shared with mdpal-app — now split. One agent, one worktree. Coordinate with mdpal-app via dispatches.

## Current State

Implementation Phase 1 in progress. Iteration 1.1 code complete (17 tests passing) but not committed via `/iteration-complete`. Iteration 1.2 (Document + Metadata) not started.

Key artifacts:
- PVR: `usr/jordan/mdpal/mdpal-cli-pvr-*.md` (check workstream for latest)
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md`
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md`
- Code: `apps/mdpal/` (Swift package — engine + CLI)

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

You reviewed both PVR (round 1 + round 2) and A&D. Your verdict: "solid and grounded, no structural issues." Read the A&D on startup.

## Active Work

- Iteration 1.1 code done, needs `/iteration-complete` to commit
- Iteration 1.2 next: Document + Metadata
- Dispatch #11 (JSON output shapes for CLI commands) — unread, process on startup
- Dispatch #7 (ISCP is live) — unread, process on startup

## Key Decisions

- Convention-based test scoping breaks for Swift layouts — use package-level fallback: "anything in `apps/mdpal/Sources/` → run `swift test` in `apps/mdpal/`"
- MARFI boundary: cross-cutting research only. Domain-specific Swift research is your normal work.
- Circuit breaker: time-based, not attempt-based

## Your Counterpart

mdpal-app owns the macOS SwiftUI app. Read their handoff at `usr/jordan/mdpal/mdpal-app-handoff.md`. Coordinate via dispatches — you are now on separate worktrees.

## Need Help?

If you're stuck or have a question, send a dispatch to captain: `dispatch create --to captain --subject "Question: ..." --body "..."`

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Run `/iteration-complete` for iteration 1.1 (code is ready, needs gate + commit)
6. Start iteration 1.2: Document + Metadata
