---
type: research
workstream: the-agency
topic: andrew-demo-root-cause
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
source: sub-agent investigation (general-purpose)
inputs:
  - /Users/jdm/code/andrew-demo/claude/workstreams/captain/transcripts/dialogue-transcript-20260418.md
  - /Users/jdm/code/andrew-demo/usr/andrew/captain/captain-handoff.md
  - /Users/jdm/code/andrew-demo/usr/jdm/captain/captain-handoff.md
  - /Users/jdm/code/andrew-demo/usr/jdm/reports/REPORTS-INDEX.md
  - /Users/jdm/code/andrew-demo full tree
---

# `agency init` + run on `~/code/andrew-demo` — Root Cause Investigation

Delegated sub-agent produced the full analysis; report preserved here as the
canonical artifact for the Great Rename (#270) + install-surface manifest (#287)
discussions.

## Headline

- **Install surface is unmanaged.** Framework's `claude/` copies wholesale —
  developer-internal docs, stale specific agents, monofolk-specific files,
  empty scaffolding all ship to adopters.
- **Identity/addressing model is split.** `$USER` vs principal.name vs
  project.name route to different dirs by different tools. #273/#274 are
  symptoms; root cause is `agency.yaml` mapping shape.
- **Claude Code integration is partial.** `.claude/agents/` entirely missing.
  `.claude/commands/` stub. StatusLine unwired. Skills works.
- **Valueflow discipline itself works well.** 1B1 + MAR + three-bucket +
  Over/Over-and-out all delivered clean on the transcript. The breakage is
  *around* Valueflow, not *within* it.
- **Handoff artifacts leak at the boundary.** QGR receipt, Reference doc,
  transcript-append can all be silently skipped at `--no-work-item` commit path.

## Defects mapped (31 total)

**Already-filed (reproduced confirmed):** #271, #272, #273, #274, #275, #276,
#277, #278 (partial — see D24 refinement), #279, #281, #282, #287, #288, #289,
#290.

**Unclear / not exercised in transcript:** #280, #283-#286, #267, #268.

**NEW (8) — recommended filings:**

1. **NEW-1** `.claude/agents/` missing entirely after `agency init` — no
   subagent classes registered for Claude Code discovery. Files exist at
   `claude/agents/<class>/agent.md` but there's no bridge.
2. **NEW-2** `CLAUDE.md` stays placeholder stub after init — `# myapp` header
   with empty `<!-- comment -->` stubs. Primary context-injection surface is
   unset on day one.
3. **NEW-3** `agency.yaml` `principals: { "<git-user>": { name: "<display>" } }`
   is the structural root cause of #273/#274. Tools split: some read `$USER`,
   some read `.name`. Adopter gets fractured sandbox.
4. **NEW-4** QG at `--no-work-item` commit path silently skips QGR receipt +
   Reference doc. Audit trail missing but commit claims phase-complete.
5. **NEW-5** Plan mode writes stray `~/.claude/plans/<name>.md` outside the
   repo — content escapes source control.
6. **NEW-6** `agency init` auto-scaffolds a project workstream (`myapp/`) with
   full shape while `claude/workstreams/captain/` gets only partial shape —
   inconsistent. Refines #278 (captain is under-scaffolded, not mis-located).
7. **NEW-7** Tests directory ships framework BATS scaffolding to adopters who
   have no test runner for their own code — confusing install surface.
8. **NEW-8** Framework version stale from day one — `agency.yaml` +
   handoffs record `framework.version: 43.4` at install, nothing polls for
   drift, adopter gets no "you're N releases behind" nudge.

## Pattern observations

1. **Install-surface sprawl** — #287's "real installer" gap is the root cause
   of #275/#276/#277/#281/#288/#290 + NEW-1/NEW-2/NEW-7. One manifest fixes
   all.

2. **Identity/addressing split** — `$USER` vs `.name` vs project.name — #270
   Great Rename has to land this.

3. **Claude Code integration partial** — Skills works, commands stub, agents
   missing, statusLine unwired. Needs single "what does Claude Code need?" pass.

4. **First-session preflight friction** — every new adopter hits #271 + #272
   in the first 30 seconds. #271's scope is just python shebang + untracked
   test file.

5. **Valueflow works** — 1B1 + MAR + three-bucket + Over/Over-and-out ran clean
   end-to-end. **Don't break what's working** while fixing what isn't.

6. **Boundary artifacts leaky** — NEW-4 exposes that phase-complete can ship
   without QGR receipt or Reference doc. Silent skip, not hard-fail.

## Recommended priorities (from agent)

1. **P1 — Install-surface manifest** (#287 + NEW-1 + NEW-2). Closes #275/#276/
   #277/#281/#288/#290 simultaneously. Single highest-leverage fix.
2. **P2 — Principal/user addressing resolution** (#270 + NEW-3). Pick one
   resolver. Update all tools.
3. **P3 — Claude Code integration surfaces** (#272 + #290 + NEW-1). Single
   pass + post-init self-test.
4. **P4 — Preflight hygiene** (#271). Relax python shebang, decide test_helper
   committed vs .gitignore.
5. **P5 — Enforce Valueflow closing artifacts** (NEW-4 + NEW-5). Hard-check at
   phase-complete / iteration-complete.

## File evidence — key paths

- `/Users/jdm/code/andrew-demo/.claude/settings.json` — no statusLine, no agents/
- `/Users/jdm/code/andrew-demo/.claude/commands/` — 7 files vs 61 skills
- `/Users/jdm/code/andrew-demo/CLAUDE.md` — placeholder stub (20 lines)
- `/Users/jdm/code/andrew-demo/claude/config/agency.yaml` — principal mapping
  root cause
- `/Users/jdm/code/andrew-demo/claude/agents/captain/SESSION-BACKUP-*.md` — 5
  leaked captain session backups (662 lines)
- `/Users/jdm/code/andrew-demo/claude/agents/{apple,discord,gumroad,testname,
  designex}/` — stale specific agents
- `/Users/jdm/code/andrew-demo/claude/workstreams/{captain,flashcards,
  housekeeping,myapp}/` — 4 workstreams, inconsistent shapes
- `/Users/jdm/code/andrew-demo/usr/{andrew,jdm}/captain/captain-handoff.md` —
  identity split in action
- `/Users/jdm/code/andrew-demo/usr/jdm/reports/` — reports in git-user dir
- `/Users/jdm/code/andrew-demo/claude/workstreams/housekeeping/bugs/BUG-0001.md`
  — local audit of #271
- `/Users/jdm/code/andrew-demo/claude/REFERENCE-{EXTRACTION_PLAN,WORKNOTE-*,
  QUALITY-GATE-MONOFOLK}.md` — framework-internal docs leaked

## Input to related work

- **#270 Great Rename** — this report directly feeds the install-vs-repo
  boundary SPEC. NEW-3 is the identity-resolver decision the Great Rename
  already has to make.
- **#287 Real installer** — NEW-1/NEW-2/NEW-7 are specific symptoms of this
  root cause; filing them explicitly gives concrete test cases for the
  manifest design.
- **Fleet-report skill (queued)** — the pattern observations here should be
  visible in `agency-health` or a new `agency doctor` command for adopters.
