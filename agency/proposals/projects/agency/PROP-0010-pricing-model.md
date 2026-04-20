# PROP-0010: The Agency Pricing Model

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Need a clear, defensible pricing model that:
1. Drives adoption (free tier is genuinely useful)
2. Captures value where it exists (teams, premium features)
3. Offers flexibility (self-host vs hosted)
4. Supports premium tools from day one

## Proposal

### Tier Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    THE AGENCY PRICING                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SOLO-PRINCIPAL (Free)          MULTI-PRINCIPAL (Paid)      │
│  ─────────────────────          ──────────────────────      │
│  • 1 Principal                  • Multiple Principals        │
│  • Unlimited local agents       • Cross-principal coord      │
│  • All local services           • Shared context/knowledge   │
│  • Core tools                   • Team workflows             │
│                                                              │
│         ┌──────────────┐              ┌──────────────┐       │
│         │ + Premium    │              │ Self-Host    │       │
│         │   Add-ons    │              │ License      │       │
│         └──────────────┘              ├──────────────┤       │
│                                       │ Hosted       │       │
│                                       │ Service      │       │
│                                       └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Tier 1: Solo-Principal (FREE)

**Target:** Individual developer/creator running their own Agency

### What's Included

| Category | Included |
|----------|----------|
| Principals | 1 (Solo) |
| Agents | Unlimited, locally orchestrated |
| Services | All run locally |
| Core Tools | Full toolset (tools/) |
| TheCaptain | Basic (local, pattern-based) |
| Markdown Browser | Full (PROP-0004) |
| Work Lifecycle | All local tools |
| Context Stack | Local push/pop |
| Proposals | Local system |

### What's NOT Included

- Multi-principal coordination
- Cloud sync
- Team features
- Premium add-ons (see below)
- TheCaptain Advanced

---

## Tier 2: Premium Add-ons (PAID, Solo-Compatible)

**Target:** Solo principals who want premium tools

Some tools are **paid from day one**, even for Solo:

| Product | Model | Notes |
|---------|-------|-------|
| **MockAndMark** | Subscription | Design tool, paid from launch |
| **TheCaptain Advanced** | Subscription | AI-powered guidance |
| **Markdown Manager** | Subscription | Full editor (beyond browser) |
| **Cloud Backup** | Subscription | Session/context cloud sync |

### MockAndMark

- Paid subscription from day one
- Complimentary access bundled with book purchase
- "And as a free bonus, three months complimentary access..."

### TheCaptain vs TheCaptain Advanced

| Feature | TheCaptain (FREE) | TheCaptain Advanced (PAID) |
|---------|-------------------|---------------------------|
| Tool discovery | ✓ | ✓ |
| Pattern guidance | ✓ Rule-based | ✓ AI-powered |
| Troubleshooting | ✓ Documentation | ✓ AI diagnosis |
| `./tools/how` | Basic answers | Context-aware AI |
| Proactive suggestions | | ✓ |
| Learning from usage | | ✓ |

### Markdown Browser vs Manager

| Feature | Browser (FREE) | Manager (PAID) |
|---------|---------------|----------------|
| View files | ✓ | ✓ |
| Navigation/search | ✓ | ✓ |
| Editing | | ✓ |
| Review comments | | ✓ |
| Versioning | | ✓ |
| Claude integration | | ✓ |

---

## Tier 3: Multi-Principal (PAID)

**Target:** Teams, companies, organizations

### Trigger

The moment you need:
- A second principal
- Shared context between principals
- Cross-agent coordination beyond local
- Team workflows

### Delivery Options

| Option | Model | For |
|--------|-------|-----|
| **Self-Host License** | Annual license | Run on your infrastructure |
| **Hosted Service** | Subscription | We run it for you |

### What's Added

| Feature | Description |
|---------|-------------|
| Multiple Principals | Add team members as principals |
| Shared Knowledge | Team-wide knowledge base |
| Cross-Agent Coord | Agents from different principals collaborate |
| Team Proposals | Voting, assignment, workflows |
| Cloud Context | Synced context across team |
| Admin Dashboard | Usage, permissions, billing |
| Priority Support | Direct access to team |

---

## Pricing Details (Draft)

### Solo Premium Add-ons

| Product | Price | Notes |
|---------|-------|-------|
| MockAndMark | $X/mo | TBD |
| TheCaptain Advanced | $X/mo | TBD |
| Markdown Manager | $X/mo | TBD |
| Cloud Backup | $X/mo | TBD |
| **Bundle** | $X/mo | All premium for Solo |

### Multi-Principal

| Option | Price | Notes |
|--------|-------|-------|
| Self-Host License | $X/year | Per-org, unlimited users |
| Hosted Service | $X/user/mo | Includes all premium |

---

## Revenue Model

```
FREE (the-agency-starter)
  └── Drives adoption
        │
        ├── Premium Add-ons (Solo)
        │     └── MockAndMark, TheCaptain Advanced, etc.
        │
        └── Multi-Principal (Teams)
              ├── Self-Host License
              └── Hosted Service
```

### Upgrade Triggers

| From | To | Trigger |
|------|-----|---------|
| Free | Premium Add-on | "I want AI guidance" / "I need MockAndMark" |
| Free | Multi-Principal | "I need to add a team member" |
| Self-Host | Hosted | "I don't want to manage infrastructure" |

---

## Book Bundle

Reference: ART-0012 (Business Model Research)

The book bundle on Gumroad includes:
- The book (PDF/EPUB)
- Privileged GitHub access
- Discord membership
- X months hosted services
- **Complimentary MockAndMark subscription**
- Complimentary app subscriptions (iOS/Mac)

Framing: "And as a free bonus, three months complimentary access..."

---

## Proposal/Tool Mapping

| Proposal | Free | Solo Premium | Multi-Principal |
|----------|------|--------------|-----------------|
| PROP-0001 Tool Ecosystem | ✓ Core | | Team sharing |
| PROP-0002 Work Lifecycle | ✓ Local | | Cross-agent |
| PROP-0003 Context Stack | ✓ Local | Cloud sync | Team sync |
| PROP-0004 Markdown Browser | ✓ | | |
| PROP-0005 Path Resolution | ✓ | | |
| PROP-0006 Distribution | ✓ | | |
| PROP-0007 Session Capture | ✓ Local | Cloud | Team |
| PROP-0008 Markdown Manager | | ✓ | ✓ |
| PROP-0009 Proposal System | ✓ Local | | Team voting |
| TheCaptain | ✓ Basic | Advanced | Advanced |
| MockAndMark | | ✓ | ✓ |

---

## Key Points

1. **Free is genuinely useful:** Solo-Principal gets full local functionality
2. **Premium for premium:** Some tools (MockAndMark) are paid from day one
3. **Team = paid:** Multi-principal is the natural upgrade trigger
4. **Flexibility:** Self-host or hosted for teams
5. **Bundle opportunity:** Book purchase includes complimentary access

## Open Questions

- [ ] Specific pricing for each tier?
- [ ] Annual vs monthly for add-ons?
- [ ] Free trial period for premium?
- [ ] Education/OSS discounts?

## Dependencies

- Related: All other proposals
- Related: ART-0012 (Business Model Research)

## When Approved

- Becomes: Business model documentation
- Informs: Marketing, product roadmap
- Target: Before public launch (Jan 23)

---

## Discussion Log

### 2026-01-06 - Created
Jordan defined the model:
- Solo-Principal = Free (local everything)
- Some tools paid from day one (MockAndMark)
- Multi-Principal = Paid (self-host or hosted)
- TheCaptain has free and Advanced tiers
