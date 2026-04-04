---
type: x-article
platform: x.com (@AgencyGroupAI)
status: final
date: 2026-04-04
topic: Enforcement Triangle
---

My current passion is AI Augmented Development. I am seeing how far we can take things with @claudeai Code and am defining an AIADLC (AI Augmented Development Life Cycle).

My day is spent working with a group of Claude Code Agents to both build the framework and tooling to support these workflows (we — me and the Agents — call it The Agency) and applying all of it in my day job.

To be successful, we have clear rules for Principals (the humans, like me) and the Agents working together as an Agency. Clear rules like:

- Never push directly to main
- Always go through a PR
- Or whatever removes friction and makes things safer, more effective, and more efficient (including in terms of context windows and token usage)

We documented them. We added warnings. And ours just ignored them (much like many of the software engineers I have worked with over the years, wonder where the Agents learned that ;))

Not because they're dumb. Because we only gave them two legs of a three-legged stool.

## The Pattern

Every AI agent capability needs three components working together:

**The Tool** — it does the work. It's a script with permissions, logging, and structured output baked in. Pre-approved in the settings so the agent doesn't need to ask permission every time. This is the mechanical layer.

**The Skill** — tells the agent when and how to use the tool. It's discoverable — agents find it through autocomplete, through context injection, through the natural flow of work. The skill makes the right path the easy path.

**The Hookify Rule** — blocks the raw alternative and points to the skill. It's the wall that says:

> You can't `git push` directly — use `/push` instead.

Mechanical enforcement, not honor system.

We call this the **Enforcement Triangle**.

## What Happens When You're Missing a Leg

**Tool + Skill, no Rule:**
The agent knows the right way but can still take the wrong way. Under pressure (context window filling up, complex task, compaction), it takes shortcuts. This is what happened to us — three times.

**Tool + Rule, no Skill:**
The agent hits a wall but doesn't know the alternative. It gets stuck, asks the user, wastes cycles. The rule blocks but doesn't guide.

**Skill + Rule, no Tool:**
The skill describes the workflow but the underlying tool doesn't exist or isn't pre-approved. Every invocation triggers a permission prompt. The agent learns to avoid it.

## The Real Insight

Documentation doesn't change agent behavior. Mechanical enforcement does.

When we write "never push to main" in our project instructions, agents follow it — until they don't. Context gets compressed. Instructions get summarized. The nuance disappears.

But a hookify rule that fires on every `git push` and blocks it with an actionable redirect? That survives context compression. That works at 3am when the Agent (or the Principal) is deep in a complex task and just wants to ship.

## How We Build It

For every new capability in our framework, we:

1. **Build the tool** — bash or Python (or Ruby or Rust or TypeScript or Swift) with logging and telemetry
2. **Wrap it in a skill** — markdown definition with allowed-tools, context injection, discovery
3. **Block the raw alternative** — hookify rule that intercepts and redirects

All three. Not one, not two. If you ship a tool without the other two legs, you're relying on the agent's good judgment under pressure. And agents under pressure behave exactly like engineers under pressure — they take shortcuts.

## What It Looks Like In Practice

Here's an actual hookify rule from our project. Our test suite leaks an environment variable (`AGENCY_PRINCIPAL=testuser`) that causes tools to write files to the wrong directory. Instead of hoping agents notice, we block it mechanically:

```markdown
---
name: block-testuser-paths
enabled: true
event: bash
pattern: usr/testuser
action: block
---

STOP.
You are writing to `usr/testuser/` — this means
`AGENCY_PRINCIPAL=testuser` leaked from the BATS test suite
into your shell environment.
Run `unset AGENCY_PRINCIPAL` and retry.

See `claude/CLAUDE-THEAGENCY.md` § "Agent & Principal Addressing"
— principal resolution uses `agency.yaml`, not raw env vars.

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
```

Direct. Actionable. And short — and token efficient.

## The Kittens Clause

Every one of our — short (read: token efficient) and direct — enforcement rules ends with the same line:

> *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

It's a joke. It's also a signal. When an Agent or Principal (human in this loop) sees that line, it knows this isn't a suggestion — it's a mechanical boundary.

The kittens are starving in our project — or so we hope. Because if they're well-fed, we're failing.

---

*We're building this as part of [The Agency](https://github.com/the-agency-ai/the-agency), an open-source framework for multi-agent and multi-principal software development.*
