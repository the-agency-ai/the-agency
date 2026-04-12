---
type: seed
workstream: agency
date: 2026-04-12
captured_by: the-agency/jordan/captain
principal: jordan
status: approved-proceed
priority: high — needed before Monday workshop
executor: devex (captain supervises)
---

# Seed: CLAUDE-THEAGENCY.md → Bootloader Refactoring

## What this is

Refactor `claude/CLAUDE-THEAGENCY.md` from a monolithic ~4000-word constitution (eager-loaded into every agent's context on every session) into a ~200-300 word **bootloader** that orients a fresh agent and points to skills, hookify rules, and ref-injector-provided reference docs for everything else.

## Why

- **Token cost:** every agent pays for the full CLAUDE-THEAGENCY.md even when they need 20% of it
- **Signal-to-noise:** important rules get buried in a wall of text
- **The mechanisms to replace it already exist:** hookify blocks violations, skills are discoverable via `/`, ref-injector provides context on demand
- **The Enforcement Ladder predicts this:** if a rule is at step 5 (hookify block), it doesn't need to also be at step 1 (CLAUDE.md prose)
- **Scaling:** every new capability currently adds prose to the monolith; the bootloader model adds pointers instead

## The bootloader model

CLAUDE-THEAGENCY.md becomes:

1. **What this repo is** (1 paragraph — framework dev repo, open core MIT + RSL for apps)
2. **Where things live** (5 lines — `claude/`, `apps/`, `usr/`, `.claude/skills/`)
3. **How you discover what to do** — skills via `/` autocomplete, hookify blocks you with guidance if you try something wrong, ref-injector provides docs on demand, handoff tool for session context
4. **Key skills to know** — `/git-commit`, `/quality-gate`, `/discuss`, `/handoff`, `/dispatch` (list of 8-10 pointers)
5. **Done.** Everything else is externalized.

## Extraction map — what moves where

| CLAUDE.md section | Current ~words | Destination | Mechanism |
|---|---|---|---|
| QG Protocol | ~400 | `/quality-gate` skill + `claude/docs/QUALITY-GATE.md` | ref-injector (already wired) |
| MAR / MARFI / MAP | ~300 | **New:** `/mar` skill + reference doc | ref-injector (new mapping) |
| Three-bucket disposition | ~200 | Fold into `/mar` skill | ref-injector |
| Valueflow methodology | ~500 | **New:** `/valueflow` ref doc or skill | ref-injector on `/define`, `/design`, `/plan` |
| Discussion protocol (1B1) | ~200 | `/discuss` skill (already has detail) | ref-injector (already wired) |
| Code review & PR lifecycle | ~400 | `/code-review` skill + `claude/docs/CODE-REVIEW-LIFECYCLE.md` | ref-injector (already wired) |
| ISCP details | ~500 | Reference doc (already exists at `claude/workstreams/iscp/iscp-reference-20260405.md`) | ref-injector on dispatch/flag skills |
| Session handoff | ~300 | `/handoff` skill + tool | ref-injector |
| Feedback format | ~200 | `/feedback-draft` skill + `claude/docs/FEEDBACK-FORMAT.md` | ref-injector |
| Git & remote discipline | ~400 | `/git-commit` skill + hookify rules (most already enforced) | hookify blocks violations; skill provides format on demand |
| Worktrees & master | ~400 | `/worktree-create`, `/worktree-sync` skills | ref-injector on worktree skills |
| Enforcement Triangle/Ladder | ~200 | Reference doc or `/enforcement` skill | ref-injector when building new capabilities |
| Bash tool usage rules | ~200 | **Already enforced by `block-raw-tools` hook** | hookify blocks violations — no CLAUDE.md prose needed |
| Commit message format | ~200 | `/git-commit` skill | skill provides format at commit time |
| Provenance headers | ~100 | `/git-commit` skill | checked at commit boundary |
| Repo structure (detailed) | ~300 | Reference doc (injected for agents that need it) | ref-injector or agent class definitions |
| Agent addressing (full model) | ~500 | Reference doc + address-resolution tools | ref-injector for dispatch/identity work |

## What stays in the bootloader

Only things that **can't be skills AND can't be hookify rules**:

- What this repo is (framework dev repo, licensing model)
- Where things live (5-line directory map)
- How to orient (skills, hookify, ref-injector, handoff)
- Key skill pointers (the 8-10 most important)

## Execution plan (hyper warp)

**Executor: DevEx.** **Supervisor: Captain.**

1. **Seed** (this document) — captured ✓
2. **PVR** — 30 minutes. Quick: problem (monolith costs tokens), vision (bootloader), requirements (every extracted section has a skill + ref doc + ref-injector mapping, nothing lost)
3. **A&D** — 1 hour. For each section: verify skill exists, verify ref doc exists, verify ref-injector mapping. Create what's missing. Draft the slimmed bootloader CLAUDE-THEAGENCY.md.
4. **Plan** — 30 minutes. Phases: (1) create missing skills/ref docs, (2) update ref-injector mappings, (3) slim CLAUDE-THEAGENCY.md, (4) MAR the result, (5) fix MAR findings
5. **Implement** — 2-3 hours. Mechanical extraction + skill creation + ref-injector updates + the actual bootloader rewrite
6. **MAR** — 1 hour. Multi-agent review of the slimmed CLAUDE-THEAGENCY.md to verify nothing critical was lost. High-stakes because removing rules from the constitution could break agent behavior.
7. **QG + PR** — standard. Ship as a PR.

**Could use `/ultraplan` for step 2-4** if we want the planning in the cloud while DevEx executes locally. Or just plan locally — this is structured enough that local plan mode works.

**Total estimate: 4-6 hours of focused DevEx work with captain review at each boundary.** "Hyper warp" means: no waiting, no back-and-forth on obvious decisions. Captain triage is autonomous for Disagree + Autonomous buckets; only Collaborative items surface to principal.

## Risk

**The big risk is removing a rule that should have stayed.** The MAR step (step 6) is specifically designed to catch this. Four review agents scan the slimmed bootloader against the original monolith and flag any "this was in the original and is now unreachable" gaps. Fix cycle runs before PR.

**Mitigation:** the monolith is version-controlled. If a rule turns out to be needed in the bootloader after shipping, we add it back. The cost of over-extraction is low because the skills and ref docs still contain the full content — it's just not pre-loaded.

## Relationship to other work

- **Contribution model rollout** — the three-ring contribution model reference (`claude/docs/CONTRIBUTION-MODEL.md`) would be ref-injector-provided, not CLAUDE.md inline
- **CI rework** — independent of the bootloader refactoring, can proceed in parallel
- **mdslidepal** — independent, already farmed out to implementation agents
- **Workshop** — benefits from the bootloader because the workshop repo's CLAUDE.md will follow the same pattern

## Principal's direction

> "I am thinking we have devex run this with you supervising?"
> "And actually, I think we need this for tomorrow?"
> "So you hand off to DevEx along with the other things in flight."

Confirmed. DevEx runs the refactoring. Captain supervises (review at each boundary, MAR triage, PR approval). Needed before Monday workshop. Dispatch to DevEx includes this seed + the contribution model rollout tasks.
