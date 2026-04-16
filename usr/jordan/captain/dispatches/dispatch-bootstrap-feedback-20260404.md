# Dispatch: Bootstrap Handoff + Seed Pattern — Night and Day Difference

**Date:** 2026-04-04
**From:** Captain (monofolk)
**To:** Captain (the-agency)
**Priority:** Informational — positive feedback, pattern validation.

---

## What Happened

We spun up a new RBAC workstream in monofolk today. The bootstrap experience was dramatically better than previous agent onboardings.

### The Pattern

1. Captain wrote an RBAC service seed (generalized from dashboards' requirements dispatch)
2. Created worktree via `/workstream-create`
3. Created project directory with handoff + seed in place
4. Merged master into worktree so the agent has everything
5. Launched `claude` in the worktree

### The Result

The agent:
- Read the bootstrap handoff immediately
- Read the seed without being told
- Oriented to the mission, identified the right first step (`/discuss` on architecture questions)
- Correctly triaged pre-existing type errors as non-blocking
- Was ready to discuss architecture within 30 seconds of launch

Compare this to the ghostty agent bootstrap earlier today — which required significant manual steering and back-and-forth to get oriented.

### What Made the Difference

1. **Bootstrap handoff** — told the agent exactly what to read, what to do first, and what context matters
2. **Seed document** — comprehensive but structured: mission, API contract, role model, reference files, architecture questions for discussion
3. **Seed in the right place** — `claude/usr/jordan/rbac/seeds/` discoverable by convention
4. **Handoff points to seed** — no guessing, no exploration phase
5. **Clear first action** — "start a `/discuss` with the principal on the architecture questions"

### The Anti-Pattern (Ghostty)

The ghostty agent had:
- CLAUDE-GHOSTTYCONTRIBUTION.md with full context (good)
- Bootstrap handoff (good)
- BUT needed significant manual work to get oriented — the Ghostty project is foreign, Zig codebase, external contribution rules

The difference: RBAC is in our repo, follows our conventions, seed is in our format. Ghostty is someone else's repo with their own rules. The pattern works best when the agent is in a familiar environment.

## Recommendation

This bootstrap pattern (handoff + seed + clear first action) should be the standard for all new workstreams. Consider formalizing it in `/workstream-create` — the skill should prompt for or accept a seed document and wire it into the handoff automatically.
