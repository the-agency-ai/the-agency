---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-20
trigger: session-end
mode: v46.1-shipped-cleanup-merged-andrew-demo-PR-open
---

# Captain handoff — v46.1 cleanup MERGED; andrew-demo PR #1 open; residuals surfacing

## NEXT SESSION PRIORITY (decisions pending from principal)

1. **andrew-demo PR #1 merge decision** (https://github.com/the-agency-ai/andrew-demo/pull/1)
   - State: OPEN, mergeStateStatus=CLEAN, +11,813/-6,032, manifest=46.1
   - Untouched since subagent opened it. Principal review pending.
2. **Residual sweep-miss bundle PR scope** (see table below)
   - Tight bundle (2 fixes, stashed): collaboration + skill-audit config paths
   - OR comprehensive bundle (adds skill registry gaps + required_reading fixes): larger scope
3. Continue v46.2 planning when principal ready

## Session summary (post-/compact resumption)

**Started:** Resume + session-preflight → proceed to PR #358 merge per prior session's principal directive.

**PR #358 merge path:**
- Smoke test was FAILURE; principal diagnosed as "bad test" (hardcoded `claude/` paths duplicating framework knowledge)
- Principal directive: remove the bad CI workflows, build proper ones later
- Executed: deleted 3 workflows (smoke-ubuntu, fork-pr-full-qg, sister-project-pr-gate), fixed 1-line path in release-tag-check (kept for post-merge invariant enforcement), commit `f7845afd`, pushed, merged PR #358 at `b727408b` via `pr-merge 358 --principal-approved --delete-branch`
- Filed **issue #359** for proper CI test rework (shell out to framework self-verify)

**andrew-demo re-migration (subagent):**
- Delegated to general-purpose subagent against final v46.1+cleanup state
- Subagent: wiped stale claude/, rsync'd fresh agency/ + .claude/ from the-agency main (`b727408b`), restored adopter customizations (workstreams, PRC-flag UI edits, flashcards), rewrote agency.yaml for andrew-demo identity
- **Result:** PR [#1](https://github.com/the-agency-ai/andrew-demo/pull/1) open on andrew-demo, +11,813/-6,032, manifest=46.1, CLEAN mergeable state
- Filed **issue #360** — subagent discovered `agency verify` has stale `claude/*` paths (Phase 7 sweep miss)

**Cross-repo dispatches (principal request):**
- Discovered `collaboration` tool itself was a sweep miss — hardcoded `claude/config/agency.yaml` path made it return "no repos configured"
- Fixed inline (2-line edit); tool came alive → found **1 unread inbound from monofolk/jordan/captain**
- Read + replied to `dispatch-source-vs-installed-path-mapping-for-ses-20260420.md` — monofolk's PR #140 landed (session-lifecycle-refactor v2.0, resolves the-agency #352/#353/#354/#355); 5 path-mapping questions answered with authoritative v46.1-hybrid + v46.2+-build-boundary context
- Pushed reply to collaboration-monofolk origin
- Monofolk captain is ready to submit upstream-port PR once they read the reply

**Cascading sweep-miss discovery:**
Attempted to commit the collaboration fix on branch `fix/collaboration-agency-yaml-path`. Pre-commit hook invoked skill-audit which ALSO had stale `claude/REFERENCE-SKILLS-INDEX.md` path. Fixed skill-audit → it ran → surfaced ~20 unregistered skills + ~2 skills with `claude/REFERENCE-*.md` stale `required_reading` fields. Commit blocked by this cascade. Stashed both fixes to keep tree clean for session-end.

## Residual sweep-miss backlog (cumulative post-v46.1+cleanup)

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `agency/tools/receipt-sign` | hardcoded `claude/workstreams/` write | Documented in v46.1 release notes |
| 2 | `agency/tools/agency verify` | `claude/*` path checks throughout | **Issue #360** filed |
| 3 | `.github/workflows/*` (3 files) | `claude/` hardcoded | **PR #358 removed** + **issue #359** for rework |
| 4 | `agency/tools/collaboration` | `claude/config/agency.yaml` line 45 + help text | **Stashed fix** (stash@{0}) |
| 5 | `src/tools-developer/skill-audit` | `claude/REFERENCE-SKILLS-INDEX.md` line 37 | **Stashed fix** (stash@{0}) |
| 6 | Skills with stale required_reading | `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md`, `claude/REFERENCE-SAFE-TOOLS.md` (in sync skill) | Not started |
| 7 | Skills registry (REFERENCE-SKILLS-INDEX.md) | ~20 skills not registered | Pre-existing gap |

**Stash command to recover #4+#5:** `./agency/tools/git-safe stash pop` (stash@{0})

## Key artifacts

- **v46.1 release:** https://github.com/the-agency-ai/the-agency/releases/tag/v46.1
- **agency-v3 tag:** symbolic installer-threshold marker (same commit as v46.1 merge)
- **v46.1 cleanup merge:** `b727408b` on main
- **andrew-demo PR #1:** https://github.com/the-agency-ai/andrew-demo/pull/1
- **Plan v5:** `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`
- **1B1 transcript:** `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260420.md`
- **Release notes:** `agency/workstreams/the-agency/releases/Release-D46-R1-20260420.md`
- **Workstream class doc:** `agency/workstreams/the-agency/CLAUDE-the-agency.md`

## Issues filed this session

- **#359** — CI: rework tests to shell out to framework self-verify (replaces 3 removed workflows)
- **#360** — agency verify: stale claude/ path references (Phase 7 sweep miss)

## Inbound dispatches handled

- monofolk/captain → dispatch-source-vs-installed-path-mapping-for-ses-20260420.md → **RESOLVED** (replied + pushed)

## Branch + state at session end

- **Current branch:** `main` (clean)
- **Main HEAD:** `b727408b` (v46.1 cleanup merge)
- **Stash:** `stash@{0}` — v46.1-residual sweep-miss fixes for collaboration + skill-audit
- **andrew-demo origin:** `v46.1-migration-20260420` branch (PR #1 open); abandoned `agency-v3-migration-20260420` branch still there (per principal: let adopter decide)
- **Tags:** `v46.1`, `agency-v3`, `v45.2`, `abandoned/v46.0-overnight-shortcut-20260420` on origin
- **Dispatch backlog:** 114 dispatches + 5 flags (deferred)

## Next session starting checklist

1. Read this handoff
2. `git stash list` — confirm stash@{0} still holds residual fixes
3. Decide with principal: tight bundle PR (residuals #4+#5 only) or comprehensive (adds #6+#7)?
4. Decide with principal: merge andrew-demo PR #1?
5. After decisions above, either:
   - Cut residuals bundle branch, pop stash, add fixes #6/#7 per scope, commit (may need to register missing skills or update their required_reading first), push, open PR
   - OR proceed with other priorities (v46.2 planning, Matt multi-principal, dispatch/flag triage)

## Known gaps carried forward

- 6 hookify rules still un-synthesizable for canary (issue #350)
- ~67 files with legitimate `.claude/` references (Phase 7 single-pass known gap)
- Matt multi-principal setup (designed in today's transcript, not executed)
- Dispatch backlog (114) + flag backlog (5) accumulating — triage needed
- Pre-commit hook's skill-audit surfacing cascading sweep misses (symptom of incomplete sweep; fix path is residual bundle + skills registry fill)

— captain, 2026-04-20 session-end #2 (v46.1 cleanup merged; andrew-demo PR open; residuals stashed)
