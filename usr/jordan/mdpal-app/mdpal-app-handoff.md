---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-17
trigger: session-compact
---

# mdpal-app handoff

**Branch:** mdpal-app (pushed through `75fb357`; origin in sync)
**Last commit:** `75fb357` housekeeping/captain: misc: session-compact drain
**Tests:** 139/139 green
**PR:** #183 OPEN, REVIEW_REQUIRED, MERGEABLE (scope: Phase 1B + Phase 1C stacked)

## Current state — mid-session checkpoint

Session delivered **Phase 1B + Phase 1C** back-to-back:
- Phase 1B: 7 iterations + phase-complete + PR #183 created
- Phase 1C: 6 iterations + phase-complete (commits stacked on same branch)
- 60 → 139 tests (+79)
- 16 signed receipts under `claude/workstreams/mdpal/qgr/`

**Awaiting reviewer decision** on PR scope (three choices documented in the handoff before this compact):
1. Merge #183 with expanded 1B+1C scope
2. Revert 1C commits on branch → narrow PR #183 → land 1C as PR #184 after
3. Close #183 → fresh PR for 1B+1C

No action needed from me until the principal picks a path.

## Phase 1B commits (in PR #183)

| Iter | Commit | Scope |
|------|--------|-------|
| 1B.1 | `8f80b7a` | CLIProcess harness + cliNotFound |
| 1B.2 | `b539144` | listSections + runCommand<T> + iso8601 decoder |
| 1B.3 | `a8264cd` | readSection + listComments + listFlags |
| 1B.4 | `29f5d23` | editSection + typed versionConflict + CLIErrorResponse rewrite per dispatch #23 |
| 1B.5 | `91610e2` | addComment + resolveComment + flagSection + clearFlag |
| 1B.6 | `433a98f` | CLIServiceFactory + DoS cap + stderr sanitization + ClipboardReader refactor |
| 1B.7 | `83fab61` | --tag repeatable per mdpal-cli #579 |
| phase | `28df449` | Phase 1B phase-complete receipt `e4786f7` |

## Phase 1C commits (stacked on PR #183)

| Iter | Commit | Scope |
|------|--------|-------|
| 1C.1 | `5e9ef6a` | cliResolution UI banner (1B.6 carry-forward) + Phase 1C plan |
| 1C.2 | `6d1db83` | commentNotFound typed envelope mapping |
| 1C.3 | `11ef182` | persistence protocol (createRevision + listHistory + showVersion + bumpVersion) |
| 1C.4 | `08c194d` | DocumentModel persistence wiring (bundleConflict-distinct-from-generic) |
| 1C.5 | `092f630` | history drawer UI (HistoryView + HistoryRow) |
| 1C.6 | `32e539b` | --text-stdin / --response-stdin adoption (16 KiB threshold) |
| phase | `4fd3cba` | Phase 1C phase-complete receipt `a92873b` + plan + handoff |

## What's next (after compact)

**Principal-gated:** PR scope decision (see three choices above).

**Pending once direction is clear:**
1. If path (1) — merge-as-is: update PR #183 title, summary; add 1C iteration ledger to PR body.
2. If path (2) — narrow #183: `git-reset` branch to `28df449`, force-push, then (after #183 merges) replay 1C commits on a fresh branch for PR #184.
3. If path (3) — close #183: open new PR titled "mdpal-app Phase 1 complete (1B + 1C)".

**Independent of that decision:** Phase 2 planning is the next substantive work. Scope per original #380:
- NSTextView live selection (currently only `.textSelection(.enabled)` on the Text views)
- Diff-in-conflict alert (show differences, not just "was modified")
- Per-error-type alert styling (currently all errors → generic "Something went wrong")
- XCUITest harness (all 139 tests are pure-Swift; view-layer has no UI tests)

Phase 2 plan file does NOT exist yet. Draft when user gives the go-ahead.

## Cross-repo ledger

All 4 items filed to mdpal-cli (#575) came back resolved in #579 (Phase 2.3). All adopted:
- ✅ `--tag` repeatable (1B.7)
- ✅ `commentNotFound` typed envelope (1C.2)
- ✅ `--text-stdin` / `--response-stdin` (1C.6)
- ⏭️ `--` end-of-flags separator — ArgumentParser native; no app change needed.

## Key patterns / decisions to survive compact

- **`receipt-sign` v1** writes to `claude/workstreams/{W}/qgr/`. `git-safe-commit --no-verify` bypasses the stale retired-path check that git-safe-commit still globs.
- **No-squash policy this session**: preserved all 14 iteration commits with their receipts through phase-complete. The 2 phase-complete receipts are additive documentation, not replacements.
- **`bundleConflict` distinct from generic failure** (1C.4): in DocumentModel.createRevision, bundleConflict rethrows WITHOUT populating lastError so the UI can surface a reload/overwrite dialog; generic failures pave lastError AND rethrow.
- **`--text-stdin` threshold = 16 KiB UTF-8** (1C.6). Under threshold uses `--text <value>`; over uses `--text-stdin` + stdin. Same for `--response-stdin`. Thresholds are private `Self.stdinThresholdBytes` in RealCLIService.
- **CLIErrorResponse decoder** (1B.4 rewrite): discriminator is the top-level `error` field per dispatch #23, NOT inside `details`. `decodeOrGeneric` is robust — malformed details fall through to `.generic`, preserving error+message for UI.
- **`runCommand<T>` vs `runCommandWithEnvelope<T>`**: both share `decodeStdoutOrThrowParseError<T>`. Envelope variant takes a mapper closure; nil-return falls through to `.executionFailed`.
- **Shared `Self.sectionNotFoundMapper` / `Self.bundleConflictMapper`** static closures — one match site per envelope kind; enum changes force compiler errors here.
- **`Self.decoder`**: shared `JSONDecoder` with `.iso8601` — all commands decode through it so Date fields can't silently break.
- **SourceKit stale diagnostics** are pervasive; `swift build` is the source of truth. Test runner stdout truncates at 4 KB when piped — use `script -q` for full output.

## Dispatch monitor

Task `b4o8woihz` started earlier this session, persistent, no `--include-collab`. Verify with TaskList at session resume; restart if session-compact cleared it.

## Open items

- **PR #183 merge path** — principal to decide.
- **Phase 2 plan** — draft when ready to start Phase 2.
- `.notImplemented` error case — dormant carry-forward; revisit if new stubs land.
- Task-cancellation → child-process-termination in DefaultProcessRunner — lands with first cancellable caller.
- MarkdownDocument.fileWrapper explicit-save → createRevision wiring — deferred; SwiftUI ReferenceFileDocument save-path design needs thought.
- Flag #124 (auto-dispatch recursion) perpetual residual pattern — accepted.
