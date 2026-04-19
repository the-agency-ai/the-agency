---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-19
trigger: session-compact
---

# Captain handoff — mid-1B1 on v46.0 Structural Reset

**⚠ NOTE:** handoff tool resolved agent from branch name (`contrib/claude-tools-worktree-sync`) instead of captain — identity-conflation bug #273/#274/#326. THIS IS CAPTAIN'S handoff.

## Where we are

**Branch:** `contrib/claude-tools-worktree-sync`
**Last commit:** `2d0d6cf7` (Valueflow artifacts committed)
**Working tree:** clean (pending handoff commit)

Mid-1B1 walkthrough of **Plan v1 MAR blockers** for v46.0 structural reset. Principal directed a compact to reset context. Pick up where we stopped.

## Session arc so far (long session)

1. **Session-resume** — cleared commit-precheck (fixture missing helper), landed refactor PR #294 with full QG
2. **andrew-demo audit** — 31 defects catalogued, 6 NEW issues filed (#324-#329)
3. **/fleet-report skill v2** — first v2 skill authored in the-agency
4. **monofolk v2 skill methodology review** — research agent read PRs #308-313
5. **agency-* cleanup** — 1B1 6-item cleanup: removed dead /agency-bug, /agency-nit, nit-add, nit-resolve; rewrote /agency-help with Tier 2 doc pointers; stubbed /agency.md
6. **andrew-demo briefing** — written for Andrew at `claude/workstreams/andrew-demo/research/briefing-agency-init-audit-flashcards-hsk3-20260419.md` + pointer notice in his captain sandbox (andrew-demo has its own git; committed locally there, not pushed)
7. **5 concrete issues filed** (#332-#336) + root-cause fixes in `_agency-init` for #334 + #335
8. **Installer seed + 2 Anthropic seeds** committed to `claude/workstreams/the-agency/seeds/`
9. **#337 filed** — "Build a true installer" with manifest-driven design + continuous self-install
10. **v46.0 Structural Reset Valueflow pass** — PVR → MAR, A&D → MAR, Plan → MAR (all autonomous per principal)
11. **1B1 walkthrough of 9 Plan blockers** — currently mid-walk, principal called compact

## Plan v1 1B1 — RESOLVED blockers (Over-and-out confirmed)

- **#1** Phase 0 budget — **full scope accepted**: single session, multi-phase with checkpoints, build tooling if required
- **#2** Placeholders in commands — **"Write the tools you need. That is Phase 1."** — Phase 1 = tooling build; Plan v2 has complete tool source + inline commit bodies
- **#3** Post-rename tool path breaks — **transitional symlink** `ln -s agency/tools claude/tools` immediately after rename; explicit cleanup step at Phase end (principal's idea — credit noted)
- **#4** Subagent regex over-aggressive — **fully qualified path substitutions** + explicit allowlist (`.claude/`, `CLAUDE.md`, `anthropic/claude-code`, `$CLAUDE_PROJECT_DIR`, `Claude Code` etc.); **`agency-sweep` preview-first tool** built in Phase 1 (shows matches in context before applying — principal loved this)

## Plan v1 1B1 — OPEN blockers (where we stopped)

### #5 — Manifest gaps (IN PROGRESS, partial resolution)

Principal refined the scope: **"It only matters if they are things we will install, right?"**

Filter accepted — in-scope is things that get installed/executed/imported/discovered:
- `.claude/**`, `agency/tools/**`, `agency/hooks/**`, `agency/hookify/**`, `agency/templates/**`, `agency/starter-packs/**`, `agency/schemas/**`, `agency/config/**`, `agency/agents/**`, `agency/REFERENCE/**`, `agency/README/**`, `agency/CLAUDE-THEAGENCY.md`, repo-root `CLAUDE.md`, `.gitignore`, `.gitattributes`, `package.json`, `tests/**`

Out-of-scope (historical):
- `usr/**`, `workstreams/*/history/**`, `workstreams/*/transcripts/**`, `workstreams/*/qgr/**`, `workstreams/*/rgr/**`, `CHANGELOG-*`, `history/flotsam/**`

### Then principal raised 3 sub-questions:

1. **`agency/agents/` contents** — "We have a few other agent class definitions (and will likely have more) - captain - workstream-lead (my renaming of what was tech-lead). Others?"
   - I started listing. Current `claude/agents/` contents (pre-cleanup):
     `apple, captain, cos, designex, discord, gumroad, iscp, marketing-lead, platform-specialist, project-manager, researcher, reviewer-{code,design,scorer,security,test}, tech-lead, templates, testname`
   - Need to triage what's KEPT as a canonical class vs DELETED as specific-named non-classes. Principal already flagged (#275) that apple/discord/gumroad/testname ship but shouldn't.
   - **Not yet presented to principal for Over-and-out.**

2. **starter-packs + schemas — "don't believe still in things"**
   - They ARE still in tree. Principal's note: "The starter packs as they exist are now source code inputs in src/spec-provider/starter-packs. Aren't they?" — i.e., in the #337 installer model, starter-packs live under src/spec-provider/. For THIS reset, they stay at `agency/starter-packs/` and #337 relocates them later.
   - Principal asked: "What is the role of schemas?"
   - I was about to report: schemas = `finding.schema.json` + `consolidated-findings.schema.json` — JSON schemas used by reviewer-scorer agent for MAR finding output validation. Framework-internal. Not shipped to adopters.
   - **Not yet presented to principal.**

3. **hooks/ + hookify/ in .claude/** — principal: "Keep as is. Is nicer, if it will work long term. I like it. Wish we could do it with commands and skills ;)"
   - RESOLVED: hooks/hookify stay in `agency/` post-rename. Commands/skills stay in `.claude/` (Claude Code requirement; would need Anthropic-side change to flip).

### #6-#9 — NOT YET WALKED
- #6 Subagent receipts self-reported
- #7 Line-count heuristic misses semantic corruption
- #8 Dotfile glob gap (`git mv agency/workstreams/agency/*` misses `.gitkeep`)
- #9 `--migrate` not enforceable; monofolk can skip

## Resume strategy

1. On session-resume, read this handoff
2. Start 1B1 at **Blocker #5, sub-question 2 (starter-packs + schemas role)**
3. Answer: schemas role (JSON schema validation for reviewer-scorer), starter-packs stay at agency/ now + src/spec-provider/ in #337
4. THEN present agent class list triage (sub-question 1)
5. Close #5 with Over-and-out
6. Walk #6, #7, #8, #9 in order
7. Once all 9 blockers closed, update Plan v2 and execute v46.0 reset

## Current branch + merge order

- Branch: `contrib/claude-tools-worktree-sync`
- PR #294 open with: refactor package + andrew-demo research + fleet-report v2 + agency-* cleanup + root-cause fixes + v46.0 Valueflow artifacts (PVR, A&D, Plan, MAR triages) + seeds
- After PR #294 merges, cut new branch `v46.0-structural-reset` from master for execution
- Do NOT execute the reset on this branch — new branch for clean PR

## Flag queue (10 unread)

- #176-#186 — various follow-ups, all captured, none blocking

## Unanswered principal questions (from long session)

- Q4-Q8 on monofolk v2 methodology 1B1 (naming renames, PRs #303/304 mislabel, PRs #311/312/313 accept, pr-submit/pr-captain-land deferral, skills-cli adoption)
- Never returned to these after the conversation pivoted to the structural reset

## Critical discipline reminders (principal caught me violating)

- **Over protocol MUST be followed** — wait for principal's explicit Over-and-out before moving to next 1B1 item
- **Do not interpret partial responses as approvals**
- **Be decisive when asked** — state one answer, not a menu of options
- **Tighten turns** — minimal context, explicit question, Over

## Files to re-read on resume

Before answering Blocker #5 follow-up:
- `claude/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md` (the Plan itself)
- `claude/workstreams/the-agency/research/mar-pvr-structural-reset-20260419.md` (MAR findings context)
- `claude/workstreams/the-agency/research/mar-ad-structural-reset-20260419.md` (MAR findings context)

## Environment state

- Dispatch monitor: running (session-length)
- 10 unread flags
- agency-health at last check: not critical
- Working directory: clean after this handoff commits

## Next-action-directive (single line)

**Resume with Blocker #5 walk: schemas role + agent class triage → Over-and-out → proceed to #6.**

— captain, 2026-04-19
