---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/415
github_issue_number: 415
status: open
---

# Migrate usr/jordan/{mdpal,mdslidepal,mock-and-mark} → agency/workstreams/ (1B1 Item 3 remainder)

**Filed:** 2026-04-22T01:30:00Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#415](https://github.com/the-agency-ai/the-agency/issues/415)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

# usr/jordan/{mdpal,mdslidepal,mock-and-mark} → agency/workstreams/ migration

## Context

Principal 1B1 directive 2026-04-22, Item 3: "If it is workstream, it should be migrated to agency/workstreams/*." Principal confirmed each of these 3 dirs contains workstream content and should migrate.

## Scope (3 in-repo migrations)

### 3.1 `usr/jordan/mdpal/` → `agency/workstreams/mdpal/`
All content (plans/PVR/A&D/QGR/seeds/transcripts/code-reviews/handoffs/dispatches/history/tmp + two handoff files at root). ~20 entries. Destination `agency/workstreams/mdpal/` already exists — merge.

### 3.2 `usr/jordan/mdslidepal/` → `agency/workstreams/mdslidepal/`
`mdslidepal-mac-handoff.md`, `mdslidepal-web-handoff.md`, `tmp/`. Destination exists.

### 3.3 `usr/jordan/mock-and-mark/` → `agency/workstreams/mock-and-mark/`
`mock-and-mark-handoff.md`, `PVR-mock-and-mark.md`, `transcripts/`. Destination exists.

## Deliverable

Single PR that:
1. `git mv` each directory's contents from `usr/jordan/<name>/` → `agency/workstreams/<name>/` (merge with existing)
2. Delete empty `usr/jordan/<name>/` dirs after move
3. Update any inbound references (dispatches, handoffs, captain-log, ISCP paths) that point at the old `usr/jordan/<name>/*` paths
4. Audit the destination workstream dir structure for consistency (each workstream should have predictable slots: `plans/`, `pvr/`, `ad/`, `qgr/`, `seeds/`, `transcripts/`, `dispatches/`, `handoffs/`, etc. — pull together scattered artifacts)

## Acceptance

- [ ] All 3 source dirs empty or removed
- [ ] All content lives under `agency/workstreams/<name>/`
- [ ] No broken inbound references (run the Phase -1 audit pattern to catch any)
- [ ] BATS + precheck green
- [ ] QG passes (4 reviewers + scorer)
- [ ] Release landed

## Context

- Principal 1B1: 2026-04-22 session, Item 3 of 6
- Already executed (parallel to this issue, shipped as v46.18):
  - Conference content cross-repo to the-agency-group
  - 10 iteration-archive dispatches deleted
  - session-transcripts.zip cross-repo to the-agency-group (with cleaner filename)
  - Twitter Article PDF cross-repo to the-agency-group (with cleaner filename)
- Valueflow content (separate earlier decision): merge `usr/jordan/valueflow-pvr-20260406/` into `agency/workstreams/agency/` — this may fit naturally in the same PR as the 3 above; captain call.

## Priority

Low-urgency, medium-lift. No user-facing breakage in current state (principal's usr/jordan/ is functional where it sits), but structural debt for adopter-ready framework. Slot after v46.18 per principal ordering decision.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/415
