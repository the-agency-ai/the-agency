---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-15
trigger: phase-complete
---

## Identity

the-agency/jordan/mdpal-app — tech-lead agent. macOS native SwiftUI app for Markdown Pal. Worktree: `.claude/worktrees/mdpal-app/`. Counterpart: mdpal-cli.

## ⚠️ Phase 1A complete — awaiting land-on-master

`/phase-complete 1A` ran. Marker commit `24a6078`. Self-review QGR landed.
Captain pre-approved (#380). Reply sent (#382) requesting merge or direction.

**Do not start Phase 1B coding before captain confirms the merge** — Phase 1B requires master to carry Phase 1A.

## Phase 1A — final state

| Iter | Commit | Tests Δ | Scope |
|---|---|---|---|
| 1A.1 | (pre-split) | 28 baseline | Scaffold: models/views/MockCLIService |
| 1A.2 | `80fbe37` | +6 → 34 | SectionReaderView interaction (flag/comment/resolve) |
| 1A.3 | `4a74d37` | +2 → 36 | Error presentation surface — `.alert` on `document.lastError` |
| 1A.4 | `eee24d9` | +2 → 38 | Inline edit flow + version-hash conflict UI |
| 1A.5 | `fe7cb37` | +5 → 43 | Add-Comment context picker (clipboard-backed prefill) |
| 1A | `24a6078` | (marker) | **Phase complete** |

- **43/43 tests passing**, clean build, zero warnings
- Phase QGR: `usr/jordan/mdpal-app/qgr-phase-complete-1A-09611a3-20260415-0845.md`
- Iteration QGRs: see `usr/jordan/mdpal-app/qgr-iteration-complete-1A-{2,3,4,5}-*.md`

## Phase 1A feature surface (reference)

- NavigationSplitView with section list + reader detail
- Section header (heading, slug, version hash, level), flag banner, comment thread
- Toolbar:
  - Edit / Save / Cancel (inline TextEditor, version-hash optimistic concurrency)
  - Add Comment menu (plain + Comment-on-Selection clipboard prefill, substring-gated)
  - Flag / Clear Flag toggle
- Sheets: AddCommentSheet (with optional context prefill), ResolveCommentSheet, FlagEditorSheet
- Errors: generic `.alert` bound to `document.lastError`; version conflict has its own Overwrite/Discard/Keep-editing alert
- Backing: `MockCLIService` end-to-end (CLIServiceProtocol abstraction ready for real-CLI swap)

## Immediate next action

**Idle until captain replies on #382 with merge confirmation or direction.** When master carries Phase 1A:

1. `./claude/tools/git-safe merge-from-master` to bring Phase 1A back into the mdpal-app branch as the new starting point
2. Begin **Phase 1B planning** — real-CLI integration (per captain #380):
   - Implement a `RealCLIService: CLIServiceProtocol` that shells to `mdpal` CLI per dispatch #23 JSON spec
   - Wire it behind a flag or env var so MockCLIService stays available for previews/tests
   - Handle CLI process lifecycle (find binary, error on absence — `CLIServiceError.cliNotFound`)
   - Bundle path resolution from open document
   - Phase 1B QG **must** invoke formal reviewer-* agents via captain general-purpose escalation (per #380); flag the enforcement gap if hit
3. Optional Phase 1B housekeeping: split SectionReaderView.swift (682 lines, 8 types) into smaller files. Captured in phase QGR's deferred list.

## Key decisions / context for next session

- **Reviewer-* agent escalation path:** for Phase 1B+, captain confirmed formal reviewer agents should be invoked via captain general-purpose escalation when this agent class can't reach them directly. Flag enforcement gaps if hit.
- **Persistence is Phase 1C**, not 1B. Don't conflate.
- **Edit conflict UX is intentionally distinct from generic errors** — the `EditConflict` alert offers Overwrite/Discard/Keep-editing rather than just an error message. Real-CLI needs to surface `versionConflict` as a typed error so the view can route correctly.
- **Sheet error-return Bool pattern** is the established idiom for any new mutation sheet.
- **Stateful mocks** (`ToggleTrackingService`, `FailingToggleService`) live in test target — Phase 1B may want similar harnesses for real-CLI error injection.

## Open items / flags

- **Flag #124 → devex**: git-safe-commit auto-dispatch recursion (untracked-file loop on session-compact). Still open.
- **DocumentModel.addComment vs resolveComment state model inconsistency** — Phase 1B integration decision (real CLI's behavior may force the resolution).
- **NSTextView live selection capture** deferred from 1A.5.
- **Diff view in conflict alert** deferred from 1A.4.
- **SwiftUI view tests** deferred — no XCUITest harness in this Swift Package setup.
- **SectionReaderView.swift split** — recommend in Phase 1B per phase QGR.

## Tooling reminders

- **Git:** `./claude/tools/git-safe {status|log|diff|branch|show|blame|add|merge-from-master}`, `./claude/tools/git-safe-commit`. Raw `git`, `cp`, `cat`, `gh pr create` blocked.
- **git-safe-commit syntax:** `"short summary" --work-item <ID> --stage <impl|review|tests> --body "body"` — NOT `-m`.
- **Commits require work item:** `--work-item ITERATION-mdpal-app-<phase>-<iter> --stage impl` (or `PHASE-mdpal-app-<phase>` at phase boundaries) or `--no-work-item` for housekeeping.
- **Dispatch reply syntax:** positional — `dispatch reply <id> "message"`. NOT `--body`.
- **Handoff canonical path:** `usr/jordan/mdpal-app/mdpal-app-handoff.md`.
- **CWD pitfall:** `swift build` cd's to `apps/mdpal-app/`; `cd` back to worktree root for `./claude/tools/*`.

## mdpal-cli coordination (active reference for Phase 1B)

Per #154: CLI Phase 1 iterations 1.1–1.3 landed (124 tests), 1.4 bundle source compiled. Phase 1B's real-CLI bridge consumes:
- JSON wire format from dispatch #23
- CLI commands: sections, read, edit, comments, add-comment, resolve-comment, flags, flag, clear-flag
- Bundle path mechanics from CLI Phase 1.4

Coordinate with mdpal-cli before designing the bridge — confirm wire format hasn't drifted.

## Monitor

- Dispatch monitor task IDs: `bytyd0zhv`, `bxe47l3qw` (both alive; both firing collab noise that is captain's scope).
- On resume: consider restarting monitor without `--include-collab` since the cross-repo queue is captain's, not mdpal-app's.
- `./claude/tools/dispatch-monitor` (without `--include-collab`) for mdpal-app-only alerts.
