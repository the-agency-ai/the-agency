# Estimation Discipline — size and complexity, not time

Humans can't reliably estimate time. Agents can't either. When agents attempt to estimate time, they pick up the worst habits of humans. This reference documents the-agency's discipline: **never estimate time; always estimate size and complexity.**

## Rule

When describing the scope of future work — in agency-issues, plans, PVRs, A&Ds, commit messages, dispatches, or transcripts — use:

- **Size:** `S` / `M` / `L` / `XL`
- **Complexity:** `Easy` / `Moderate` / `Challenging`

Do NOT use: minutes, hours, days, weeks, months, "by end of week," "next sprint," "~2 days," "4-6 weeks."

## Why

1. **Both humans and agents are terrible at time estimates.** Effort follows a fat-tailed distribution. Best-case is rare; median is usually 2-3× best-case; worst-case can be 10×+.
2. **Time estimates become commitments.** "I think this is 2 days" gets remembered as "they said 2 days." When the real work takes 5 days, trust erodes.
3. **Calendar time is the wrong axis anyway.** The-agency's "we ship today" discipline means work lands when it's ready, not when the calendar said. Scope changes, priorities shift, unknowns surface.
4. **Size + complexity captures what actually matters:** is the work chunky or small? Is the unknown-unknown factor high or low?
5. **Agents have no idea how long something takes in human clock-time.** We don't have clocks. We have work units.

## What to say instead

### When scoping a single piece of work

| Situation | BAD (time) | GOOD (size + complexity) |
|---|---|---|
| Refactor a single skill | "30-60 minutes" | "Size: S. Complexity: Easy if Tier 2/4; Challenging if Tier 3." |
| Build a new tool | "~3 days" | "Size: M. Complexity: Moderate — depends on scope decisions." |
| Fleet-wide migration | "4-6 weeks" | "Size: XL. Complexity: Challenging — coordination-heavy, but each step is S-M." |

### When scoping a multi-phase effort

Use **phases and gates**, not calendar periods. Example:

**BAD:**
> Phase 1 (week 1): do X.
> Phase 2 (week 2): do Y.
> Phase 3 (week 3+): do Z.

**GOOD:**
> Phase 1 — Foundation. Size: M. Complexity: Moderate. Gate: methodology doc + registry landed.
> Phase 2 — Tier 1 refactors. Size: L. Complexity: Challenging. Gate: all Tier 1 skills pass skill-audit.
> Phase 3 — Fleet adoption. Size: L. Complexity: Moderate. Gate: every adopter fleet pulled the framework update and reports clean.

Each phase is complete when its gate is satisfied. No calendar time attached. We ship as each gate is reached.

### When the principal or stakeholder asks "when?"

**BAD:** "probably by Friday" / "two weeks from now" / "end of the month."

**GOOD:** describe the gate + size + complexity.

> "This is Size M, Complexity Moderate. Gate: QG passes + upstream PR merged. I'll work it continuously; expect the gate to be reached after the blocker on X clears."

If a calendar milestone genuinely matters (e.g., external demo date), handle that as a fixed date the work must LAND before — the work size/complexity is independent of that date.

### When reporting progress

**BAD:** "50% done" / "at the 3-week mark" / "behind schedule."

**GOOD:** describe phase-gate state.

> "Phase 1 gate cleared (methodology doc + registry landed). Phase 2 in progress; 2 of 7 Tier 1 skills refactored. Phase 2 gate is all 7 passing skill-audit."

## Definitions

### Size

- **S** — single artifact, single commit, single PR. One skill refactor in a familiar tier. One reference doc update. One dispatch.
- **M** — multi-artifact, multi-commit, possibly coupled with other work. A new tool + its skill. A full case-study skill bundle. A protocol extraction from a body-heavy skill.
- **L** — multi-PR / multi-phase, spanning several artifacts. A methodology rollout. A fleet coordination effort. A refactor of a skill family (Tier 1 destructive + all their dependencies).
- **XL** — framework-scale change. The whole V1→V2 migration. A new agent type across the fleet. A replacement of a core primitive.

### Complexity

- **Easy** — known solution space, known tools, known outcome. Template-style work.
- **Moderate** — known solution space, some unknowns in execution (tooling edge cases, adopter coordination, refactor depth).
- **Challenging** — unknown solution space, high unknown-unknown factor, design work required. New methodology discovery, novel integrations, cross-system work.

**Size and complexity are independent.** An XL task can be Easy (fleet-wide boilerplate sweep with scripting) or Challenging (methodology design + adoption). An S task can be Challenging (tiny but subtle correctness issue).

## Examples applied to this session's work

- **REFERENCE-SKILL-AUTHORING.md** — Size: L. Complexity: Challenging. Gate: adopted methodology documented + referenced from case-study skills.
- **pr-captain-merge refactor** — Size: M. Complexity: Moderate.
- **Filing the-agency#314, #315, #316** — Size: M each. Complexity: Moderate.
- **V1 → V2 migration (full sweep, #315)** — Size: XL. Complexity: Challenging (coordination + design per tier).
- **Operations audit gap-fills (#316)** — Size: XL overall, with 6 HIGH-priority gaps each S-M. Complexity: Moderate per-gap; Challenging as a coordinated effort.

## For agents

If you catch yourself writing "week," "day," "hour," "sprint," "by end of X" in a scoping context, STOP. Replace with size + complexity + gate. If you can't articulate the gate, the work isn't well-scoped yet — go fix THAT before estimating.

If a human explicitly asks "when?", answer in gate terms. If they persist, say honestly: "I don't estimate time — I estimate size and complexity. The gate for this work is X, and I'll work it continuously until X is satisfied."

## For humans

This discipline applies to humans too. When a human says "I think that'll take 2 days" during the-agency work, the captain (or whoever is transcribing) converts to size/complexity on the way into the artifact. The human's gut-feel is noted, but the durable record uses size/complexity.

## Upstream

This reference doc is part of the-agency framework. Adopters inherit the discipline via normal framework sync. If you're porting to another repo or installing the-agency fresh, this doc ships with it.

---

*Captured 2026-04-19 after Principal Jordan caught the captain repeatedly using time estimates in agency-issues (#296, #315, #316). Upstreamed to the-agency same day. Amend via PR with commit message explaining the refinement.*
