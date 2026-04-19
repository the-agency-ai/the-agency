---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-14
trigger: pre-0300-pause
---

## Identity

the-agency/jordan/mdpal-app — tech-lead agent. macOS native SwiftUI app for Markdown Pal. Worktree: `.claude/worktrees/mdpal-app/`. Counterpart: mdpal-cli (separate worktree).

## ⚠️ Paused until 0300

Principal directive: **resume Phase 1A work at 2026-04-15 03:00**. Timer: cron job `6288de17` (one-shot). Monitor `bxe47l3qw` running for dispatches. Do no proactive work before the timer fires.

## What happened this session (2026-04-14)

1. **Merged from main** — 54 commits landed cleanly as `d1a438e`. No conflicts (one expected sparse-worktree artifact: `test/test-agency-project` shown deleted).
2. **New tooling rules now active here**: git-safe family enforced by hookify. Raw `git status/log/diff/merge` blocked. Use `/git-safe`, `/git-safe-commit`, `/git-captain` (captain only). Raw `cat` also blocked — use Read tool. Raw `cp` and `gh pr create` also blocked.
3. **Replied to captain's merge-confirmation directive (#302)** — but the reply body did not transmit correctly (see bug below). Captain sent two follow-ups (#310, #312) asking for the status. Captain has accepted that the response lives in this handoff instead.
4. **Skills discipline reminder from principal** — stop shelling to `./agency/tools/dispatch` directly; use `/dispatch`. Stop using raw git; use `/git-safe`. Going forward, invoke skills via the Skill tool.

## Captain's merge-confirmation response (per #312 — lives here until bug fixed)

1. **Merge clean?** Yes. 54 commits from main merged as `d1a438e`. No conflicts. `test/test-agency-project` shown deleted is the usual sparse-worktree artifact.
2. **Questions / needs?** None blocking. Acknowledge git-safe family is now the only allowed git path here.
3. **Blocking next iteration?** No. Phase 1A scaffold intact. Paused until 0300.

## 🐛 Dispatch tool bug — investigate at 0300 (captain directive #312)

**Symptom:** `./agency/tools/dispatch reply <id> --body "..."` (and `--body-file`) produces a dispatch with body content equal to the literal string `--body` (or `--body-file`). Two empty replies landed this session: #309 (`--body`) and #311 (`--body-file`).

**Hypothesis:** the tool's argument parser is reading the flag *name* as the body value, i.e. the positional slot that should hold the body content is being filled by the flag name itself. Could be a shift/offset bug, or the CLI treats `--body` as a positional rather than a flag-with-value.

**At 0300, investigate:**
1. Read `agency/tools/dispatch` source — find how `reply` subcommand parses `--body` / `--body-file`.
2. Compare to `create --body` which other agents use successfully.
3. Check if the issue is shell-level: Bash quoting? `$(...)` expansion? Heredoc? Principal's earlier heredoc through the Bash tool had issues — may or may not be related.
4. Try: `dispatch create --to ... --subject ... --body "test"` — does that work? If yes, the bug is isolated to `reply`.
5. File findings as a bug/flag, or send a dispatch to devex if it's a framework bug.

**Workaround until fixed:** write response content in this handoff or in a dispatch *file* (pre-written payload) rather than inline flag.

## Phase 1A state (unchanged — no code written this session)

Scaffold intact at `apps/mdpal-app/`:
- Models: Comment, DocumentModel, Flag, Section, ResponseTypes
- Views: ContentView, MarkdownContentView, MarkdownDocument, SectionListView, SectionReaderView
- Services: CLIServiceProtocol, MockCLIService
- Tests: ModelTests (735 lines)
- Last verified `swift build` passes in ~43s
- Iteration work NOT advanced this session

## Dispatch state

- #302 ← captain — merge directive — read, replied (but reply empty due to tool bug)
- #309 → captain — empty reply (tool bug)
- #310 ← captain — "empty response, please reconfirm" — read, replied (again empty)
- #311 → captain — empty reply (tool bug)
- #312 ← captain — "tool is broken, investigate at 0300, put response in handoff" — read, honored here
- Monitor `bxe47l3qw` still running

## mdpal-cli coordination (unchanged from prior handoff)

Per #154 (2026-04-07): iterations 1.1–1.3 landed (124 tests), 1.4 bundle source compiled.
Coordination decision: JSON shapes for CLI commands stay deferred until mdpal-cli implements Phase 2. App continues against `MockCLIService` + dispatch #23 spec. Swap stubs in one pass when real shapes land.

## Environment notes

- `CLAUDE_PROJECT_DIR` is not always exported to the shell — when invoking tools manually, may need `export CLAUDE_PROJECT_DIR=/Users/jdm/code/the-agency/.claude/worktrees/mdpal-app` first. Skills handle this correctly; direct bash does not.
- Sparse worktree still in effect. Still never `git add .`.
- stop-check.py turn-loop problem from previous sessions appears mitigated by Monitor + 15m loop.

## Startup actions (next session at 0300)

1. **Check timer fired correctly** — expect prompt "Resume autonomous Phase 1A work..."
2. `/dispatch list` — process anything new (use skill, not raw tool)
3. `/flag list`
4. **First investigation task**: dispatch tool bug per #312. File fix or dispatch to devex.
5. **Then Phase 1A iteration work** per `usr/jordan/mdpal/plan-mdpal-20260406.md`. Likely targets: section-reader interaction flows, comment/flag state management in views, test expansion.
6. **Commit via `/git-safe-commit`** — new canonical path; git-commit is renamed.

## Open questions (carried)

- Dispatch `reply --body` / `--body-file` bug — investigate at 0300
- mdpal-cli Phase 1 completion status — ping if still needed after checking their handoff

## Timer + monitor

- Cron: `6288de17` — one-shot 2026-04-15 03:00
- Monitor: `bxe47l3qw` — event-driven dispatch watch

*No further proactive work until 0300.*
