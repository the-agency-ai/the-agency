# Dispatch: Agency 2.0 Bootstrap

**Date:** 2026-03-30
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** High — this is the roadmap

---

## Context

This PR (`fix/claudemd-v2-and-fixes`) delivers the Agency 2.0 CLAUDE.md — the project-level instructions that every agent reads. It was developed through a multi-session 1B1 design review covering project structure, file organization, tool audit, agent class model, artifact lifecycle, and skills model.

**Three companion dispatches are included in this PR. Act on them.**

1. `dispatch-iscp-design-20260330.md` — Design intra-session communication protocol
2. `dispatch-browser-protocol-20260330.md` — Design agent browsing protocol
3. `dispatch-plugin-framework-20260330.md` — Build pluggable provider framework (ASAP)

**Read all three dispatches and begin work. Start with the plugin framework.**

## What This PR Delivers

### CLAUDE.md v2
- Three hierarchies: framework (`claude/`), agent instances (`usr/{principal}/`), tooling
- Agent class (`claude/agents/{class}/`) vs instance (`usr/{principal}/{agent}/`) model
- Workstream shared artifacts (KNOWLEDGE.md, seeds, PVR, A&D, Plan, Ref, reviews)
- Full tool audit with current state + planned migration to `claude/tools/` with noun-verb naming
- Plugin provider pattern formalized (secrets, terminal, platform, design)
- Skills model: `/discuss` (protocol), `/define` (PVR checklist), `/design` (A&D checklist)
- Handoff as first-class primitive (context bootstrap, not just session continuity)
- QGRs separate from Plan (summary + pointer in Plan, receipt in reviews/)

### Fixes
- ISS-007, ISS-012 resolved
- Hookify rules: no-push-main (covers main+master), warn-compound-bash, block-commit-main, warn-enter-worktree
- iTerm support removed (Ghostty-only)
- Test paths updated (v1→v2)
- Worktree tools standardized to `.claude/worktrees/`

### Analysis
- `gstack-analysis-20260330.md` — full analysis of gstack with adoption recommendations

## What Needs to Happen Next

### Immediate (this week)
1. **Kill 7 dead agents:** foundation-alpha, foundation-beta, collaboration, unknown, hub, mission-control, research (instance)
2. **Build 4 agent class definitions:**
   - `tech-lead` — product work (most instances depend on this)
   - `marketing-lead` — GTM strategy
   - `platform-specialist` — platform operations
   - `researcher` — deep research (default subagent)
3. **Re-point live agents to class definitions**
4. **Act on dispatch-plugin-framework** — build provider resolution, refactor existing tools

### Near-term
5. **Act on dispatch-iscp-design** — intra-session communication
6. **Act on dispatch-browser-protocol** — agent browsing escalation
7. **Build `/define` and `/design` skills** with completeness checklists
8. **Build promotion tooling** — move artifacts from agent instance to workstream at implementation launch
9. **Tool migration** — move tools from `tools/` to `claude/tools/`, adopt noun-verb naming
10. **Services audit** — identify which agency-service components are still needed, kill dead ones

### Adopted from gstack (see analysis)
11. **Template system** — `{{PLACEHOLDER}}` + build step for shared blocks across skills
12. **Learnings JSONL** — per-project typed memory with confidence scoring
13. **Confidence scoring** — on all review findings
14. **Decision classification** — Mechanical/Taste/User Challenge for review findings

## Reminders

- **Read and act on the three dispatches in this PR.**
- All changes go through PR branches — never commit to main.
- The CLAUDE.md describes current state with migration notes. As tools move/rename, update CLAUDE.md.
- `claude/principals/` is legacy v1. All new work in `usr/{principal}/`.

**Read and act on the three dispatches.**
