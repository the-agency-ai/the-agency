# THE-AGENCY-BOOK-WORKING-NOTE-0010

**Date:** 2026-01-03 23:58 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** TheAgency AI Product Suite Vision

---

## Discussion

### The Vision

If we play it right, TheAgency AI can become a major player in the AI-assisted development space. Here's the product suite sketch:

### Product Suite

#### 1. the-agency-starter (FREE, Open Source)

**The on-ramp.** Gets developers in the door, proves the value, creates the ecosystem.

- Multi-agent scaffolding
- Basic tooling (news, collaborate, working-notes)
- Documentation and patterns
- Community-driven improvements

#### 2. AgencyCollaborate

**DVCS tuned for Agents and Humans**

- Collaborative messaging (push and pull) - productized NEWS system
- Local or Cloud deployment
- Built-in Issues tracking
- Code Review workflow
- Agent-aware branching and merging

#### 3. Agency CI/CD (C²ID)

**Continuous Integration and Continuous Deployment**

- Unified model across providers (Vercel, GitHub Actions, etc.)
- Ties back to Workbench for visibility
- Agent-aware pipelines
- Green-Red deployment patterns built in
- Service health monitoring

#### 4. Agency Workspace

**Shared workspace for agents and humans**

- May be an extension of AgencyCollaborate
- Real-time collaboration features
- Shared context management
- Cross-agent knowledge base

#### 5. Agency Workbench

**What any tech business needs to manage things**

- Agent configuration and monitoring
- Content management
- Catalog management
- Analytics dashboard
- The "command center" for everything

#### 6. MockAndMark

**Visual context creator for AI-assisted development**

- Screenshot annotation for Claude Code
- Direct integration with Agency Workspace
- Save to the right workstream/agent with context
- "Here's what to do with this" workflow
- **Price: $19.95** (all platforms - iOS, iPadOS, macOS)
- Pricing model TBD: one-time vs subscription (see Pricing Research below)

### Deployment Model

| Option          | Target                         | Pricing Model     |
| --------------- | ------------------------------ | ----------------- |
| **Hosted**      | Teams who want zero ops        | SaaS subscription |
| **Self-Hosted** | Enterprise, security-conscious | License + support |

### Go-to-Market Strategy

```
the-agency-starter (FREE)
    │
    │ "This is great, but I need..."
    ▼
┌─────────────────────────────────────────┐
│         Paid Add-Ons                    │
├─────────────────────────────────────────┤
│ • AgencyCollaborate (team messaging)    │
│ • Agency CI/CD (unified pipelines)      │
│ • Agency Workspace (shared context)     │
│ • MockAndMark (visual context)          │
│ • AI Services (How, Troubleshooting)    │
└─────────────────────────────────────────┘
    │
    │ "I want everything in one place"
    ▼
┌─────────────────────────────────────────┐
│         Agency Workbench                │
│    (Flagship - bundles everything)      │
└─────────────────────────────────────────┘
```

---

## Agent's Thoughts

### What's Strong

1. **Clear differentiation** - "for Agents AND Humans" is a unique angle nobody else owns
2. **Validated patterns** - NEWS, COLLABORATE, working-notes already work. We're productizing proven tools
3. **Smart deployment model** - Hosted + Self-hosted captures both markets
4. **Coherent ecosystem** - Everything ties back to Workbench
5. **MockAndMark integration** - Brilliant to have visual context flow directly into the right agent

### Questions to Consider (RESOLVED)

1. **AgencyCollaborate scope** - DVCS + messaging + issues + code review is GitHub + Slack + Linear combined. Is that intentionally ambitious, or should we narrow focus?

   **RESOLVED:** Framework approach like Workbench. Create the framework, plug in applications. Start with messaging for Agents and Humans - the whole coordination infrastructure. Think semaphores, counters, indexes.

2. **DVCS vs Git layer** - Do we build a new DVCS, or layer agent-aware features on top of git? Git is deeply entrenched. A layer might be easier adoption.

   **RESOLVED:** Build ON git, not replace it. "Git for agents" layer. We'd be crazy to try and replace git.

3. **Agency Workspace vs AgencyCollaborate** - These feel overlapping. Maybe Workspace IS the real-time layer of Collaborate?

   **RESOLVED:** Yes, Workspace is the real-time layer of Collaborate.

4. **Nitro for everything?** - Earlier we discussed Nitro for APIs. Does that scale to CI/CD and Workspace needs?

   (Still open - evaluate as we build)

### What Makes This Different

The key insight: **existing tools weren't designed for AI agents.**

- GitHub: designed for humans, agents bolt on awkwardly
- Slack: human-centric, agents feel like integrations
- CI/CD: pipelines assume human decision points

TheAgency AI products treat agents as first-class citizens. That's the moat.

### Risk Factors

1. **Execution risk** - This is a full product suite. Sequencing matters.
2. **Competition** - Big players (GitHub Copilot Workspace, etc.) are circling
3. **Market timing** - Are teams ready to adopt agent-first tooling?

### Revised Sequencing (Post-Discussion)

**Step 0: Mid-January 2026**

- **Launch the-agency-starter** at Claude Code Singapore Meetup
- Jordan gets 5-10 minutes to present
- This is the announcement moment

**Step 1: Immediately After Launch**

- **Workbench Commercial** - it's already built, just needs packaging
- **MockAndMark** - if we can align (visual context → direct Agency integration)
- Quick wins that showcase the ecosystem

**Step 2: Service-ify the Tools**

- Identify tools that benefit from service backing:
  - NEWS → AgencyCollaborate messaging service
  - Semaphores, counters, indexes for coordination
  - Session backup/restore → cloud persistence
- AI Services (How, Troubleshooting)

**Step 3: AgencyCollaborate Full**

- Full messaging + coordination infrastructure
- Issues, code review
- Git layer (not replacement!)

**Step 4: CI/CD, Workspace**

- Agency CI/CD unified model
- Workspace real-time collaboration

---

## Pricing Research: Figma as Reference

### Figma Pricing (2025-2026)

| Plan         | Monthly     | Annual (per month) |
| ------------ | ----------- | ------------------ |
| Free         | $0          | $0                 |
| Professional | $15/editor  | $12/editor         |
| Organization | Annual only | $45/seat           |
| Enterprise   | Annual only | $90/seat           |

**Key observations:**

- Monthly billing only available on lowest paid tier
- Annual gets ~20% discount
- Big jumps between tiers (244% from Pro → Org)
- Free tier hooks people in
- Annual billing saves money (and locks customers in)
- Figma bundles multiple products (Design, Dev Mode, FigJam, Slides) into full seats

**Sources:**

- https://www.figma.com/pricing/
- https://help.figma.com/hc/en-us/articles/27468498501527-Updates-to-Figma-s-pricing-seats-and-billing-experience
- https://userjot.com/blog/figma-pricing-2025-plans-seats-costs-explained

### MockAndMark Pricing Options

At $19.95 price point, several models possible:

| Model             | Monthly  | Annual    | Notes                      |
| ----------------- | -------- | --------- | -------------------------- |
| One-time purchase | -        | $19.95    | App Store friendly, simple |
| Subscription A    | $4.99/mo | $39.99/yr | Higher lifetime value      |
| Subscription B    | $2.99/mo | $24.99/yr | Lower friction             |

**Considerations:**

- One-time makes sense for standalone app
- Subscription justified if cloud features (Agency integration, sync)
- Could do: **MockAndMark free**, Agency integration features as paid upgrade (trojan horse model)

**WINNING MODEL (decided):**

- **MockAndMark app: FREE** (trojan horse)
- **Agency Integration: $19.95/month** - push to the right workstream/agent in Agency Workspace
- People will pay for the workflow, not the tool!

### Agency Product Pricing Thoughts

| Product                            | Model           | Notes                             |
| ---------------------------------- | --------------- | --------------------------------- |
| the-agency-starter                 | Free            | Open source, on-ramp              |
| MockAndMark                        | One-time $19.95 | Or free with paid Agency features |
| Workbench                          | Subscription    | $X/seat/month                     |
| AI Services (How, Troubleshooting) | Usage-based?    | Per-query or bundled              |
| AgencyCollaborate                  | Subscription    | Per-seat, tiered                  |
| CI/CD                              | Subscription    | Per-pipeline or per-seat          |

**Open questions:**

- Bundle Workbench with services? (Figma bundles approach)
- Free tier for Workbench? (Essential for adoption)
- Enterprise pricing separate from individual/team?

---

## Decisions Made

- TheAgency AI product suite includes: starter (free), Collaborate, CI/CD, Workspace, Workbench, MockAndMark
- Hosted + Self-hosted deployment model (architect for both from day 1)
- the-agency-starter is the free on-ramp - "camel's nose in the tent" / "trojan horse"
- MockAndMark integrates directly with Agency (save to right workstream/agent)
- **AgencyCollaborate:** Framework approach, start with messaging/coordination (semaphores, counters, indexes)
- **Git:** Layer on top, not replace. "Git for agents."
- **Workspace = Collaborate real-time layer**
- **Launch: Mid-January 2026** at Claude Code Singapore Meetup

---

## Action Items

- [ ] **PRIORITY:** Prepare the-agency-starter for mid-Jan launch
- [ ] Prepare 5-10 minute presentation for Singapore Meetup
- [ ] Identify tools that can quickly be service-backed (NEWS, session backup, etc.)
- [ ] Package Workbench for commercial release
- [ ] Align MockAndMark for early launch alongside Workbench
- [ ] Create product one-pagers for investor/customer conversations
- [ ] Research competitive landscape

---

## Next Steps

- **Immediate:** Focus on the-agency-starter launch readiness
- Create `claude/principals/jordan/projects/theagency-ai/` for business planning
- INSTR-0050 services exploration informs Step 2 (service-ify tools)
- Start identifying beta customers for Workbench commercial

---

_Working note for project: the-agency-book_
