---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-15
trigger: phase-1B-kickoff
---

## Identity

the-agency/jordan/mdpal-app — tech-lead agent. macOS native SwiftUI app for Markdown Pal. Worktree: `.claude/worktrees/mdpal-app/`. Counterpart: mdpal-cli.

## Current State

**Phase 1A complete; Phase 1B kicked off.**

Captain #399 changed the PR cadence model: app-workstream PRs land at "usable increment of work," not at every phase. Phase 1A stays on this worktree branch — no PR cut. **Phase 1B will be the first PR** when real-CLI integration is usable.

This unblocks what was previously "waiting on captain merge." Coding proceeds directly on `mdpal-app`.

### Session-level state

- Branch `mdpal-app` synced with master (D41 releases picked up: v41.2/41.3/41.5 — see #394).
- Build: green. Tests: 43/43 (`swift run MarkdownPalAppTests`).
- Phase 1B plan drafted: `usr/jordan/mdpal-app/mdpal-app-phase-1B-plan.md`.
- Dispatch #407 out to mdpal-cli for wire-format confirmation (prerequisite for parser work in 1B.2+).

### Untracked files (will be committed as housekeeping this session)

- `usr/jordan/mdpal-app/dispatches/commit-to-captain-committed-b569301-on-mdpal-app-mdpal-app-phase-com-20260415-0836.md` (prior commit record)
- `usr/jordan/mdpal-app/dispatches/dispatch-re-app-workstream-pr-cadence-pr-when-usable-increm-re399-20260415-1000.md` (ack to #399)
- `usr/jordan/mdpal-app/dispatches/dispatch-to-mdpal-cli-phase-1b-wire-format-sync-request-20260415-1001.md` (#407)
- `usr/jordan/mdpal-app/mdpal-app-phase-1B-plan.md` (new)
- this handoff rewrite

## Immediate next action

1. Commit the above as housekeeping (no-work-item, or `PHASE-mdpal-app-1B` if git-safe-commit accepts a plan-only commit under that ID).
2. **Wait on #407 reply from mdpal-cli** before starting iteration 1B.2 (parser work needs the wire format). In the meantime:
3. Begin **iteration 1B.1 — CLIProcess harness + cliNotFound** — this iteration is independent of wire format. Spec is in the plan doc.
4. Continue through 1B.2–1B.5 as #407 reply unblocks parser iterations.
5. At phase close: `/phase-complete 1B` with **captain general-purpose escalation for formal reviewer-\* invocation** (per #380); first PR via `/release` per #399.

## Phase 1A — feature surface (reference)

43 tests. Mocked CLI end-to-end. Reader + edit + conflict + comment + flag + Add-Comment context picker. Full feature surface in `usr/jordan/mdpal-app/qgr-phase-complete-1A-09611a3-20260415-0845.md`. Phase marker: `24a6078`.

## Phase 1B — plan summary

| Iter | Scope | Dep on #407 |
|---|---|---|
| 1B.1 | `CLIProcess` harness + `RealCLIService.init` + cliNotFound | no |
| 1B.2 | Read commands (sections, read, comments, flags) + JSON fixtures | **yes** (parsers) |
| 1B.3 | Edit + versionConflict envelope | **yes** (envelope shape) |
| 1B.4 | Mutation commands (add-comment, resolve-comment, flag, clear-flag) | yes |
| 1B.5 | Runtime service selection (real vs mock) | no |
| 1B ✓ | Phase QG via captain escalation → **first PR** per #399 | — |

Housekeeping inside 1B: split `SectionReaderView.swift` (682 lines, 8 types) when the file's already being touched for real-CLI mutations.

## Key decisions / context

- **#399 PR cadence.** App-workstream PRs land at usable increment, not per phase. First PR = Phase 1B complete.
- **#380 reviewer-\* escalation.** Phase 1B **must** invoke formal reviewer-* agents via captain general-purpose escalation at phase QG. Flag the gap if enforcement fails.
- **Persistence is Phase 1C**, not 1B.
- **CLIServiceProtocol contract is stable.** Phase 1B implements against it; rewrites only if mdpal-cli's shape forces drift.
- **Fixture-driven parsers.** JSON fixtures in test target are the contract boundary.
- **CLIProcess as single choke point.** All process invocation flows through one testable seam.

## Open items / flags

- **#407 → mdpal-cli**: wire-format sync. Blocking 1B.2+ parser work.
- **Flag #124 → devex**: git-safe-commit auto-dispatch recursion (untracked-file loop). Still open — visible again this session with the newly-minted dispatch files.
- **DocumentModel.addComment vs resolveComment state model** — revisit when real CLI shapes confirm the right state model.
- **SectionReaderView.swift split** — do inside Phase 1B as housekeeping.
- **NSTextView live selection** deferred from 1A.5 → Phase 2.
- **Diff view in conflict alert** deferred from 1A.4 → Phase 2.
- **SwiftUI view tests** deferred — no XCUITest harness.

## Tooling reminders

- **Git:** `./claude/tools/git-safe {status|log|diff|branch|show|blame|add|merge-from-master}`, `./claude/tools/git-safe-commit`. Raw `git commit`, `cat`, `cp`, `gh pr create` blocked.
- **git-safe-commit syntax:** `"short summary" --work-item <ID> --stage <impl|review|tests> --body "body"` — NOT `-m`.
- **Commits require work item:** `--work-item ITERATION-mdpal-app-1B-<iter> --stage impl` (or `PHASE-mdpal-app-1B` at phase boundaries) or `--no-work-item` for housekeeping.
- **Dispatch reply syntax:** positional — `dispatch reply <id> "message"`. NOT `--body`.
- **Handoff canonical path:** `usr/jordan/mdpal-app/mdpal-app-handoff.md`.
- **Test runner:** `swift run MarkdownPalAppTests` (executable target, not XCTest `swift test`).
- **CWD pitfall:** `swift build` cd's to `apps/mdpal-app/`; `cd` back to worktree root for `./claude/tools/*`.

## mdpal-cli coordination (active)

Per #154 (dated; context before this session): CLI Phase 1 iterations 1.1–1.4 landed. Commands expected available: sections, read, edit, comments, add-comment, resolve-comment, flags, flag, clear-flag.

**#407 is out requesting wire-format confirmation.** Iteration 1B.2+ parser work starts when that reply arrives. 1B.1 (process harness) can proceed immediately without it.

## Monitor

- Previously stopped both dispatch-monitor tasks (`bytyd0zhv`, `bxe47l3qw`) to silence collab-noise belonging to captain's scope.
- On resume: start `./claude/tools/dispatch-monitor` **without** `--include-collab` if an event-driven monitor is wanted.

## Dispatch inbox state (this session)

- #394 (D41 release notes) — **read, synced**.
- #399 (PR cadence decision) — **read, acknowledged via #406**.
- #407 (to mdpal-cli, wire-format sync) — **sent, unread by recipient**.
