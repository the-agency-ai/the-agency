# Handoff: mdpal-cli

---
type: session-handoff
date: 2026-04-05
principal: jordan
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
trigger: session-end
previous: mdpal-cli-handoff (session-end, 2026-04-05 earlier)
---

## Who You Are

You are **mdpal-cli**, a tech-lead agent owning the **core engine, CLI, and bundle management operations** for Markdown Pal — a section-oriented tool for structured document operations. You are building the brain; mdpal-app is building the face.

Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-app** owns the macOS native SwiftUI app — the human interface. You share the `mdpal` worktree and branch. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read her handoff at `usr/jordan/mdpal/mdpal-app-handoff.md` on startup for shared context.

## Current State

### PVR: FINAL — signed off by all parties (2026-04-04)

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`

### A&D: REVISED + MAR'd — all 8 items resolved, MAR round 2 complete

The A&D has been through:
1. Full 14-section draft (2026-04-04)
2. 6-agent MAR with 25 findings fixed (2026-04-04)
3. /discuss with Jordan: 8 items resolved (6 on 2026-04-04, 2 on 2026-04-05)
4. Full revision incorporating all 8 decisions (2026-04-05)
5. 6-agent MAR round 2 — findings fixed (2026-04-05)
6. Two remaining MAR items resolved with Jordan:
   - Working copy location: app auto-saves outside the bundle via FileWrapper; bundle is CLI/engine-only
   - Serialize command: not a gap — app holds full text in memory as a document editor

**A&D file:** `usr/jordan/mdpal/ad-mdpal-20260404.md` (16 sections, ~1369 lines)

### All 8 Architectural Decisions

| # | Decision | A&D Section Updated |
|---|----------|-------------------|
| 1 | **Dual latest mechanism** — symlink for CLI/agents + pointer file for app/FileWrapper | §6.1, §6.6 |
| 2 | **ISCP dispatches are the communication layer** — not filesystem notifications | §3.5 (rewritten) |
| 3 | **App never calls DocumentBundle** — communicates via ISCP + CLI | §3, §3.6, §6.7 |
| 4 | **Independent packages in monorepo** — no direct library linking | §1, §10.2 |
| 5 | **CLI + ISCP = the public contract** — message-based separation | §3, §11.1 |
| 6 | **Full testing specification** — five layers, QG discipline | §14 (new) |
| 7 | **Collaborative Phase 1** — both agents work in parallel against shared CLI spec | §15 (new) |
| 8 | **CLI call on Cmd-S for revision** — auto-save is FileWrapper working copy only | §6.7, §9.2 |

### Plan: NOT YET DRAFTED — research complete

Plan mode research is saved in the Claude plan file. Gathered:
- All types, CLI commands, phase sequencing from A&D
- Plan format conventions from existing plans in the repo
- Ready to draft but session ended before writing

## Dispatches — Awaiting Responses

| Dispatch | Direction | Status |
|----------|-----------|--------|
| captain MAR findings | us → captain | Sent. Worktree model question (should mdpal-cli and mdpal-app have separate branches?) — **no response yet** |
| ISCP MAR findings | us → ISCP agent | Sent. Dispatch type requirements, payload format, notification mechanism — **no response yet** |
| ISCP adoption | us → ISCP agent | Sent 2026-04-04. No response yet |

All inbound dispatches from mdpal-app have been read and acknowledged.

## Known Issue: Agent Identity

This worktree resolves as `the-agency/jordan/captain` instead of `the-agency/jordan/mdpal-cli`. The `agent-identity` tool has no override for this worktree. This means:
- `iscp-check` checks the captain mailbox, not mdpal-cli
- Dispatches addressed to mdpal-cli won't trigger notifications
- Needs framework/captain fix: agent identity override for worktrees

## What Was Done This Session (2026-04-05, session 2)

1. Checked dispatches — found #10 and #3 addressed to captain from ISCP agent (not responses to our queries)
2. Identified agent identity resolution bug (resolves as captain, not mdpal-cli)
3. Confirmed no responses yet to our captain/ISCP dispatches from last session

## What Needs to Happen Next

### Immediate — Draft the Development Plan

Plan mode research is complete. Draft the plan with phases and iterations based on:
- A&D §15 (phase sequencing — collaborative Phase 1)
- A&D §14 (testing strategy)
- PVR requirements

Then MAR the plan before Jordan sign-off.

### Also — Fix Agent Identity

Raise to captain: worktree agent identity needs an override mechanism so mdpal-cli resolves correctly and gets its own dispatch notifications.

### Also — Check for Dispatch Responses

On next session start, check if captain or ISCP agent responded to our dispatches about:
- Worktree model (separate branches for mdpal-cli vs mdpal-app?)
- Dispatch type requirements for mdpal communication

### Then — Implementation

Phase 1 collaborative build. Engine core + CLI basics + app scaffold.

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/ad-mdpal-20260404.md` | A&D (revised, MAR'd, all 8 decisions) |
| `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` | PVR (final) |
| `usr/jordan/mdpal/transcripts/design-transcript-20260405.md` | Today's transcript |
| `usr/jordan/mdpal/transcripts/design-transcript-20260404.md` | Yesterday's transcript |
| `usr/jordan/mdpal/dispatches/` | All dispatches |
