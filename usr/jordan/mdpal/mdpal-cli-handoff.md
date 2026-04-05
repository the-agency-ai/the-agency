# Handoff: mdpal-cli

---
type: session-handoff
date: 2026-04-05
principal: jordan
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
trigger: session-end
previous: mdpal-cli-handoff (mid-session-compact, 2026-04-04)
---

## Who You Are

You are **mdpal-cli**, a tech-lead agent owning the **core engine, CLI, and bundle management operations** for Markdown Pal — a section-oriented tool for structured document operations. You are building the brain; mdpal-app is building the face.

Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-app** owns the macOS native SwiftUI app — the human interface. You share the `mdpal` worktree and branch. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read her handoff at `usr/jordan/mdpal/mdpal-app-handoff.md` on startup for shared context.

## Current State

### PVR: FINAL — signed off by all parties (2026-04-04)

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`

### A&D: REVISED — all 8 /discuss items resolved, revision complete

The A&D has been through:
1. Full 14-section draft (2026-04-04)
2. 6-agent MAR with 25 findings fixed (2026-04-04)
3. /discuss with Jordan: 8 items resolved (6 on 2026-04-04, 2 on 2026-04-05)
4. Full revision incorporating all 8 decisions (2026-04-05)

**A&D file:** `usr/jordan/mdpal/ad-mdpal-20260404.md` (now 16 sections, 1369 lines)

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
| 8 | **CLI call on ⌘S for revision** — auto-save is FileWrapper working copy only | §6.7, §9.2 |

### Dispatch Exchange Today

| Dispatch | Direction | Status |
|----------|-----------|--------|
| `dispatch-ad-review-ready-20260405.md` | mdpal-app → us | Read. No blockers, one flag (superseded by Decision #2) |
| `dispatch-ad-collab-kickoff-20260405.md` | us → mdpal-app | Sent. Informed her of all 6 decisions, collaborative Phase 1 |
| `dispatch-ad-app-ack-20260405.md` | mdpal-app → us | Read. She acknowledged shift, listed Phase 1 priorities, agreed Option A for Item 8 |
| `dispatch-ad-item8-resolved-20260405.md` | us → mdpal-app | Sent. Item 8 resolution + CLI spec coming next |
| `dispatch-iscp-adoption-20260404.md` | us → ISCP agent | Sent yesterday. No response yet |

## What Was Done This Session (2026-04-05)

1. **Resolved Item 7** (phase sequencing): Collaborative Phase 1 — both agents work in parallel against shared CLI command contract.
2. **Resolved Item 8** (auto-save vs revision): Option A — app shells out to `mdpal revision create` on ⌘S. Auto-save is FileWrapper working copy only.
3. **Full A&D revision** incorporating all 8 decisions:
   - Rewrote §1 (system overview diagram + independent packages)
   - Reframed §3 (Swift API is engine-internal, CLI + ISCP is public contract)
   - Rewrote §3.5 (ISCP communication model replaces file-watching)
   - Updated §3.6 (app never calls engine API directly)
   - Added dual latest mechanism to §6.1
   - Updated §6.6 (pointer management + crash recovery)
   - Updated §6.7 (revision triggers — CLI call on save)
   - Added `mdpal revision create` to §9.2
   - Restructured §10.2 (independent packages in monorepo)
   - Added §11.1 (trade-off: independent packages vs direct linking)
   - Updated §11.3 (Document class rationale)
   - Added §14 (testing strategy — five layers, QG discipline)
   - Added §15 (phase sequencing — collaborative Phase 1)
4. **Dispatched to mdpal-app** — collab kickoff + Item 8 resolution
5. **Set up 5-minute dispatch check loop** for collaboration cadence
6. **Maintained transcript** at `usr/jordan/mdpal/transcripts/design-transcript-20260405.md`

## What Needs to Happen Next

### Immediate — MAR Round 2

Run another 6-agent MAR on the revised A&D. The revision was substantial (new sections, rewritten sections, changed architectural model). Needs review before Jordan sign-off.

### Then — Test Agent Decision

Jordan proposed a dedicated test agent. Deferred to Phase 1 start in the A&D, but needs a conversation before implementation begins.

### Then — Plan

With PVR final and A&D nearing final, the next artifact is the Plan — phases, iterations, QGRs. The phase sequencing (§15) provides the skeleton.

### Then — Implementation

Phase 1 collaborative build. Engine core + CLI basics + app scaffold.

## Key Files

| File | What |
|------|------|
| `usr/jordan/mdpal/ad-mdpal-20260404.md` | A&D (revised with all 8 decisions) |
| `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` | PVR (final) |
| `usr/jordan/mdpal/transcripts/design-transcript-20260405.md` | Today's transcript |
| `usr/jordan/mdpal/transcripts/design-transcript-20260404.md` | Yesterday's transcript |
| `usr/jordan/mdpal/dispatches/` | All dispatches (10 files) |
