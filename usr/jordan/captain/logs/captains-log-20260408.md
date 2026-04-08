---
type: captains-log
date: 2026-04-08
agent: jordan/captain
---

# Captain's Log — Wednesday, April 8, 2026


## 20:20:23 — milestone

Day 33 R1 shipped (PR #53) — agency-issue v1, release-plan v1, dispatch loop convention, iscp-check delta suppression, 6 new workstream seeds, 3 pre-existing bugs caught and fixed (bare=true in .git/config, git-commit PROJECT_ROOT unbound, stale iscp-check test version). Bootstrap pattern worked: built release-plan then used it to assemble R1.

## 20:20:28 — build

agency-issue v1: thin wrapper around gh CLI for filing/viewing/commenting/closing GitHub issues against the-agency framework. Designed via 1B1 (10 questions) then built in ~2 hours. 5 verbs working end-to-end. Smoke-tested by filing the-agency-ai/the-agency#52 — the tool's own v1 — using the tool itself. Reports written to usr/{principal}/reports/ with REPORTS-INDEX.md pattern.

## 20:20:36 — build

release-plan v1: analyzes branch state, groups uncommitted files by heuristic, proposes commit ordering with tool/skill feature pairing and agency.yaml config-block pairing. Auto-detects day{N}-release-{M} branch and switches. Used to assemble both R1 and R2. 16 BATS tests.

## 20:20:42 — decision

Dispatch loop convention for every agent: 5m silent + 30m visible nag. Documented in CLAUDE-THEAGENCY.md When You Have Mail section. Propagates to every downstream adopter via framework inheritance. Filed Anthropic Claude Code feedback for silent periodic execution primitive (feedback 8dd67e96, GH anthropics/claude-code#45017) as the real fix — status line is the only silent periodic path that exists today, wired via iscp-check --statusline in R2.

## 20:20:47 — learning

Three pre-existing framework bugs surfaced today during bootstrap work: (1) .git/config bare=true mis-flagged the repo; every git command failed until fixed. (2) claude/tools/git-commit referenced PROJECT_ROOT without defining it — caused 'unbound variable' under set -u in every commit since the per-agent attribution code was added. (3) tests/tools/iscp-check.bats version assertion stale at 1.0.1 (we bumped to 1.1.0). All three were invisible until we started exercising the edges. Lesson: build + test in the same session. Bugs hide at the edges where tools compose.

## 20:20:51 — milestone

Day 33 R2 in flight: agency-issue tests (19), release-plan BATS tests (16), iscp-check --statusline mode + footer integration, agency.yaml config-block pairing heuristic, monofolk RFI reply sent with full 1B1 context, captain's log (this file), nit-add/nit-resolve migrated to merge-based pull per PR #55 discipline. Bootstrap demonstrated: release-plan assembled R2 of itself. PR #54 draft with 12+ commits as of this entry.

## 20:20:57 — friction

Back-and-forth on statusline mailbox behavior: I first shipped silent-when-empty, then principal said 'That is a bug' when iscp had mail but no icon, I misinterpreted as 'always visible' and added 📪, principal corrected 'the icon should only be there if the current agent has unread messages.' Reverted. Lesson: when the principal says 'that is a bug', ask what the expected state is before assuming the inverse. The bug was that iscp HAD mail and the icon didn't appear — because iscp's worktree didn't have R2 code. Not that the icon should always be visible.

## 20:21:07 — learning

Monofolk upstream contribution (PR #55, merge-not-rebase) landed mid-session. Replaced rebase-based sync across the framework with merge-based. Two hookify block rules (block-reset-to-origin, block-raw-rebase), four skill updates, one reference doc. We incorporated via merge (not rebase) into day33-release-2 in accordance with the new discipline — on its first day. Found two existing tools (nit-add, nit-resolve) still using git rebase --abort as cleanup, migrated them to merge-based pull. This is exactly the cross-agency feedback loop we want: you hit a bug, you fix it, you send it upstream with full context, the upstream merges and incorporates.
