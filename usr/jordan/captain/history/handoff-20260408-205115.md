---
type: handoff
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-08
trigger: mid-session-day-33
---

## Identity

the-agency/jordan/captain — Captain. Coordination, dispatch routing, quality gates, PR lifecycle. First up, last down.

## Current State

**Day 33 in progress.** R1 shipped and merged (PR #53). R2 in draft as PR #54 with substantial content. Monofolk's merge-not-rebase contribution (PR #55) merged into main and incorporated into R2 via merge (not rebase) — discipline applied on its first day.

## Day 33 - Release 1 (PR #53) — MERGED

7 commits. Day 32 carry-over + Day 33 core work.

- **agency-issue v1** — thin gh wrapper with file/list/view/comment/close verbs. Designed via 10-question 1B1 with principal. Smoke-tested by filing the-agency-ai/the-agency#52 using the tool itself.
- **release-plan v1** — heuristic-based release plan generator. Auto-detects day{N}-release-{M} branch, groups uncommitted files, pairs tool+skill+tests as feature commits. **Bootstrap pattern: built the tool then used it to assemble R1 and R2.**
- **Dispatch loop convention** — documented in CLAUDE-THEAGENCY.md as canonical for every agent (5m silent + 30m visible nag).
- **iscp-check v1.1.0** — delta suppression, stops the "You have N" repeat on every Stop event.
- **6 seeds** — fleet awareness, agency-issue, release-plan, silent-tool-calls (filed as Anthropic feedback + GH #45017), granola carry-over, agent-mail-service.
- **3 pre-existing bugs caught and fixed** — .git/config bare=true, git-commit PROJECT_ROOT unbound, iscp-check.bats stale version.

## Day 33 - Release 2 (PR #54) — DRAFT

13+ commits on top of R1. Still in flight.

- **iscp-check --statusline mode** + statusline.sh integration — shows 📬 Nd Mf in the footer when current agent has unread mail; silent when empty (per principal directive — icon only appears when there's something to notice)
- **release-plan heuristic for config-block pairing** — agency.yaml section changes now fold into matching feature commits (e.g., agency.yaml `issues:` block changes go with the agency-issue feature commit)
- **BATS tests for agency-issue** — 19 tests covering version/help, arg validation, verb dispatch, required-flag checks. Arg validation moved before gh auth check so bad args surface real errors.
- **BATS tests for release-plan** — 16 tests covering classification, feature pairing, agency.yaml config-block pairing, output options, base ref comparison.
- **Monofolk merge-not-rebase contribution (PR #55) incorporated** — merged into day33-release-2 via `git merge origin/main` (not rebase). All skills now merge-based, hookify rules block raw rebase and reset --hard origin/*.
- **nit-add + nit-resolve migrated to merge-based pull** — the two tools were using `git pull --rebase` with `git rebase --abort` cleanup, blocked by the new hookify rule from #55. Migrated to `git pull --no-rebase`.
- **Monofolk RFI reply sent** — full 1B1 answers on SPEC-PROVIDER + SPEC-ENVIRONMENT, all 5 questions with options considered and reasoning. Delivered via collaboration repo.
- **Worktree naming rule answered to devex** (#169 review-response, #166 unblocked)
- **iscp notified of --statusline extension** (#170 heads-up)
- **Captain's log for Day 33 written** (7 entries: 2 milestones, 2 builds, 1 decision, 3 learnings, 1 friction)

### R2 content pending

- This handoff update (complete once this file lands)
- Push and update PR #54 description
- Principal call on merging R2
- Agency-update test on a real downstream project (1B1 pending on parameters)

## Active Agents (background)

| Agent | State | Notes |
|-------|-------|-------|
| devex | Queue of 4 items from #149 + worktree naming (#166 unblocked today), #167 hookify rename, #168 agent-create scaffolding | Needs to merge master for R1/R2 updates |
| iscp | Working on Phase 2 (per-agent inboxes plan approved). Received #170 heads-up on iscp-check extension. Also received peer-to-peer directive (#165) | Needs to merge master for R1 |
| mdpal-app | Phase 1A SwiftUI work | Needs to merge master |
| mdpal-cli | Own iteration | Needs to merge master |

## Monofolk Cross-Repo

- **Day 33 morning:** Received RFI on SPEC-PROVIDER + SPEC-ENVIRONMENT. 1B1'd with principal. Full reply sent today.
- **Day 33 afternoon:** Received merge-not-rebase contribution (PR #55). Merged into main (ba6deed). Replied acknowledging, noting discipline applied on its first day (merged into R2, not rebased).
- **No pending inbound** from monofolk.

## Open Items

### Pending principal calls

- **Merge R2** — PR #54 still draft, pending principal go-ahead
- **Agency-update test** — principal offered a real-world test of R1+R2+#55 on an existing project. 1B1 pending on: project path, backup tag, branch, dry-run vs real run
- **Anthropic Claude Code backlog** — 4 unfiled issues parked for tomorrow morning

### Carried forward (deferred to Day 34+)

- Git-commit `--staged` default behavior fix (when staging area non-empty)
- Pull-rebase hookify gap investigation (block-raw-rebase pattern may miss `git pull --rebase`)
- PR lifecycle tool build (on hold, seed captured)
- Fleet awareness /define (seed ready, PVR not yet started)
- Hookify noun-verb rename (dispatched to devex as #167, their work)
- Agent-create scaffolding with dispatch loops (dispatched to devex as #168, their work)

## Active Flags

| ID | Flag | Status |
|----|------|--------|
| 34 | SECURITY: Bash(*) too broad pre-GTM | TODO (kept active per principal) |

## Next Action (start of next session or continuation)

1. Push R2 content to update PR #54 description
2. **1B1 with principal on agency-update test parameters** (see Open Items)
3. If principal approves merge of R2: merge PR #54, then post-merge sync
4. Run agency-update test on the selected downstream project
5. Tomorrow morning: triage + file Anthropic Claude Code backlog (4 issues)

## Key Decisions This Session

1. **Dispatch loop convention is universal** — every agent, every session, 5m silent + 30m visible nag
2. **Bootstrap pattern confirmed** — captain can build a tool and use it in the same session to assemble the release containing the tool. Done twice (R1 with release-plan, R2 with release-plan's improvements)
3. **Always-visible mailbox was wrong** — corrected to silent-when-empty per principal directive. The icon only appears when the current agent has unread mail.
4. **Merge-not-rebase discipline adopted same-day** — monofolk's PR #55 shipped the framework-wide rule, we applied it to R2 within minutes via `git merge origin/main`.
5. **SPEC-PROVIDER orthogonality confirmed** — environment and provider are fully independent concepts. Answered all 5 monofolk RFI questions.
6. **Worktree naming = prefix collapse** — `devex/devex` → `devex`, `mdpal/mdpal-app` → `mdpal-app`, `agency/captain` → `agency-captain`. Devex unblocked to plan #166.

## Discipline Reminders

- **Never rebase** — framework-wide block active (block-raw-rebase hookify rule)
- **Never reset --hard origin/*** — framework-wide block active (block-reset-to-origin hookify rule)
- Use `/handoff` skill, never raw handoff tool
- Use `/git-commit` (with `--staged` flag when pre-staging) — never bare `git commit`
- Run dispatch loop on session start (5m + 30m)
- Cross-repo dispatches via collaboration repo, not direct
- Per-agent attribution in all commits via the new email format

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
