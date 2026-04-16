# PROP-0012: Open Feedback Service

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Traditional feedback collection is structured and limiting:
- Surveys are rigid
- Bug reports lack context
- Feature requests are disconnected from user journey
- Teams can't see the full picture

## Proposal

**Open Feedback** is an AI-powered, context-aware feedback platform. It's like having a focus group available at every moment, not a survey.

### The Name

"Open" because:
1. **Always available** - The widget is always there
2. **Unstructured** - Users can go wherever the conversation takes them
3. **Open-ended** - Not constrained to predefined questions

NOT about open source.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CUSTOMER'S APP                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    CLIENT LIBRARY                           │ │
│  │  @theagency/open-feedback                                   │ │
│  │                                                             │ │
│  │  • Tracks navigation history                                │ │
│  │  • Captures errors (JS, API, etc.)                          │ │
│  │  • Records user actions                                     │ │
│  │  • Maintains session context                                │ │
│  │  • Custom context from app                                  │ │
│  │                                                             │ │
│  │  Everything ready when feedback is triggered.               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    FEEDBACK WIDGET                          │ │
│  │                                                      [💬]   │ │
│  │  • Floating trigger (always visible)                        │ │
│  │  • NOT "?" (that's help) - indicates "tell us something"    │ │
│  │  • User can pre-select type (optional):                     │ │
│  │    [🐛 Bug] [✨ Feature] [❤️ Kudo] [😤 Complaint]           │ │
│  │  • Grabs full context when triggered                        │ │
│  │  • AI-powered conversation                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OPEN FEEDBACK BACKEND                         │
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │ Receive  │ → │ Process  │ → │ Classify │ → │  Store   │     │
│  │ Session  │   │ w/ Claude│   │ & Split  │   │ & Index  │     │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘     │
│                                                                  │
│  Key: Multi-topic conversations → Split into separate items     │
│                                                                  │
│  API: REST + GraphQL                                             │
│  CLI: openfeedback list|search|export|push                      │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANALYSIS DASHBOARD                            │
│                                                                  │
│  ┌─────────────────┬─────────────────┬─────────────────┐        │
│  │  FEEDBACK       │  ANALYSIS       │  REPORTS        │        │
│  │  STREAM         │                 │  & ISSUES       │        │
│  │  ─────────────  │  ─────────────  │  ─────────────  │        │
│  │  🐛 Login fail  │  Clustering     │  REPORT-001:    │        │
│  │  ✨ Dark mode   │  Sentiment      │  "Auth Issues"  │        │
│  │  ❤️ Love it!   │  Trends         │  (12 items)     │        │
│  │  😤 Slow load   │  Patterns       │                 │        │
│  │                 │                 │  [→ GitHub]     │        │
│  │                 │                 │  [→ Jira]       │        │
│  └─────────────────┴─────────────────┴─────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       INTEGRATIONS                               │
│  GitHub Issues │ Jira │ Linear │ Zendesk │ Intercom │ Custom   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Client Library

```javascript
import { OpenFeedback } from '@theagency/open-feedback';

// Initialize
OpenFeedback.init({
  projectId: 'my-app',
  apiKey: 'of_live_...',

  // Automatic tracking
  trackNavigation: true,      // Page/route changes
  captureErrors: true,        // JS errors, unhandled rejections
  captureNetworkErrors: true, // Failed API calls
  captureConsoleErrors: true, // console.error

  // Session context
  sessionTimeout: 30 * 60,    // 30 minutes
});

// Add custom context (always available to feedback agent)
OpenFeedback.setContext({
  userId: user.id,
  userEmail: user.email,
  plan: user.subscription.plan,
  accountAge: user.createdDays,
});

// Track custom events
OpenFeedback.track('checkout_started', {
  cartValue: 149.99,
  itemCount: 3
});

// Manually trigger widget
OpenFeedback.open();
OpenFeedback.open({ type: 'bug' });
```

### Context Captured

| Category | What's Tracked | Why |
|----------|---------------|-----|
| Navigation | Last N pages, time on each | Reproduce user journey |
| Errors | Stack traces, API failures | Bug context |
| Actions | Clicks, form submissions | What they were doing |
| Session | Duration, device, browser | Environment |
| Custom | App-specific via setContext() | Business context |

### 2. Feedback Widget

**Trigger Icon:**
- NOT "?" (that's help/docs)
- Something that says "tell us" or "message us"
- Options: 💬 📝 ✉️ or custom

**Type Selection:**
- Optional pre-selection before chat
- Single-select (for now): Bug | Feature | Kudo | Complaint | Other
- Can change during conversation

**The Conversation:**

```
┌─────────────────────────────────────────────┐
│  Open Feedback                          ✕   │
├─────────────────────────────────────────────┤
│                                             │
│  What would you like to share?              │
│                                             │
│  [🐛 Bug] [✨ Feature] [❤️ Kudo] [😤 Issue] │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│  👤 The checkout is broken                  │
│                                             │
│  🤖 I can see you were on the checkout      │
│     page and there was an error with the    │
│     payment API. Can you tell me what       │
│     you were trying to do?                  │
│                                             │
│  👤 I tried to pay with my credit card      │
│     but it just spun forever                │
│                                             │
│  🤖 Got it. I'm seeing a timeout error      │
│     from Stripe at 14:32. Was this a        │
│     Visa or Mastercard?                     │
│                                             │
│  👤 Visa. Also, unrelated, but dark mode    │
│     would be really nice to have            │
│                                             │
│  🤖 Noted! Let me reflect back what I'm     │
│     hearing:                                │
│                                             │
│     1. 🐛 Bug: Payment timeout with Visa    │
│        on checkout (error captured)         │
│     2. ✨ Feature: Dark mode request        │
│                                             │
│     Is that right?                          │
│                                             │
│  👤 Yes!                                    │
│                                             │
│  🤖 Thanks! Both have been recorded with    │
│     full context. Anything else?            │
│                                             │
├─────────────────────────────────────────────┤
│  [Type a message...]              [Send]    │
└─────────────────────────────────────────────┘
```

**Key Behaviors:**
- AI has full context from client library
- Can reference specific errors, pages, actions
- Reflects back: "This is what I'm hearing"
- Confirms: "Got it!"
- Multi-topic: User can cover multiple issues
- Backend splits into separate items

### 3. Backend Service

**Receiving:**
- Session context (navigation, errors, etc.)
- Conversation transcript
- User-selected type(s)
- Timestamps, metadata

**Processing with Claude:**
- Summarize each topic (keep original transcript)
- Classify: bug | feature | kudo | complaint | question | other
- Extract: severity, affected area, user sentiment
- Split multi-topic conversations into separate items

**Storage:**
- Original transcript preserved
- Summary for quick scanning
- Structured metadata for filtering
- Full-text indexed for search

**API:**
```bash
# CLI
openfeedback list --type bug --since 7d
openfeedback search "checkout payment"
openfeedback export --format csv --since 30d
openfeedback push ITEM-123 --to github

# REST
GET  /api/v1/feedback
GET  /api/v1/feedback/:id
POST /api/v1/feedback/:id/push
GET  /api/v1/reports
POST /api/v1/reports
```

### 4. Analysis Dashboard

**Feedback Stream:**
- Real-time feed of incoming feedback
- Filter by type, date, user, severity
- Quick actions: assign, tag, group

**Analysis Tools:**
- Clustering: Auto-group similar items
- Sentiment: Track positive/negative trends
- Patterns: Identify recurring issues
- Trends: Volume over time by type

**Reports & Issues:**
- Group related feedback into Reports
- Create Issues from patterns
- Track resolution status
- Link back to source feedback

### 5. Integrations

**Push to external systems:**

| System | What's Pushed |
|--------|--------------|
| GitHub Issues | Bug as issue, with context |
| Jira | Issue with custom fields |
| Linear | Issue with labels |
| Zendesk | Ticket for support |
| Intercom | Conversation |
| Webhook | Custom payload |

**Two-way sync (future):**
- When GitHub issue closed → update feedback status
- When Jira ticket resolved → mark items addressed

---

## Pricing

**Premium across the board** - this is a paid product.

### Model: Base + Per-Report

Following analytics pricing patterns:

| Tier | Base/mo | Included | Per Extra |
|------|---------|----------|-----------|
| Starter | $29 | 500 reports | $0.05 |
| Pro | $99 | 2,500 reports | $0.03 |
| Business | $299 | 10,000 reports | $0.02 |
| Enterprise | Custom | Custom | Custom |

### What's a "Report"?

One feedback item after splitting:
- User submits 1 conversation with 3 topics → 3 reports
- Bug with context → 1 report
- Quick kudo → 1 report

### Self-Host Option

- Annual license for enterprise
- Run on your infrastructure
- Bring your own Claude API key
- Same features, you control data

### Local POC

- Limited local version for evaluation
- 50 reports lifetime
- Upgrades to hosted or self-host

---

## Relationship to The Agency

Open Feedback is part of The Agency product ecosystem:

```
THE AGENCY (Development)
         │
         ▼
   Open Feedback
   (captures user feedback)
         │
         ▼
   Reports & Issues
   (prioritized by team)
         │
         ▼
   INSTRs / Work Items
   (assigned to agents)
         │
         ▼
   Implementation
   (back to the product)
```

Feedback flows into the development process. This is tooling that makes AI-augmented development better.

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Client Library | TypeScript, tree-shakeable |
| Widget | Preact (tiny), iframe isolation |
| Backend | Nitro (Node.js) |
| AI | Claude API |
| Database | Postgres (hosted), SQLite (local) |
| Search | Typesense or Meilisearch |
| Dashboard | Next.js |

---

## Key Points

1. **Focus group, not survey** - Open-ended, contextual conversations
2. **Full context** - Client library captures everything useful
3. **AI-powered** - Claude processes, summarizes, classifies
4. **Multi-topic splitting** - One conversation → multiple items
5. **Actionable output** - Push to issue trackers, group into reports
6. **Premium product** - Paid from day one, not free tier

## Open Questions

- [ ] Widget icon - what indicates "tell us something"?
- [ ] Type selection - single or multi-select?
- [ ] Offline support in client library?
- [ ] Real-time dashboard updates?
- [ ] White-label option for agencies?

## Dependencies

- Related: PROP-0010 (Pricing Model)
- Related: INSTR-0050 (TheAgency Services)

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: dedicated team
- Target: v0.4.0 (post-launch product)

---

## Discussion Log

### 2026-01-06 - Created
Jordan defined the full vision:
- "Like a focus group, not a survey"
- "Not about open source - about always available and unstructured"
- "Backend splits multi-topic conversations into separate items"
- "Premium across the board"
