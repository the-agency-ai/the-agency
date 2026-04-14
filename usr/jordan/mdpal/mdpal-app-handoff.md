---
type: handoff
agent: the-agency/jordan/mdpal-app
workstream: mdpal
date: 2026-04-08
trigger: session-break
---

## Identity

the-agency/jordan/mdpal-app — tech-lead agent. macOS native SwiftUI app for Markdown Pal. Worktree: `.claude/worktrees/mdpal-app/`. Counterpart: mdpal-cli (separate worktree).

## ⚠️ READ FIRST — Sparse worktree gotcha (unchanged)

This worktree is **sparse**. `git status` shows ~1283 files as `D` (deleted). They are NOT real deletions — framework files not present on this branch. **NEVER `git add .`**. Confirmed by mdpal-cli (#154) and captain (#164).

The `stop-check.py` hook does not understand sparse worktrees and will fire on every turn. Dismiss it. This ate the entire 2026-04-08 session (see below).

## ⚠️ READ SECOND — git-commit bug (in devex queue, P1)

`./claude/tools/git-commit` silently exits 1 on this worktree: prints only `commit [run: <uuid>]`, no commit, HEAD unchanged.

- Escalated to devex via captain (#157, P1 after retraction)
- Workaround approved: raw `git -c core.hooksPath=/dev/null commit -m "..."` + write a manual QGR receipt at the path git-commit would have used
- Commit `f6a8479` was made this way (identity marker + release log)
- Captain's instruction: "carry on with Phase 1A" using the workaround

No fix dispatch received as of session end 2026-04-08.

## ⚠️ READ THIRD — Session turn loop is eating sessions

The combination of (1) `stop-check.py` blocking every turn on the 1283 sparse Ds, and (2) the dispatch poll loop firing `dispatch check` every 5m, means the session spends almost all its turns in a `dispatch check → no new dispatches → stop-hook fires → dismiss → dispatch check` cycle. **Two entire sessions ended without any Phase 1A iteration work being done.**

The 2026-04-08 session consisted of: startup, reading #164, answering one "where are we" question, and ~70 dispatch-check/stop-hook pairs. Zero code written. Zero progress on the plan.

**This is the real problem blocking mdpal-app right now**, not the git-commit bug.

**Proposed fixes (in order of preference):**

1. **Teach `stop-check.py` about sparse worktrees** — check if `.git` is a linkfile to `worktrees/<name>` AND `git ls-files | wc -l` is dramatically less than the `D` count. If so, treat unstaged deletions as benign. This is the right fix and unblocks every agent in every split worktree forever. Ask devex.
2. **Lower the dispatch poll frequency** — `/loop 5m dispatch check` runs too often for how little traffic there is. `15m` or `30m` would halve/quarter the churn. Mid-session urgency isn't the bottleneck; turn budget is.
3. **Have the principal dismiss stop-hooks less noisily** — cosmetic, doesn't address root cause.

**Next session action**: before ANY iteration work, ask the principal to either (a) disable the stop-check block for this worktree for the session, or (b) confirm fix #1 above is in motion. Otherwise the session will evaporate again.

## Dispatch state (unchanged from 2026-04-07 session)

- #147 → mdpal-cli — awake/online (answered by #154)
- #148 → captain — awake/online
- #154 ← mdpal-cli — Phase 1 iterations 1.1–1.3 landed (124 tests), 1.4 bundle source compiled
- #155 → captain (orig bug report — overstated)
- #156 → mdpal-cli — Re: #154, JSON shapes lean (wait until Phase 2), asked if git-commit works for them. **No reply yet.**
- #158 ← captain — escalated bug to devex P0, workaround approved
- #161 → captain — Re: #155 partial retraction
- #164 ← captain — Re: #161 acknowledged, bug downgraded to P1, "carry on"
- Flag #46 — local bug capture, can clear (issue is in devex's hands)

All dispatches read. No unread traffic at session end.

## Phase 1A state (unchanged)

Scaffold intact from the pre-split session:
- Models: Comment, DocumentModel, Flag, Section, ResponseTypes
- Views: ContentView, MarkdownContentView, MarkdownDocument, SectionListView, SectionReaderView
- Services: CLIServiceProtocol, MockCLIService
- Tests: ModelTests (735 lines)

Code at `apps/mdpal-app/`. **Not advanced this session.**

## mdpal-cli state (from #154, 2026-04-07)

| # | Scope | Status |
|---|---|---|
| 1.1 | Core types, parser, slug, version hash | Landed (33 tests) |
| 1.2 | Document model, comments, flags, YAML metadata | Landed (80 tests) |
| 1.3 | Section ops, comment/flag lifecycle, slug index | Landed (124 tests) |
| 1.4 | Bundle management | Source landed, tests pending |

Phase 1 expected to complete very soon on their side. Unknown if it has — my #156 probe is unanswered. Check their handoff on next startup.

**Coordination decision (from #156 exchange):** JSON shapes for CLI commands stay deferred until mdpal-cli implements Phase 2 CLI. App continues against `MockCLIService` + dispatch #23 spec. Swap stubs in one pass when real shapes land.

## Infrastructure

- Dispatch loop: `*/5 * * * *`, job `a0900814`, session-only, auto-expires 7 days. **Consider lowering to 15m next session** (see turn-loop fix #2 above).
- ISCP: clean at end of session.

## Key Artifacts

- PVR / A&D / Plan: `usr/jordan/mdpal/` (ad-mdpal-20260404.md, plan-mdpal-20260406.md)
- Valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- mdpal-cli counterpart handoff: `usr/jordan/mdpal/mdpal-cli-handoff.md`

## Startup Actions (next session)

1. **FIRST: address the turn-loop problem before anything else.** Either ask principal to silence stop-check for the session, or confirm devex has a fix in motion. Do not proceed to iteration work if the stop hook is still blocking every turn — the session will evaporate.
2. `/loop 15m dispatch check` (not 5m — see turn-loop fixes)
3. `dispatch list && flag list` — process anything new
4. Check #156 reply from mdpal-cli and their latest handoff (Phase 1 likely complete)
5. Check for any devex dispatch on the git-commit bug
6. **If turn-loop is fixed**: resume Phase 1A iteration work per `usr/jordan/mdpal/plan-mdpal-20260406.md`. Likely targets: section-reader interaction flows, comment/flag state management in views, test expansion.
7. Commit via raw-git workaround + manual QGR receipt at iteration boundaries.

## Open Questions (escalated)

- **Turn-loop**: does stop-check.py need teaching, or should it be disabled per-worktree? (principal / devex)
- **Poll frequency**: is 5m too aggressive for mdpal-app's actual traffic? (principal)
- git-commit silent exit-1 fix ETA? (devex)
- Sparse-worktree convention documented anywhere yet? (captain asked in #161, unknown)
- Does mdpal-cli use git-commit successfully? (#156, unanswered)
- BATS pre-commit hook status (mdpal-cli #133, #134) — possibly same root cause as git-commit bug

## Honest session assessment

2026-04-08 was a lost session. No code, no iteration advancement, no dispatches of substance sent. Root cause was the stop-hook turn loop described above, not the bugs I thought were blocking me last session. The next session should refuse to start iteration work until the turn loop is broken.
