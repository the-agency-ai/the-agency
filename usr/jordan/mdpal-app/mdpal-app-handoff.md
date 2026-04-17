---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-17
trigger: phase-complete-1C
---

# mdpal-app handoff

**Branch:** mdpal-app (pushed through `7c23c78`; commits after that are local)
**Last commit:** `32e539b` Phase 1C.6: feat: --text-stdin / --response-stdin for large bodies
**Tests:** 139/139 green
**PR in flight:** #183 (Phase 1B, still open & unreviewed — Phase 1C commits stack on top)

## Session arc

One session shipped **Phase 1B (7 iterations + phase-complete + PR #183) AND Phase 1C (6 iterations + phase-complete)** — 14 iteration receipts + 2 phase-complete receipts, 60 → 139 tests (+79), all signed via receipt-sign v1 five-hash chain.

### Phase 1B (PR #183)

| Iter | Commit | Scope |
|------|--------|-------|
| 1B.1 | `8f80b7a` | CLIProcess harness + cliNotFound |
| 1B.2 | `b539144` | listSections + runCommand<T> + iso8601 decoder |
| 1B.3 | `a8264cd` | readSection + listComments + listFlags |
| 1B.4 | `29f5d23` | editSection + typed versionConflict + CLIErrorResponse rewrite per dispatch #23 |
| 1B.5 | `91610e2` | addComment + resolveComment + flagSection + clearFlag |
| 1B.6 | `433a98f` | CLIServiceFactory + DoS cap + stderr sanitization + ClipboardReader refactor |
| 1B.7 | `83fab61` | --tag repeatable per mdpal-cli #579 |
| phase | `28df449` | phase-complete receipt |

### Phase 1C (on mdpal-app branch, stacked atop Phase 1B)

| Iter | Commit | Scope |
|------|--------|-------|
| 1C.1 | `5e9ef6a` | cliResolution UI banner (1B.6 carry-forward) + Phase 1C plan |
| 1C.2 | `6d1db83` | commentNotFound typed envelope mapping |
| 1C.3 | `11ef182` | persistence protocol (createRevision + listHistory + showVersion + bumpVersion) |
| 1C.4 | `08c194d` | DocumentModel persistence wiring (bundleConflict-distinct-from-generic) |
| 1C.5 | `092f630` | history drawer UI (HistoryView + HistoryRow) |
| 1C.6 | `32e539b` | --text-stdin / --response-stdin adoption (16 KiB threshold) |
| phase | receipt `a92873b` | phase-complete receipt signed; PR deferred until #183 merges |

Receipts all under `claude/workstreams/mdpal/qgr/`.

## Cross-repo ledger

All 4 items filed to mdpal-cli via dispatch #575 came back resolved in #579 (Phase 2.3). Adopted:
- ✅ `--tag` repeatable (1B.7).
- ✅ `commentNotFound` typed envelope (1C.2).
- ✅ `--text-stdin` / `--response-stdin` (1C.6).
- ⏭️ `--` end-of-flags separator — mdpal-cli confirmed ArgumentParser handles it natively; no app change needed unless a bundle/slug starting with `-` crashes.

## Current state

- **PR #183 (Phase 1B)**: OPEN, REVIEW_REQUIRED, MERGEABLE. Captain #566 pre-approved the phase-complete → PR path. Principal's Sprint Review happens on the PR itself.
- **Phase 1C stacked on top**: commits `5e9ef6a` through `32e539b` land Phase 1C. They're on the `mdpal-app` branch and will show up in PR #183's diff if it's still open when reviewed — scope grows from "Phase 1B" to "Phase 1B + 1C persistence."
- **Branch state**: 8 commits ahead of origin/mdpal-app as of the last push (`7c23c78`). Need a final push to bring origin up to `32e539b` plus the phase-complete receipt commit pending below.

## Decisions for the reviewer

The principal/captain should decide whether the current PR #183 should:

1. **Merge as-is** — ship Phase 1B + 1C together as one "Phase 1 complete" PR. Title needs updating (from "Phase 1B" → "Phase 1B + 1C"). Scope: ~14 iterations, 139 tests, 2 phase-complete receipts.
2. **Revert Phase 1C commits locally and push a narrower PR #183** containing only through the Phase 1B phase-complete commit (`28df449`). Then land Phase 1C as PR #184 after #183 merges. This is the cleanest "one phase per PR" shape.
3. **Close #183 and open a fresh PR** for Phase 1B + 1C combined. Same net effect as (1) but with a cleaner PR-open moment.

No action needed from this agent until the principal picks a path.

## What's next (once the reviewer decides)

If PR #183 merges with 1B+1C scope:
- Update handoff to note Phase 1 (1A+1B+1C) shipped.
- Move to Phase 2 planning: NSTextView live selection, diff-in-conflict, XCUITest harness, per-error-type alert styling.

If 1C gets carved into PR #184 after #183:
- Push the phase-complete receipt + any pending housekeeping.
- Update PR #184 body with the 6-iteration ledger.
- Same Phase 2 planning afterwards.

## Key context / known patterns

- **Dispatch monitor running**: task `b4o8woihz` (persistent, no `--include-collab`).
- **receipt-sign v1** writes to `claude/workstreams/{W}/qgr/`. `git-safe-commit --no-verify` bypasses the stale retired-path check.
- **skill-verify reports 59 invalid** skills — deliberate flag #62/#63 pattern (inherit Bash(*) from settings.json). Ignore.
- **SourceKit stale diagnostics** are pervasive ("Cannot find X in scope") while `swift build` is clean — indexer cache lag. Safe to ignore.
- **Flag #124** auto-dispatch recursion perpetual residual — still the expected pattern.
- **Test runner stdout truncates at 4 KB** when piped. Use `script -q` for full output; read line count with `wc -l`, tail key lines with Grep.
- **CLIServiceProtocol now has 13 methods** (9 read/mutation from Phase 1B + 4 persistence from 1C.3). All three service implementations (Mock, Real, ToggleTracking/FailingToggle fakes) fully conform.

## Open items / carry-forwards

- `.notImplemented` error case — no stubs remain; dormant; revisit if new stubs land.
- Task-cancellation → child-process-termination in DefaultProcessRunner — lands with first cancellable caller (likely Phase 2's long-running prune/refresh).
- MarkdownDocument.fileWrapper explicit-save → createRevision wiring — deferred (1C wired the model side; SwiftUI integration needs ReferenceFileDocument save-path design thought).
- Diff-in-conflict alert, per-error alert styling, XCUITest harness — all Phase 2.
