---
type: x-article
platform: x.com (@AgencyGroupAI)
status: draft
date: 2026-04-04
topic: Enforcement Triangle
---

# The Enforcement Triangle: Why AI Agents Keep Breaking Their Own Rules

We build multi-agent systems for software development. Our agents have clear rules — never push directly to main, always go through a PR. We documented it. We added warnings. Our agents violated it three times anyway.

Not because they're dumb. Because we only gave them two legs of a three-legged stool.

## The Pattern

Every AI agent capability needs three components working together:

**The Tool** does the work. It's a script with permissions, logging, and structured output baked in. Pre-approved in the settings so the agent doesn't need to ask permission every time. This is the mechanical layer.

**The Skill** tells the agent when and how to use the tool. It's discoverable — agents find it through autocomplete, through context injection, through the natural flow of work. The skill makes the right path the easy path.

**The Hookify Rule** blocks the raw alternative and points to the skill. It's the wall that says "you can't `git push` directly — use `/push` instead." Mechanical enforcement, not honor system.

We call this the **Enforcement Triangle**.

## What Happens When You're Missing a Leg

**Tool + Skill, no Rule:** The agent knows the right way but can still take the wrong way. Under pressure (context window filling up, complex task, compaction), it takes shortcuts. This is what happened to us — three times.

**Tool + Rule, no Skill:** The agent hits a wall but doesn't know the alternative. It gets stuck, asks the user, wastes cycles. The rule blocks but doesn't guide.

**Skill + Rule, no Tool:** The skill describes the workflow but the underlying tool doesn't exist or isn't pre-approved. Every invocation triggers a permission prompt. The agent learns to avoid it.

## The Real Insight

Documentation doesn't change agent behavior. Mechanical enforcement does.

When we write "never push to main" in our project instructions, agents follow it — until they don't. Context gets compressed. Instructions get summarized. The nuance disappears.

But a hookify rule that fires on every `git push` and blocks it with an actionable redirect? That survives context compression. That works at 3am when the agent is deep in a complex task and just wants to ship.

## How We Build It

For every new capability in our framework:

1. **Build the tool** — bash or Python, with logging and telemetry
2. **Wrap it in a skill** — markdown definition with allowed-tools, context injection, discovery
3. **Block the raw alternative** — hookify rule that intercepts and redirects

All three. Not one, not two. If you ship a tool without the other two legs, you're relying on the agent's good judgment under pressure. And agents under pressure behave exactly like engineers under pressure — they take shortcuts.

## The Kittens Clause

Every one of our enforcement rules ends with the same line: *"OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"*

It's a joke. It's also a signal. When an agent sees that line, it knows this isn't a suggestion — it's a mechanical boundary. The kittens are well-fed in our project. That's how we know the rules are working.

---

*We're building this as part of [The Agency](https://github.com/the-agency-ai/the-agency), an open-source framework for multi-agent software development.*
