# THE-AGENCY-BOOK-WORKING-NOTE-0012

**Date:** 2026-01-04 07:43 SGT
**Participants:** Ujordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** TheAgencyOracle - AI-Powered Agent Guidance Service

---

## Discussion

### The Concept

**TheCaptain** - a unified AI-powered guidance service for The Agency with three core modes:

```
TheCaptain
├── how         → Tool discovery ("How do I push?")
├── troubleshoot → Debugging ("Why won't my agent spawn?")
└── onboard     → First-run setup ("Interview with The Captain")
```

The same AI, same knowledge base, different entry points. The Captain guides you from day one (onboard) through daily work (how) and when things go wrong (troubleshoot).

### Key Insight: Shared Knowledge Service for Agents

TheCaptain is not just for principals - **agents use it too**.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  web agent  │     │catalog agent│     │  housekeep  │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────▼──────┐
                    │ TheCaptain  │
                    │             │
                    │ • All tools │
                    │ • Patterns  │
                    │ • Playbooks │
                    │ • History   │
                    └─────────────┘
```

**Why this matters:**

- Agents have limited context windows
- Can't carry full knowledge of every tool, pattern, anti-pattern
- TheCaptain extends their reasoning space on-demand
- Query when stuck → get targeted guidance → continue work

**Example agent usage:**

```bash
# Agent is stuck, queries TheCaptain
result=$(./captain troubleshoot "supabase RLS policy blocking insert")
# Gets targeted fix, applies it, continues
```

This makes TheCaptain a **force multiplier** - every agent becomes smarter without bloating their individual context.

### TheCaptain as Collaborator, Not Just Tool

TheCaptain isn't a utility you invoke - it's **a member of the crew** that both principals and agents work with.

```
┌─────────────────────────────────────────────────────┐
│                    THE AGENCY                        │
│                                                      │
│   ┌──────────┐                    ┌──────────────┐  │
│   │ Principal │◄──── chats ─────►│  TheCaptain  │  │
│   └──────────┘                    └───────▲──────┘  │
│                                           │         │
│   ┌──────────┐  ┌──────────┐             │         │
│   │  Agent A │  │  Agent B │◄─collaborates─┘        │
│   └──────────┘  └──────────┘                        │
│         ▲              ▲                            │
│         └──────────────┴─── collaborates ───────────┤
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Principal interactions:**

- "Captain, how should I structure this new feature?"
- "Captain, why did my deploy fail?"
- "Captain, onboard me to this codebase"

**Agent interactions:**

- "Captain, what tool handles this?"
- "Captain, I'm stuck on RLS policy, help"
- "Captain, what's the pattern for X in this codebase?"

**The Captain is always available, always consistent, never forgets.**

This positions TheCaptain as the **institutional memory** and **wisdom keeper** of the agency - the one who's seen it all and can guide anyone through anything.

### Naming Exploration

**TheAgencyOracle**

- Pros: Mystical, wise, conveys knowledge/guidance
- Cons: Oracle Corporation trademark risk (they're aggressive)
- Risk level: Medium - different domain (dev tools vs database), but Oracle has sued over less

**Safer alternatives:**

| Name                   | Vibe                      | Notes                                     |
| ---------------------- | ------------------------- | ----------------------------------------- |
| **TheAgencyGuide**     | Friendly, approachable    | Simple, clear purpose                     |
| **TheAgencySage**      | Wise, knowledge-based     | Less trademark risk                       |
| **TheAgencyAdvisor**   | Professional              | Consulting feel                           |
| **TheAgencyMentor**    | Teaching-oriented         | Growth mindset                            |
| **TheAgencyNavigator** | Direction, pathfinding    | Discovery focus                           |
| **TheAgencyCompass**   | Always-on direction       | Minimal, clean                            |
| **TheCaptain**         | Fits existing terminology | "Interview with The Captain" synergy      |
| **AgencyAI**           | Direct, modern            | Could work as subdomain: ai.theagency.dev |

**Recommendation:** "TheAgencyGuide" or "TheCaptain" (leveraging existing branding from onboarding)

### Functionality Beyond How + Troubleshoot

**Core (MVP):**

1. **Tool Discovery** - "How do I X?" → right tool
2. **Troubleshooting** - "Why isn't X working?" → diagnosis + fix
3. **Best Practices** - "What's the right way to X?" → patterns

**Extended:** 4. **Architecture Guidance** - "How should I structure this feature?" 5. **Code Review** - "Is this implementation good?" 6. **Onboarding/Learning** - "Teach me about agents/workstreams/principals" 7. **Cost Optimization** - "How do I reduce my API costs?" 8. **Security Review** - "Is this configuration secure?" 9. **Integration Help** - "How do I connect Supabase to my agent?" 10. **Migration Assistance** - "How do I upgrade from v1 to v2?"

**Advanced (future):** 11. **Performance Profiling** - "Why is my agent slow?" 12. **Multi-agent Coordination** - "How should these agents communicate?" 13. **Custom Tool Generation** - "Build me a tool that does X" 14. **Workflow Optimization** - "What's the fastest way to do X?"

### Delivery Models

| Model                              | Pros                    | Cons                       |
| ---------------------------------- | ----------------------- | -------------------------- |
| **CLI tool** (`./agency ask`)      | Local, fast, integrated | Requires local setup       |
| **Web chat** (theagency.dev/guide) | Accessible, no setup    | Hosting costs, auth needed |
| **VS Code extension**              | IDE-integrated          | Platform-specific          |
| **Slack/Discord bot**              | Community-integrated    | External dependency        |

**Recommendation:** Start with CLI (bundled with Agency Starter), add web chat for book purchasers.

### Knowledge Base

What does the Oracle/Guide need to know?

- THE_AGENCY.md (concepts, philosophy)
- CONCEPTS.md (terminology)
- All tools/ with descriptions
- Common patterns and anti-patterns
- Troubleshooting playbooks
- FAQ from early adopters

### Business Model

| Tier           | Access                                 | Price                 |
| -------------- | -------------------------------------- | --------------------- |
| Free           | Basic how + troubleshoot, rate-limited | $0                    |
| Book Purchaser | Full access, higher limits             | Included with book    |
| Pro            | Unlimited, priority, custom training   | $X/month subscription |

---

## Decisions Made

- **TheCaptain** is the name - ties into "Interview with The Captain" onboarding
- Trademark safe, memorable, fits the nautical/guidance vibe
- Start with CLI (`./captain` or `captain ask`), expand to web

---

## Action Items

- [ ] Validate "TheAgencyGuide" domain availability
- [ ] Sketch CLI interface for combined how+troubleshoot
- [ ] Define knowledge base curation process
- [ ] Draft business model for book integration

---

## Next Steps

- Prototype TheCaptain CLI with unified interface
- Consolidate instructions under TheCaptain umbrella:
  - INSTR-0028 (Agency Man Facility / How) → TheCaptain.how
  - INSTR-0029 (Troubleshooting Agent) → TheCaptain.troubleshoot
  - INSTR-0042 (Interview with The Captain) → TheCaptain.onboard
- Design knowledge base structure for all three modes

---

_Working note for project: the-agency-book_
