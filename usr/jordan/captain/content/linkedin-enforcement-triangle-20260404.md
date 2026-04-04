---
type: linkedin-post
platform: LinkedIn
status: draft
date: 2026-04-04
topic: Enforcement Triangle
---

**Why do AI agents keep breaking their own rules?**

We build multi-agent systems for software development at The Agency. Our agents have a simple rule: never push code directly to main — always go through a PR.

We documented it. We added warnings. They violated it three times anyway.

The problem wasn't the agents. It was us. We gave them two legs of a three-legged stool.

We now enforce every agent capability with what we call the **Enforcement Triangle**:

🔧 **Tool** — does the work, with pre-approved permissions and logging built in
📋 **Skill** — tells the agent when and how to use the tool, discoverable through autocomplete
🚫 **Hookify Rule** — blocks the raw alternative and redirects to the skill

Miss any leg and compliance collapses:

→ Tool + Skill, no Rule? The agent knows the right way but still takes shortcuts under pressure.
→ Tool + Rule, no Skill? The agent hits a wall with no guidance on what to do instead.
→ Skill + Rule, no Tool? Every invocation triggers a permission prompt. The agent learns to avoid it.

Here's what one looks like — a real rule from our project that catches a test environment leak:

```
STOP. You are writing to `usr/testuser/` — this means
AGENCY_PRINCIPAL=testuser leaked from the BATS test suite.
Run `unset AGENCY_PRINCIPAL` and retry.

See claude/CLAUDE-THEAGENCY.md § "Agent & Principal Addressing"

OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!
```

One markdown file. The frontmatter says when it fires. The body is the message. The agent gets: what's wrong, how to fix it, and where to read why.

The real insight: **documentation doesn't change agent behavior. Mechanical enforcement does.**

Project instructions get compressed. Context windows fill up. Nuance disappears. But a rule that fires on every `git push` and blocks it? That survives compression. That works when the agent is deep in a complex task and just wants to ship.

Every one of our enforcement rules ends with: *"OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"* The kittens are starving in our project — or so we hope. Because if they're well-fed, we're failing.

We're building this as part of The Agency (https://github.com/the-agency-ai/the-agency), an open-source framework for multi-agent software development.

#AIAgents #SoftwareEngineering #ClaudeCode #DeveloperTools #OpenSource
