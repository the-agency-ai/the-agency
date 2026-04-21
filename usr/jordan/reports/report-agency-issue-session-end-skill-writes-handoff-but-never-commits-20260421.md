---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-21
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/393
github_issue_number: 393
status: open
---

# session-end skill writes handoff but never commits it — leaves tree dirty, blocks next session-resume

**Filed:** 2026-04-21T05:16:54Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#393](https://github.com/the-agency-ai/the-agency/issues/393)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

## What happened

Session-end skill description says "Leaves a clean working tree" but the actual flow leaves the newly-written handoff uncommitted.

### Reproduction

1. Run `/session-end` at end of any session.
2. Check `git status` after the skill completes: the rewritten `captain-handoff.md` + new `history/handoff-*.md` archive are uncommitted.
3. Start next session.
4. `/session-resume` → `session-pickup --from fresh` → `session-preflight` fails with "Working tree dirty (2 files)" → `status=blocked`.

### Root cause

`.claude/skills/session-end/SKILL.md` flow:

- **Step 1:** shells to `session-pause` (commits any existing coord dirt; handoff not yet written).
- **Step 2:** "Write the handoff file at `handoff_path`" — creates new dirty state.
- **Step 3:** `handoff read` + report "Safe to `/compact` and/or `/exit`."

**No step commits the handoff written in Step 2.** Skill description claims clean tree; implementation does not deliver it.

Last session's session-pause output: `commit_sha=none, handoff_commit_sha=none, status=ok`. Tree was clean entering pause (nothing to checkpoint), and the abort-path force-commit didn't fire (not an abort). Post-pause handoff write left the tree dirty.

### Evidence

- Observed 2026-04-21 captain session resume after 2026-04-21 session-end.
- `session-preflight` correctly flagged the dirt — the preflight is NOT the bug; the upstream skill is.
- Fix required manual `/coord-commit` before `/session-resume` could complete.

### Fix options

1. **Session-end Step 2.5:** after writing the handoff, commit it as a coord artifact via `/coord-commit` (or direct `./agency/tools/git-safe-commit --no-work-item`). Fast, low-risk.
2. **Session-pause handles it:** accept handoff content via flag/stdin, write-and-commit atomically inside the primitive so the skill doesn't have a dirty-tree window. Cleaner; requires primitive API change.

Recommendation: Option 1 short-term (unblock users), Option 2 medium-term (atomic primitive).

### Acceptance criteria

- [ ] After `/session-end` completes, `git status` reports clean tree.
- [ ] Next session's `/session-resume` succeeds without manual intervention.
- [ ] Skill description "Leaves a clean working tree" is truthful.
- [ ] Tests in `src/tests/skills/session-end.bats` (or equivalent) verify clean-tree post-condition.

### Related

- Principal-raised during 2026-04-21 AM session — "I am seeing errors on session-resume, you should review them and root-cause them!"
- Paired skill `/compact-prepare` may have the same pattern — verify before closing.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-21:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/393
