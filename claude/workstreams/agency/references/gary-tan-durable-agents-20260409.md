---
type: reference
source: Gary Tan (gstack)
captured: 2026-04-09
captured_by: the-agency/jordan/captain
workstream: agency
purpose: context for articles, book, framework methodology writing
---

# How I Get My Claw To Be A Durable AI Agent I Never Have To Instruct Twice

Source: Gary Tan (@garrytan, gstack). Captured verbatim for reference. This is a philosophical sibling to our **telemetry-driven tool discovery** insight captured in `seed-telemetry-driven-tool-discovery-20260409.md` — both point at the same pattern from different angles.

## The Prompt

> Paste this into your OpenClaw's AGENTS.md or send it as a message:
>
> You are not allowed to do one-off work. If I ask you to do something and it's the kind of thing that will need to happen again, you must:
>
> 1. Do it manually the first time (3-10 items)
> 2. Show me the output and ask if I like it
> 3. If I approve, codify it into a SKILL.md file in workspace/skills/
> 4. If it should run automatically, add it to cron with `openclaw cron add`
>
> Every skill must be MECE — each type of work has exactly one owner skill. No overlap, no gaps. Before creating a new skill, check if an existing one already covers it. If so, extend it instead.
>
> The test: if I have to ask you for something twice, you failed. The first time I ask is discovery. The second time means you should have already turned it into a skill running on a cron.
>
> When building a skill, follow this cycle:
> - Concept: describe the process
> - Prototype: run on 3-10 real items, no skill file yet
> - Evaluate: review output with me, revise
> - Codify: write SKILL.md (or extend existing)
> - Cron: schedule if recurring
> - Monitor: check first runs, iterate
>
> Every conversation where I say "can you do X" should end with X being a skill on a cron — not a memory of "he asked me to do X that one time."
>
> The system compounds. Build it once, it runs forever.

## Why this matters to TheAgency

Tan's framing is adjacent to but not identical to our **Friction → Telemetry → Tool → Block → Flow** loop. The differences are instructive:

| Dimension | Tan's Durable Agents | TheAgency's Telemetry-Driven Discovery |
|-----------|---------------------|----------------------------------------|
| **Signal source** | The principal asking twice | The Bash tool log recording friction |
| **Detection** | Human notices repetition | Telemetry mining finds patterns |
| **Trigger** | "Don't make me ask twice" | "Every compound command is a request for a missing primitive" |
| **Response** | Codify into skill + cron | Build tool + skill + hookify Triangle, block the workaround |
| **Enforcement** | Promise / prompt instruction | Mechanical hookify block |
| **Scale** | One human, one agent | Multi-agent fleet, multi-principal, multi-repo |
| **MECE constraint** | Explicit (no overlap, no gaps) | Implicit (Triangle owns the capability) |

## What we can borrow

1. **"The first time is discovery; the second time is failure."** This is the better one-line framing of our friction-to-tool loop. Steal it for the README.
2. **The skill lifecycle** (Concept → Prototype → Evaluate → Codify → Cron → Monitor) maps cleanly onto our Ladder (Document → Skill → Tool → Warn → Block) but emphasizes the Prototype → Evaluate step, which our Ladder underweights. Consider adding an explicit "Prototype (3-10 real items)" step to the Ladder documentation.
3. **MECE constraint on skills.** We have this intuitively but not written down. Add a framework rule: before creating a new skill, check if an existing one can be extended. This prevents the skill-sprawl problem other frameworks hit.
4. **Cron as first-class.** Tan has `openclaw cron add` as a fundamental primitive. We have `CronCreate` and `schedule` but haven't positioned them as "this is where durable work lives." Elevate cron in the framework story.

## What we do that Tan doesn't mention

1. **Mechanical enforcement via hookify** — Tan relies on agent compliance with the prompt. We block the anti-pattern at the tool level. Agent compliance is an unreliable base.
2. **Telemetry as the signal source** — Tan relies on the principal noticing repetition. We mine the log. The principal can forget; the log cannot.
3. **Triangle structure** (Tool + Skill + Hookify) — Tan has Skill + Cron. We add the Hookify layer and the Tool layer as distinct responsibilities. The separation of "the thing that does the work" (tool) from "the thing that teaches the agent to do the work" (skill) from "the thing that prevents the anti-pattern" (hookify) is a cleaner factoring.
4. **Multi-agent fleet awareness** — Tan's model is single-agent. Ours has to work across a fleet where different agents have different capabilities and permissions.

## Use for writing

Direct quotes are usable with attribution. The comparison table is usable as structure for a section like "Two framings of the same insight."

The article angle: **"The best framework insights are the ones that multiple people arrive at independently. Here are two."**

The book angle: Tan's version is the **sound-bite version** (easy to copy-paste into any project). Ours is the **framework-level version** (requires investment in tool/skill/hookify infrastructure). Both are right for different contexts. The book should present Tan's prompt as the on-ramp for solo developers, and the full Triangle + Telemetry loop as the destination for teams running fleets.

## Related artifacts

- Seed: `claude/workstreams/agency/seeds/seed-telemetry-driven-tool-discovery-20260409.md`
- Flag #55: CLAUDE.md + README revision for telemetry-driven tool discovery (add a section referencing Tan)
- Flag #54: compound command telemetry analysis workstream (the mining side)
