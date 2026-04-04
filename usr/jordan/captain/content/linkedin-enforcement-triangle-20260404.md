---
type: linkedin-post
platform: LinkedIn
status: draft
date: 2026-04-04
topic: Enforcement Triangle
---

My current passion is AI Augmented Development — seeing how far we can take things with Claude Code and defining an AIADLC (AI Augmented Development Life Cycle).

I spend my days working with a group of Claude Code Agents. Together — me and the Agents — we build the framework, the tooling, and the workflows. We call it The Agency.

To make this work, we have clear rules for Principals (the humans) and the Agents working together. Rules like: never push directly to main, always go through a PR, whatever removes friction and makes things safer, more effective, and more efficient.

We documented them. We added warnings. And our Agents just ignored them. (Much like many of the software engineers I've worked with over the years — wonder where the Agents learned that.)

Not because they're dumb. Because we only gave them two legs of a three-legged stool.

We now enforce every capability with what we call the **Enforcement Triangle**:

**The Tool** — does the work, with pre-approved permissions, logging, and telemetry built in.

**The Skill** — tells the agent when and how to use the tool. Discoverable through autocomplete, context injection, the natural flow of work. The right path is the easy path.

**The Hookify Rule** — blocks the raw alternative and redirects to the skill. Mechanical enforcement, not honor system.

Miss any leg and compliance collapses. Agents under pressure behave exactly like engineers under pressure — they take shortcuts.

Here's what a real enforcement rule looks like:

> STOP. You are writing to `usr/testuser/` — this means AGENCY_PRINCIPAL=testuser leaked from the BATS test suite. Run `unset AGENCY_PRINCIPAL` and retry.
>
> See claude/CLAUDE-THEAGENCY.md § "Agent & Principal Addressing"
>
> OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!

Direct. Actionable. Token efficient. The agent gets: what's wrong, how to fix it, and where to read why.

The real insight: **documentation doesn't change agent behavior. Mechanical enforcement does.** Context gets compressed. Instructions get summarized. Nuance disappears. But a rule that fires on every `git push` and blocks it? That survives compression. That works at 3am when the Agent — or the Principal — is deep in a complex task and just wants to ship.

The kittens are starving in our project — or so we hope. Because if they're well-fed, we're failing.

We're building this as part of The Agency — an open-source framework for multi-agent and multi-principal software development: https://github.com/the-agency-ai/the-agency

#AIAgents #AIDevelopment #ClaudeCode #DeveloperTools #OpenSource #AIADLC
