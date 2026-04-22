# THE-AGENCY-BOOK-WORKING-NOTE-0011

**Date:** 2026-01-04 00:24 SGT
**Participants:** jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** TheAgencyFeedback - Context-Aware Feedback Collection

---

## Discussion

### The Problem with Traditional Feedback

Traditional feedback tools (Zendesk, Intercom, UserVoice, Canny) are **external** to the workflow:

- Users have to context-switch
- Manually describe what they were doing
- Try to remember error messages
- Provide reproduction steps from memory

**Result:** High friction = only the angriest or most motivated users provide feedback. You lose the valuable "this is mildly annoying" or "wouldn't it be nice if..." moments.

### TheAgencyFeedback: The Insight

Because TheAgency IS the development platform, we have deep visibility into:

1. What the user was doing (last N commands/operations)
2. Recent errors or issues (with stack traces)
3. Current file/workstream/agent context
4. Session duration and patterns
5. Environment info (OS, versions, config)

**We already have the context. We just need to ask: "What's on your mind?"**

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│  Context Already Captured (because we ARE the platform) │
├─────────────────────────────────────────────────────────┤
│  • Last N commands/operations                           │
│  • Recent errors (with stack traces)                    │
│  • Current file/workstream/agent                        │
│  • Session duration, what they were trying to do        │
│  • Environment info (OS, versions, config)              │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  User just types what's on their mind                   │
│  "This is annoying" / "Would be cool if..." / "Love it" │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  AI Classification & Routing                            │
├─────────────────────────────────────────────────────────┤
│  🐛 Bug Report      → Engineering (with repro context!) │
│  ✨ Feature Request → Product (with usage patterns)     │
│  😤 Complaint       → Customer Success (with history)   │
│  ❤️ Kudo           → Team morale + marketing            │
└─────────────────────────────────────────────────────────┘
```

### Why This Is Different

**Windows Crash Reporter** captures state but only on crashes, and users rarely add context.

**UserVoice/Canny** collects feedback but has no context - users must describe everything manually.

**TheAgencyFeedback** combines:

- Automatic context capture (like crash reporter)
- Free-form feedback (like UserVoice)
- AI classification (smart routing)
- Deep context (because we ARE the platform)

### The Moat

**You can only do this if you ARE the development platform.**

- GitHub can't do this (they don't see the full workflow)
- Slack can't do this (they're not in the IDE)
- VSCode extensions could try, but they don't have agent context

We have the full picture: commands, errors, agent state, workstream, files touched.

### Near 100% Adoption

Our "attack surface" is the entire development workflow:

1. Developers are already IN TheAgency tools
2. The feedback button is right there
3. Context is auto-captured (no manual reproduction steps)
4. Low friction = high usage
5. Covers: developers, tests, product

We even integrate issue reporting and tracking - full circle.

### The Recursive Play

Our customers can add TheAgencyFeedback to THEIR products via our starter kits.

We're not just using it - we're selling it.

```
TheAgency AI uses TheAgencyFeedback
        │
        ▼
Our customers buy TheAgencyFeedback
        │
        ▼
Their users give feedback through TheAgencyFeedback
        │
        ▼
We have starter kits for every framework/language
```

### Revenue Model Options

| Model        | Description                             |
| ------------ | --------------------------------------- |
| Per-feedback | Pay per classified feedback item        |
| Subscription | Monthly per-seat for teams              |
| Volume tiers | Free tier (100/mo), paid tiers for more |
| Enterprise   | Self-hosted with support contract       |

---

## Decisions Made

- TheAgencyFeedback is a major product in the TheAgency AI suite
- Context-aware = key differentiator (we capture what others can't)
- AI classification routes to the right team automatically
- Starter kits enable our customers to offer it to THEIR users (recursive play)
- Added to INSTR-0050 as service candidate #12

---

## Action Items

- [ ] Add TheAgencyFeedback to INSTR-0050 services exploration
- [ ] Design the context capture protocol (what do we collect?)
- [ ] Design the classification system (bug/feature/complaint/kudo + custom?)
- [ ] Research existing feedback tools for competitive analysis
- [ ] Explore privacy implications of context capture

---

## Next Steps

- Service architecture exploration in INSTR-0050
- Consider early prototype as `./tools/feedback` in the-agency-starter
- Think about SDK/starter kit design for customer implementation

---

_Working note for project: the-agency-book_
