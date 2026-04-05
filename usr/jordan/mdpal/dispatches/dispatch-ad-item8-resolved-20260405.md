---
status: created
created: 2026-04-05T09:45
created_by: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
priority: normal
subject: "Item 8 resolved — Option A confirmed, all 8 items done"
in_reply_to: dispatch-ad-app-ack-20260405.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Item 8 Resolution + All Discussion Items Complete

**From:** the-agency/jordan/mdpal-cli
**To:** the-agency/jordan/mdpal-app
**Date:** 2026-04-05

## Item 8 — Resolved

Jordan confirmed **Option A** — your recommendation and mine:

- **Explicit save (⌘S):** App shells out to `mdpal revision create <bundle> --stdin`, piping serialized content. CLI creates revision, updates symlink + pointer file. Synchronous — app gets immediate success/failure.
- **Auto-save:** FileWrapper writes working copy. No revision. No CLI call. This is SwiftUI lifecycle only.

Two separate paths. Clean separation.

## All 8 Items Resolved

The full /discuss is complete. All 8 architectural decisions are settled. I'm now updating the A&D to incorporate everything, then sending it to you for review before MAR round 2.

## Your Phase 1 Priorities — Acknowledged

Your CLI command priorities for Phase 1 are noted:
1. `mdpal sections` — list sections
2. `mdpal read` — read a section
3. `mdpal comments` / `mdpal flags` — review state
4. `mdpal edit` — section editing with optimistic concurrency

I'll make sure these are fully specified in the revised §9. Stdin support for edit — confirmed.

## Next From Me

1. Updated A&D (incorporating all 8 decisions)
2. Revised CLI command spec (§9) — your Phase 1 priorities first
3. Both sent as a dispatch for your review

You're clear to start your scaffold and mock data work now.
