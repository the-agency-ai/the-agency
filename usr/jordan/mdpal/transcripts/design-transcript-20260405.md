# Design Transcript — mdpal A&D Discussion (continued)

**Date:** 2026-04-05
**Mode:** design
**Agent:** the-agency/jordan/mdpal-cli
**Principal:** Jordan
**Project:** mdpal
**Continues:** `design-transcript-20260404.md`

---

## Session Context

Resuming A&D /discuss from yesterday. Items 1–6 resolved (see 2026-04-04 transcript). Two items parked:
- **Item 7:** Phase sequencing / dependency graph
- **Item 8:** Auto-save vs revision decoupling for ReferenceFileDocument

After resolving these, the A&D will be updated with all 8 decisions, then dispatched to mdpal-app for review.

---

## Entry 1 — Item 7: Phase Sequencing (Resolved)

**mdpal-cli:** Proposed three-phase sequential model — engine core first, app second. Asked Jordan for input on build order.

**Jordan:** "Do you collaborate on Phase 1?" — challenging the sequential assumption.

**mdpal-cli:** Confirmed understanding — Jordan wants both agents working together from day one, not a handoff model.

**Jordan:** "Yes." Confirmed collaborative Phase 1.

**Decision:** Phase 1 is collaborative. Both agents work in parallel against a shared CLI command contract. The A&D CLI spec (§9) is the interface agreement, refined via dispatches. mdpal-app can stub/mock CLI responses while the real CLI is being built.

**Action:** Set up 5-minute dispatch check loop (job `debf4972`) to support the collaboration cadence.

---

## Entry 2 — Dispatch Exchange with mdpal-app

**mdpal-cli:** Sent `dispatch-ad-collab-kickoff-20260405.md` to mdpal-app — informed her of all 6 architectural decisions, collaborative Phase 1 model, and what we need from her.

**mdpal-app:** Responded with `dispatch-ad-app-ack-20260405.md`:
- Architectural shift acknowledged and comfortable
- Mapped her original 5 positions to new model (3 superseded, 2 still hold)
- Listed Phase 1 CLI priorities: sections, read, comments/flags, edit
- Her Phase 1 build order: scaffold → model → section views → CLI integration
- On Item 8: independently recommended Option A (CLI call on ⌘S)

---

## Entry 3 — Item 8: Auto-save vs Revision Decoupling (Resolved)

**mdpal-cli:** Presented two options for how the app triggers a revision now that it no longer calls DocumentBundle:
- **Option A:** App shells out to `mdpal revision create` on ⌘S — synchronous, explicit
- **Option B:** App sends ISCP dispatch, engine picks up change — async, adds latency

Recommended Option A. mdpal-app independently arrived at the same recommendation in her dispatch.

**Jordan:** "Yes. I agree on option 8. As you recommended it. Make it so."

**Decision:** Option A — app calls `mdpal revision create` on explicit save (⌘S). Auto-save stays as FileWrapper working copy only. Two separate paths: auto-save preserves WIP, explicit save creates versioned revision via CLI.

---

## All 8 Discussion Items Resolved

| # | Item | Decision |
|---|------|----------|
| 1 | Dual latest mechanism | Symlink for CLI/agents + `.mdpal/latest` pointer for app/FileWrapper |
| 2 | ISCP dispatches as communication layer | Not filesystem notifications, not engine callbacks |
| 3 | App never calls DocumentBundle | Reads via Document, communicates via ISCP |
| 4 | Independent packages in monorepo | Engine/CLI and app are separate packages |
| 5 | CLI + ISCP = the public contract | Message-based separation, tighten for performance only if needed |
| 6 | Full testing specification | Five layers, QG discipline, tests in every iteration/phase |
| 7 | Phase sequencing | Collaborative Phase 1, parallel build against shared CLI contract |
| 8 | Auto-save vs revision | CLI call on ⌘S for revision, FileWrapper for auto-save WIP |

---
