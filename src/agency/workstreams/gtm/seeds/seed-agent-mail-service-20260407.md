---
type: seed
workstream: gtm
date: 2026-04-07
status: parked — business opportunity exploration
source: flag #39 + flag #40
captured-by: the-agency/jordan/captain
---

# Seed: Agent Mail — Email Infrastructure for AI Agents

## The Idea

Email infrastructure designed specifically for AI agents in multi-agent frameworks. Each agent gets its own addressable identity, plus-addressing works naturally across agent+principal combinations, forwarding routes to human principals via configurable rules, and there's an audit trail of which agent sent what.

This came up twice in Day 32 from different angles:
- **Flag #39:** "Agentic email service... captain+jordandm@... with forwarding routes... a noreply-for-agents service that handles attribution, traceability, and replies-to-principal routing."
- **Flag #40:** "Agent Mail Service... takes the format `jordandm+captain.the-agency@users.noreply.github.com` forward as a real email delivery service. Service-owned domain (e.g., `agentmail.dev`)."

## The Gap In The Market

Today, when you want to attribute commits or messages to AI agents in a multi-agent framework, you have three bad options:

1. **Use the principal's real email** — works, but exposes private email and conflates principal/agent identity
2. **Use GitHub noreply with plus-tags** — works for commit attribution (what we just shipped on Day 32) but doesn't deliver messages, no replies route anywhere, only useful inside GitHub
3. **Set up multiple GitHub bot accounts** — works but is heavyweight, requires GitHub App registration per agent, and locks you into GitHub

There's no email service that says "we know about agents." None of the existing services (Gmail, FastMail, Proton, ImprovMX, etc.) treat agents as first-class entities with identity, routing, and replies-to-principal as a native feature.

## The Product

A managed email service where:

- **Each principal gets a mailbox** — `jordan@agentmail.dev`
- **Plus-tags route per agent** — `jordan+captain@agentmail.dev`, `jordan+iscp@agentmail.dev`, `jordan+devex@agentmail.dev` all deliver to Jordan's inbox by default
- **Per-agent forwarding rules** — `jordan+captain.commits@agentmail.dev` could route to a digest, `jordan+iscp.errors@agentmail.dev` could forward to Slack, `jordan+devex.urgent@agentmail.dev` could SMS the principal
- **Reply-to-principal routing** — when someone replies to an agent address, the reply lands in the principal's inbox with the agent context preserved
- **Audit trail** — every message sent from an agent address is logged: which agent, when, to whom, why (link to the dispatch/commit/action that generated it)
- **Identity verification** — addresses are verifiable on platforms like GitHub (so commit attribution works) without needing per-agent GitHub accounts

## Why It's An Opportunity

The market for this didn't exist a year ago because nobody was building multi-agent frameworks. Now there are several:
- TheAgency
- gstack
- metaswarm
- (and the inevitable wave coming)

All of them face the same attribution + delivery problem we just hit on Day 32. Right now they all hack around it. A managed service that solves it cleanly is a small but real market — and the market is going to grow as multi-agent dev becomes mainstream.

## The Connection To Day 32

The plus-tag attribution format we shipped on Day 32 is **exactly the format Agent Mail would understand**. When commits use `jordandm+captain.the-agency.the-agency-ai@users.noreply.github.com`, that's a non-routable string today. With Agent Mail, it becomes a routable address. Same format, same semantics, just upgraded delivery — adopters could migrate by changing one config line in `agency.yaml`.

Our `commit_email` override (planned future config) is the migration path:
```yaml
principals:
  jdm:
    commit_email:
      mode: agent-mail
      mailbox: "jordan@agentmail.dev"
```

When this ships, every commit's agent co-author becomes a real, deliverable, replyable address.

## Initial Users

1. **AIADLC framework adopters** — TheAgency, gstack, metaswarm users
2. **Agent-driven CI/CD pipelines** — bots that need identity and message routing
3. **Multi-agent research teams** — academic and industry research running multiple agents
4. **Personal "second brain" agents** — individual users running personal agent stacks

## Constraints To Solve

- **Domain ownership** — service needs its own domain (e.g., `agentmail.dev`)
- **MX + SPF + DKIM + DMARC** — proper email infrastructure
- **GitHub verifiability** — addresses should work as verified emails on GitHub for profile linking
- **Spam handling** — both inbound (we don't want agent addresses spammed) and outbound (we don't want our service to look like a spam source)
- **Privacy** — principals should control what's logged about their agents
- **Pricing model** — per-principal? per-agent? per-message? freemium?

## Open Design Questions

1. **Mailbox-per-principal or mailbox-per-agent?** Probably principal — agents are tags, not full mailboxes. But agents could be promoted to full mailboxes if needed.
2. **Web UI vs API-only?** Both, eventually. API first.
3. **Hosted vs self-hosted?** Hosted to start. Self-hosted as a second tier for enterprise.
4. **Integration with existing email?** Should `jordan+captain@agentmail.dev` be able to forward to `jdm@devopspm.com`? Yes — that's the whole point.
5. **GitHub integration?** First-class — auto-verify addresses on GitHub, link to profiles, support the noreply pattern as a fallback.

## Related

- Day 32 Per-Agent Commit Attribution implementation: `agency/tools/git-safe-commit` (commit `03d3ed6`)
- Discussion record: `usr/jordan/captain/transcripts/agent-attribution-model-20260407.md`
- README-THEAGENCY.md "Per-Agent Commit Attribution" subsection

## Spin-Up Notes

This is a business opportunity, not a TheAgency feature. When prioritized:
- Validate market: ask other AIADLC framework authors if they'd pay for this
- Validate technical: verify GitHub address verification works as expected
- Validate domain: secure `agentmail.dev` or similar
- Build MVP: principal mailboxes + plus-tag routing, no fancy features

If we don't build it, someone else will. The Day 32 attribution work is evidence the market exists.

## Captured From

- Flag #39 (2026-04-07T06:29:01Z): "BUSINESS OPPORTUNITY: Agentic email service..."
- Flag #40 (2026-04-07T07:27:53Z): "BUSINESS: Agent Mail Service..."
