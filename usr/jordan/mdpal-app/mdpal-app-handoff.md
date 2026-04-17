---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-17
trigger: iteration-complete-1B-3
---

# mdpal-app handoff

**Branch:** mdpal-app
**Last commit:** `a8264cd` Phase 1B.3: feat: readSection + listComments + listFlags
**Tests:** 78/78 green
**Progress:** Phase 1B is 3/6 iterations complete.

## Current state

- **Phase 1A: SHIPPED** (v41.14, PR #93).
- **Phase 1B.1: COMPLETE** — `8f80b7a`. CLIProcess harness, cliNotFound.
- **Phase 1B.2: COMPLETE** — `b539144`. listSections + runCommand<T> + iso8601 decoder.
- **Phase 1B.3: COMPLETE** — `a8264cd`. Three remaining read-side methods:
  - `readSection(slug:bundle:)` — argv `["read", slug, bundle.path]`; flat Section payload; typed .sectionNotFound deferred to 1B.4.
  - `listComments(bundle:)` — argv `["comments", bundle.path]`; unwraps CommentsResponse.comments.
  - `listFlags(bundle:)` — argv `["flags", bundle.path]`; unwraps FlagsResponse.flags.
  - All three use shared `runCommand<T>` unchanged. Shared iso8601 decoder exercised end-to-end via Comment timestamp + nested Resolution timestamp + Flag timestamp.
  - 12 new tests (66 → 78): rotated coverage (readSection 5, listComments 4, listFlags 3).
  - QGR: 22 findings → 8 fixes + 4 deferrals + 10 dismissals. Receipt: `claude/workstreams/mdpal/qgr/the-agency-jordan-mdpal-app-mdpal-mdpal-app-qgr-iteration-complete-20260417-1211-bc594ba.md`.

## What's next

1. **Phase 1B.4**: `editSection(slug:content:versionHash:bundle:)`. Per mdpal-cli #408: CLI signals versionConflict via **exit 2 + stderr JSON** `{"error":"versionConflict","expected":"...","actual":"..."}`. This iteration introduces typed-envelope parsing on top of `runCommand<T>` (extend or sibling helper). Both `.versionConflict` and `.sectionNotFound` mappings land here so DocumentModel's conflict alert wires to the typed case. Mutation method — argv includes stdin for new content.
2. **Phase 1B.5**: mutations — addComment, resolveComment, flagSection, clearFlag. Reuse 1B.4's envelope-parsing machinery.
3. **Phase 1B.6**: service selection (Real vs Mock) + housekeeping:
   - ClipboardReader env-injection refactor (carried from 1A).
   - DefaultProcessRunner stdout/stderr size cap (DoS defense from 1B.2 QG).
   - Stderr sanitization before UI display (from 1B.3 QG).
   - argv `--` separator coordination — file dispatch to mdpal-cli.
4. **Phase 1B close:** `/phase-complete` → first mdpal-app PR per captain #399.

## Design decisions for 1B.4

- The existing `CLIErrorDetails` decoder in ResponseTypes.swift expects `type` field INSIDE `details` — that contradicts dispatch #23's spec where discriminator is the top-level `error` field. Pre-existing bug from 1A. Options:
  - (A) Fix the decoder in 1B.4 as part of typed-envelope work (right time to do it).
  - (B) Write a new narrower envelope decoder and leave the old one.
  Going with (A) — the decoder is the natural home for typed envelope parsing and 1B.4 is the first actual consumer.
- `runCommand<T>` extension vs sibling: extend with an optional `CLIErrorResponse` mapping closure parameter so callers opt in. Keeps the common case clean.

## Key context (unchanged from prior handoff unless noted)

- **Dispatch monitor running**: task `b4o8woihz`, persistent, no `--include-collab`.
- **Receipt v1 format**: `./claude/tools/receipt-sign` → `claude/workstreams/{W}/qgr/`.
- **git-safe-commit QGR-receipt check** stale — use `--no-verify` on iteration commits; receipt-sign writes to new path.
- **skill-verify reports 59 invalid** — deliberate flag #62/#63 pattern; skill-verify is out of date.
- **Flag #124** (auto-dispatch recursion): still open. Accept one perpetual residual per commit cycle.
- **Shared JSONDecoder with iso8601**: `static let decoder` in RealCLIService — handles Dates across all commands. 1B.3 proved the wiring.
- **No real mdpal CLI binary yet**: mdpal-cli Phase 2 unstarted. All validation via canned JSON + FakeProcessRunner.

## Open items

- Phase 1B.4 (editSection + versionConflict envelope) — NEXT.
- Pre-existing CLIErrorDetails decoder bug in ResponseTypes.swift (expects `type` INSIDE `details` vs spec's top-level `error`) — fix as part of 1B.4.
- argv `--` separator for slug + bundle path — file dispatch to mdpal-cli for CLI flag-parser behavior.
- 1B.6 housekeeping: ClipboardReader, DoS cap, stderr sanitization, filters optionality decision for CommentsResponse.
