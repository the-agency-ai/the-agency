---
type: session
date: 2026-04-04 00:15
branch: main
trigger: session-end-manual — session 18 complete, pushed to origin, dispatch to monofolk sent
agent: the-agency/jordan/captain
---

# Captain Handoff

**Agent:** the-agency/jordan/captain
**Principal:** Jordan
**Updated:** 2026-04-04 (session 18)

## Session 18 Summary

Major session. Flag data loss fix, transcript mining (session 17 + mdpal + presence-detect), ISCP workstream creation, addressing standards formalization, scoped CLAUDE.md pattern, provenance headers convention, 4-agent MAR, pushed 20 commits to origin.

### Flag Tool Fix — Data Loss Bug
- Flag queue (JSONL) was not git-added after writes — lost on session boundaries
- Added `git add` after every write in `claude/tools/flag`
- Added SessionStart warning in `claude/hooks/session-handoff.sh` when flags exist
- Fixed principal resolution (was using `$USER` instead of `AGENCY_PRINCIPAL`)
- Recovered 11 lost flags from session 17 via transcript mining

### Transcript Mining
- **Session 17:** Mined 57 items, filtered to 29 pending flags (added to queue)
- **mdpal-cli + mdpal-app:** Worktree/master path confusion is #1 friction (66 master-path vs 13 worktree-path calls in mdpal-app). 7 findings written to `usr/jordan/iscp/seeds/mdpal-bootstrap-mining-20260404.md`
- **presence-detect:** Confirmed agency-init broken in the field (wrong principal mapping, missing tools, missing permissions). Script: `usr/jordan/captain/tools/mine-transcripts.sh`

### ISCP Workstream Created
- **Scope:** flag (SQLite-backed), dispatch lifecycle, ISCP v1 notification hook, dropbox, addressing, cross-repo
- **Files created:**
  - `claude/workstreams/iscp/CLAUDE-ISCP.md` — workstream-scoped instructions
  - `claude/workstreams/iscp/KNOWLEDGE.md` — key decisions
  - `claude/agents/iscp/agent.md` — agent class definition
  - `.claude/agents/iscp.md` — agent registration with `@` imports
  - `usr/jordan/iscp/CLAUDE-ISCP.md` — agent-scoped instructions
  - `usr/jordan/iscp/iscp-handoff.md` — bootstrap handoff with 10 open questions
  - `usr/jordan/iscp/dispatches/dispatch-addressing-scheme-20260404.md` — addressing scheme seed
  - `usr/jordan/iscp/seeds/mdpal-bootstrap-mining-20260404.md` — mining findings seed

### CLAUDE-THEAGENCY.md Updates
1. **Addressing standards** — workstream addressing (`{repo}/{workstream}`), dispatch payload locations table, dropbox concept
2. **Scoped CLAUDE.md pattern** — CLAUDE-{WORKSTREAM}.md + CLAUDE-{AGENT}.md with `@` import, table of 3 layers
3. **Provenance headers** — What Problem / How & Why / Written on all code (replaces "comment the why")
4. Various fixes: IACP→ISCP typo, `{agent-project}`→`{project}`, DB pattern explanation

### Discussion (4 items resolved)
- **Item 1 (Ghostty):** State understood. Three-file AppleScript change. Validates agency-init on external repo.
- **Item 2 (Flag/Dispatch/ISCP):** Flag→agent-addressable+SQLite. Dispatch lifecycle formalized. Code reviews = dispatch type. ISCP v1 = hook. Dropbox for worktree↔master staging.
- **Item 3 (mdpal mining):** 7 findings, #1 is worktree/master path confusion. Seeds delivered to ISCP.
- **Item 4 (Addressing):** Agent = `{repo}/{principal}/{agent}`, Workstream = `{repo}/{workstream}`. Bare forms resolve from context.

### MAR (4-agent review)
- Code, design, test, security agents on 860-line diff
- 12 findings found and fixed (commit ed575df, rebased to origin)

### Monofolk Dispatch
- Written: `usr/jordan/captain/dispatches/dispatch-monofolk-session18-incorporation-20260404.md`
- Directive: incorporate 5 framework changes, discuss issues with monofolk/jordan

## Git State

- **Branch:** `main`
- **HEAD:** `1752178` (pushed to origin)
- **Working tree:** clean (untracked: PDF, history/push-log.md modified)
- **Ahead of origin:** 0 commits

## Flag Queue

~50 items total (5 recovered + 29 mined + ~16 new this session). Run `./claude/tools/flag list` to see full queue. Key new flags:
- Vouch model adoption from Ghostty
- Starter repo retargeting (the-agency-starter followers)
- X/Twitter API monitoring (@AgencyGroupAI)
- Non-destructive tool permissions requirement
- Provenance enforcement tooling (future)

## What's Next (Session 19)

1. **Launch ISCP agent** — `claude --agent iscp`. Bootstrap handoff ready, seeds delivered, 10 open questions for /define
2. **Update presence-detect** — agency-update or manual, dispatch changes
3. **Pull mdpal worktree work** — sync-all, review agent progress, relaunch
4. **Read DevEx dispatch** — 77cb4a5 → 870a84a (all 6 items decided). Full /discuss pending.
5. **Discuss flags** — 50 items to triage, scope next release requirements
6. **PR for monofolk** — dispatch sent but no PR created yet. Create PR for visibility.

## Key Files Modified This Session

| File | Change |
|------|--------|
| `claude/tools/flag` | git-add on write, warning on failure |
| `claude/hooks/session-handoff.sh` | Flag queue detection, principal resolution fix |
| `claude/CLAUDE-THEAGENCY.md` | Addressing, scoped CLAUDE.md, provenance headers |
| `claude/workstreams/iscp/` | NEW workstream (CLAUDE-ISCP.md, KNOWLEDGE.md) |
| `claude/agents/iscp/agent.md` | NEW agent class |
| `.claude/agents/iscp.md` | NEW registration |
| `usr/jordan/iscp/` | NEW sandbox (handoff, CLAUDE-ISCP.md, dispatches/, seeds/) |
| `usr/jordan/captain/tools/mine-transcripts.sh` | NEW mining tool |
| `usr/jordan/captain/transcripts/discussion-transcript-20260404.md` | Items 1-4 resolved |
| `usr/jordan/captain/dispatches/dispatch-monofolk-session18-incorporation-20260404.md` | NEW dispatch |
