---
type: session
date: 2026-04-04 17:00
branch: main
trigger: session-pause-compact — 1B1 at 15/29, agents running, compact needed
agent: the-agency/jordan/captain
---

# Captain Handoff

**Agent:** the-agency/jordan/captain
**Principal:** Jordan
**Updated:** 2026-04-04 (session 18 continued)

## Current State

Release scoping 1B1 in progress — 15 of 29 items resolved. Three agents running on worktrees (ISCP, mdpal-cli, mdpal-app).

## Session 18 (continued) Summary

### Phase 1: Earlier (pre-compact)
- Flag data loss fix, transcript mining, ISCP workstream creation
- Addressing standards, scoped CLAUDE.md, provenance headers in CLAUDE-THEAGENCY.md
- 4-agent MAR, 20 commits pushed to origin
- Monofolk dispatch for framework incorporation

### Phase 2: Post-compact
- PR #34 created (content + hookify testuser block + monofolk dispatch)
- X article "Enforcement Triangle" published, LinkedIn post published
- Jordan's voice style guide created at `usr/jordan/captain/content/jordans-voice.md`
- Content queue started: 3 more articles planned (Continual Improvement Loop, Why mdpal, Why M&M)
- Hookify rule `block-testuser-paths` — blocks env leak writes
- ISCP worktree created via `/worktree-create` skill
- All 3 agents launched: ISCP (bootstrapped, has 7-phase plan), mdpal-cli (running), mdpal-app (running)
- Monofolk collaboration-repo dispatch received (private coordination repo created)
- DevEx dispatch read (6 items decided, all accepted)
- Release scoping 1B1: 15/29 items resolved

### Release Scoping Decisions (Items 1-15)

| # | Item | Decision |
|---|------|----------|
| 1 | agency-init | #1 priority. Five bugs. Front door to framework. |
| 2 | agency-update (NEW) | #2 priority. Three audiences: monofolk, starter migrants, new adopters. |
| 3 | agent-create | #3. Five bugs. Two entry points: standalone + workstream-create dependency. |
| 4 | Pre-approved permissions | High priority. Known gaps + systematic discovery via transcript/log mining. |
| 5 | SessionStart hook | Iterate toward mechanical enforcement. Progress over perfection. |
| 6 | /pr skill (was /push) | Captain-only. Branch→QG→PR→push→auto-merge. No human review. Full triangle. |
| 7 | Test isolation | Docker containers for all tests. Full Enforcement Triangle for test execution. Future: test result reporting service. |
| 8 | Handoff multi-agent | Support {agent}-handoff.md per agent. |
| 9 | Transcript mining tool | Formalize to claude/tools/. Downstream: agentic pipeline for friction detection. |
| 10 | Dispatch auto-read | Abstraction layer now (file-rename), ISCP replaces with SQLite later. Dispatch requirement to ISCP. |
| 11 | Hookify rules terse | Standard pattern: one-liner + doc ref + kittens. Audit remaining. |
| 12 | Handoff typed frontmatter | Add type: field (session-restore, agency-bootstrap, agent-bootstrap). |
| 13 | Transcript commit discipline | Dual-write: worktree + master. Tooling handles it. |
| 14 | Kill agency-service | Salt the earth. ISCP + dispatches replace it. |
| 15 | Kill /agency dispatcher | Document patterns/anti-patterns first, then delete. Pass learnings to ISCP. |

### Items 16-29 Pending

16. the-agency-starter sunset
17. Vouch model
18. the-agency-content repo (NEW — private, articles/book/workshops, jordandm + jordan-of)
19. X/Twitter integration
20. Provenance header enforcement
21. MAR in CLAUDE-THEAGENCY.md
22. PROVIDER-SPEC.md
23-26. ISCP owns (dropbox, flag SQLite, dispatch lifecycle, cross-repo)
27-29. Decisions (seeds location, agency-init ordering, Ghostty-only)

## Active Agents

| Agent | Worktree | Status |
|-------|----------|--------|
| iscp | `.claude/worktrees/iscp/` | Running — has 7-phase plan, 22 iterations |
| mdpal-cli | `.claude/worktrees/mdpal/` | Running |
| mdpal-app | `.claude/worktrees/mdpal/` | Running |

## Git State

- **Branch:** main
- **Ahead of origin:** ~15 commits (content, hookify, release scoping, transcript)
- **PR #34:** open, content + hookify + monofolk dispatch
- **Monofolk branch:** `monofolk/collaboration-repo-20260404` — unmerged, private coord repo

## Flag Queue

60 items. Key additions this phase:
- /pr skill (was /push) — Enforcement Triangle
- Test result reporting service
- Git commit permissions for agents
- Thoughts on Principles document
- the-agency-content repo

## What's Next

1. **Resume 1B1** at Item 16 (the-agency-starter sunset) — 14 items remaining
2. **Generate PVR** from resolved items → A&D → Plan
3. **Dispatch to ISCP:** agency dispatcher patterns/anti-patterns + dispatch auto-read requirement
4. **Update presence-detect**
5. **Merge PR #34** and monofolk collaboration branch
6. **Content:** Continual Improvement Loop article, Why mdpal, Why M&M

## Key Files This Phase

| File | Change |
|------|--------|
| `usr/jordan/captain/next-release-items-20260404.md` | NEW — 29 release items |
| `usr/jordan/captain/transcripts/discussion-transcript-next-release-20260404.md` | NEW — 1B1 transcript, 15 items resolved |
| `usr/jordan/captain/content/` | NEW dir — X article, LinkedIn, voice guide, content queue |
| `claude/hookify/hookify.block-testuser-paths.md` | NEW — env leak block |
| `usr/jordan/captain/dispatches/dispatch-monofolk-hookify-testuser-20260404.md` | NEW — adoption directive |
