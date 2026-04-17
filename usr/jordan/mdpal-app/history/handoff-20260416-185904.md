---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-15
trigger: iteration-complete-1B.1
---

# mdpal-app handoff

**Branch:** mdpal-app
**Last commit:** 8f80b7a — Phase 1B.1: feat: CLIProcess harness + RealCLIService init + cliNotFound
**Agency version:** 41.14

## Current state

- **Phase 1A: SHIPPED.** PR #93 merged this morning by captain (per dispatch #460). The mocked-CLI section reader, error surface, inline edit + conflict, and Add-Comment context picker are now in main as part of v41.14.
- **Phase 1B.1: COMPLETE.** Real-CLI integration foundation committed at 8f80b7a (NOT yet pushed to origin). 60/60 tests green. QGR at `usr/jordan/mdpal-app/qgr-iteration-complete-1B-1-d54cc05-20260415-1158.md`.

## What was done this session (post-1A-merge)

1. Captain landed v41.10/.12/.13 on main while I was mid-1B.1. Per dispatch #456: stashed 1B.1 WIP, fetched + merged origin/main into mdpal-app (manifest conflict resolved to 41.14, skipping 41.13), re-signed RGR at hash `f2b6702`, pushed `1a0809b`. Captain merged PR #93. Dispatched ack to captain (#458, #460 received).
2. Restored 1B.1 stash. Wrote `CLIProcess.swift` (ProcessRunner protocol, DefaultProcessRunner with concurrent pipe drain on a global dispatch queue + NSLock + stdin-error-to-stderr surfacing, CLIProcess composer, CLIBinaryResolver three-tier MDPAL_BIN→PATH→fallbacks with fallbacks injection seam) and `RealCLIService.swift` (final Sendable, init resolves binary or throws cliNotFound, 9 stub methods).
3. Ran QG via parallel general-purpose code/design/test reviewer — 13 raw findings → 8 fixes + 4 deferrals/dismissals with rationale. HIGH fixes: data race on drain captures (NSLock), silent stdin error (now appended to stderr). MEDIUM: cooperative-thread block (DispatchQueue.global), `@unchecked Sendable` removed, conditional resolver test fixed via `fallbacks` parameter, 5 DefaultProcessRunner integration tests added (proves the >64KB drain claim with a real ~256KB script), 2 cross-tier precedence tests.
4. Committed 8f80b7a with full QGR.

## What's next

1. **Push 8f80b7a to origin/mdpal-app.** Currently HEAD is 8f80b7a; origin is at 42061b3. Open a Phase 1B.1 PR, or hold until 1B.2 is ready and ship together.
2. **Phase 1B.2 — first real protocol method.** Likely `listSections` (simplest read). Re-read `dispatch read 408` to confirm whether mdpal-cli's #407 reply gives a committable wire-format spec. If still in flux, do the Phase 1B.5 housekeeping first (ClipboardReader environment-injection refactor — known Phase 1A carry-forward).
3. Continue Phase 1B per `usr/jordan/mdpal-app/mdpal-app-phase-1B-plan.md`. Iterations: 1B.2 sections+read, 1B.3 comments+flags, 1B.4 mutation methods, 1B.5 housekeeping + phase-complete.

## Key context surviving compaction

- **Dispatch monitor armed** (Monitor task `bxjdmnq9o`, persistent). New dispatches arrive as `<task-notification>` events.
- **Receipt v1 format** is required — use `./claude/tools/receipt-sign`, not hand-rolled markdown.
- **diff-hash excludes `claude/receipts/` AND `usr/**/dispatches/`** — receipts-only and dispatch-payload-only commits don't shift the diff hash. This is the workaround for flag #124 (git-safe-commit auto-dispatch recursion).
- **`git-safe-commit --staged`** skips the auto `git add -A` and is the way to commit without sweeping in residual untracked dispatches.
- **Captain pre-approved iteration commits** for mdpal-app workstream — no Sprint Review at iteration boundaries.
- **Reviewer-* agents not invocable from this agent class** — using parallel general-purpose substitutes per #380 documented interim path.

## Open items

- **PR push pending**: 8f80b7a not on origin yet.
- **#407 wire-format**: mdpal-cli replied via #408 (read). Re-read to confirm spec is committable for 1B.2.
- **Flag #124** (git-safe-commit auto-dispatch recursion): still open with devex; workaround documented above.
- **Flag #136**: my proposal to suppress auto-dispatch when committing only into `claude/receipts/` or with `--staged`.
- **ClipboardReader environment-injection refactor**: Phase 1A carry-forward, scheduled for Phase 1B.5.
- **Cross-repo collab dispatch**: SessionStart noted 1 unread monofolk dispatch about D41 enforcement gaps. Not mdpal-app workstream — defer to captain or principal.

## File map

- Phase 1B plan: `usr/jordan/mdpal-app/mdpal-app-phase-1B-plan.md`
- Latest QGR: `usr/jordan/mdpal-app/qgr-iteration-complete-1B-1-d54cc05-20260415-1158.md`
- App package: `apps/mdpal-app/` (SPM, macOS 14+)
- New 1B.1 files: `apps/mdpal-app/Sources/MarkdownPalApp/Services/CLIProcess.swift`, `RealCLIService.swift`
- Tests: `apps/mdpal-app/Tests/MarkdownPalAppTests/ModelTests.swift` (60 tests)
