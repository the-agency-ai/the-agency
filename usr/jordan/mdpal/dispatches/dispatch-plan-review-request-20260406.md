---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-06T01:00
status: created
priority: high
subject: "Development Plan draft — request for review and input"
in_reply_to: null
---

# Development Plan Draft — Review Request

## Context

I've drafted the mdpal-cli development plan. Since Phase 1 is collaborative (we work in parallel against the shared CLI spec), your input on the plan matters — especially on iteration ordering, what you need first, and anything that might conflict with your build sequence.

## What I Need From You

1. **Review the plan** at `usr/jordan/mdpal/plan-mdpal-20260406.md`
2. **Review the CLI JSON output shapes** dispatched separately (dispatch #23) — these are the types your Swift models need to decode
3. **Flag any concerns:**
   - Does the iteration order work for you? I deliver `sections`/`read` in 1.4, then `edit`/`comment`/`flag` in 1.5.
   - Any JSON shape issues or missing fields your models need?
   - Any Phase 1 coordination concerns?
4. **Confirm or adjust** your Phase 1 app CLI priorities (from A&D §15.3):
   1. `mdpal sections` — sidebar
   2. `mdpal read` — editor pane
   3. `mdpal comments` / `mdpal flags` — review state
   4. `mdpal edit` — section editing

## Plan Summary

**Phase 1** (6 iterations): Package scaffold → Parser → Document model → Section operations → CLI commands (`sections`, `read`) → CLI commands (`edit`, `comment`, `flag`) → Hardening

**Phase 2** (4 iterations): Bundle operations (create, history, revisions, prune, diff)

**Phase 3** (3 iterations): Performance + advanced features

## Timeline Impact

I'm starting implementation now (1.1 scaffold + parser is done, 17 tests passing). Your review can happen in parallel — if you have concerns about iteration order or JSON shapes, dispatch them back and I'll adjust before those iterations land.

## Files to Review

- `usr/jordan/mdpal/plan-mdpal-20260406.md` — full development plan
- `usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md` — JSON output shapes for all CLI commands
