---
type: marfi
date: 2026-04-06
project: valueflow
from: the-agency/jordan/captain
agents: 4 research agents (sonnet)
---

# MARFI Brief: Valueflow

Multi-Agent Request for Information — input for the Valueflow PVR.

## Research Questions

1. How do established methodologies (Lean, SAFe, Shape Up, DORA) handle seed-to-delivery flow?
2. What multi-agent coordination patterns exist in AI agent frameworks?
3. How do teams progressively tighten enforcement from voluntary to mandatory?
4. What Claude Code features are we underusing? *(Added by Jordan during MARFI review)*

## Findings

### 1. Comparable Methodologies

**Cross-framework pattern: autonomous execution within bounded scope.**
- Human checkpoints at scope definition, not during execution
- Shape Up is the extreme: betting table decides, then team owns delivery entirely
- SAFe: portfolio kanban gates at epic level, PI Planning mandatory, iteration autonomous
- Lean: WIP limits as implicit gates, pull not push, stop-the-line on defects
- DORA: elite teams minimize mandatory human gates in deploy path — shift left

**Directly applicable:**
- **Shaping before betting** (Shape Up) = our define before plan
- **Circuit breaker** (Shape Up) = abandon if not done by deadline. We lack this.
- **WIP limits** (Lean) = pull work when ready. Relevant to captain loop batching.
- **DORA shift-left** = quality enforcement at earliest possible gate
- **Three-bucket analogs exist** in all four frameworks but none formalize them

### 2. AI Multi-Agent Patterns

**We're ahead of the field in four areas:**
1. Parallel multi-agent review with scoring/confidence — no framework has this
2. Three-bucket disposition (disagree/autonomous/discuss) — unique to TheAgency
3. Autonomy ladders (trust levels that shift by artifact type) — absent everywhere
4. Stage-hash gating (cryptographic proof gate ran on specific artifact) — unique

**Relevant patterns from others:**
- MetaGPT: structured role hierarchy, QA feedback loops (closest to our model)
- LangGraph: interrupt-before/after nodes (closest to progressive autonomy)
- AutoGen: `human_input_mode` per agent (ALWAYS/NEVER/TERMINATE) — too coarse
- No framework has dynamic agent group composition — all are static

### 3. Enforcement Ladder

**The meta-pattern: the tool doesn't change — its position in the pipeline changes.**

1. Document the practice
2. Make violations visible (report, dashboard)
3. Move check to earliest enforcement point (pre-commit > CI > merge gate)
4. Gate on artifact existence, not quality (mechanical, auditable)
5. Reserve human judgment for quality, not compliance

**Each layer addresses the bypass discovered in the previous layer.** Additive.

**Compliance insight (SOX/HIPAA/FDA):** gate on artifact existence. "Did you produce a QGR?" is mechanically checkable. "Is the QGR good?" requires human judgment. Our stage-hash approach is exactly this.

### 4. Claude Code Underused Features

**Highest leverage for valueflow:**

| Feature | What | Impact |
|---------|------|--------|
| `WorktreeCreate` hook | Auto-register agent in ISCP on worktree spawn | Eliminates manual .agency-agent setup |
| `PostCompact` hook | Re-inject handoff after compaction | Prevents context loss — major gap today |
| `--bare -p` mode | Headless SDK for batch operations | Captain loop, QG runs, dispatch processing |
| `effort:` frontmatter | Per-skill cost control | High for QG, low for reads |
| Plugin packaging | Bundle skills+agents+hooks+MCP | Right model for agency init distribution |
| Named subagents + SendMessage | Within-session parallel agents | MAR can use native Claude Code parallelism |
| `FileChanged` hook | Reactive dispatch notification | Replace polling with event-driven |
| `--json-schema` | Structured output validation | Enforce dispatch/QGR schemas at generation |
| `PermissionDenied` hook | Auto-retry safe commands | Reduce permission friction |
| `--fork-session` | Divergent review branches | Multiple MAR reviewers from same checkpoint |

**Architecture insight:** Named subagents for within-session (MAR), ISCP for cross-session (dispatches). Both needed. Not either/or.

## Synthesis: What This Means for the PVR

1. **Valueflow's three-bucket pattern is unique** — formalize it as a first-class primitive, not just a convention
2. **Gate on artifact existence** — stage-hash approach is validated by compliance patterns
3. **Autonomous execution is the norm** — our model should default to autonomous with explicit human checkpoints only at scope-definition boundaries
4. **Circuit breaker needed** — what happens when a phase isn't converging? Shape Up's "kill it" model
5. **Plugin model for distribution** — agency init should ship a plugin, not a directory tree
6. **PostCompact hook is critical** — we lose context on compaction today, this fixes it
7. **MARFI process note** — principal must review research questions before agents spin up (lesson learned this run)
