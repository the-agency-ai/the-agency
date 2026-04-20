# The Agency — Jan 23 Product Backlog

**Target:** Claude Code Meetup Singapore — January 23, 2026
**Goal:** Compelling free framework for Solo Principals + paid add-ons + team features

---

## Product Tiers Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    THE AGENCY PRODUCT TIERS                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  TIER 1: SOLO PRINCIPAL (FREE)         TIER 2: SOLO PREMIUM (PAID)      │
│  ───────────────────────────           ─────────────────────────        │
│  Fully open source                     Add-ons for serious work         │
│  Everything to run your Agency         Book, video, premium tools       │
│                                                                          │
│  ┌───────────────────────────┐         ┌───────────────────────────┐    │
│  │ the-agency-starter        │         │ The Agency Guide ($29)    │    │
│  │ 40+ tools, install.sh     │         │ Complete 12-chapter book  │    │
│  │ CLAUDE.md, conventions    │         ├───────────────────────────┤    │
│  │ /welcome onboarding       │         │ Starter Pack ($49)        │    │
│  │ Markdown Browser          │         │ Book + video + templates  │    │
│  │ Workbench Free            │         ├───────────────────────────┤    │
│  │ TheCaptain Basic          │         │ Premium Bundle ($99)      │    │
│  │ Discord community         │         │ All above + 3mo premium   │    │
│  └───────────────────────────┘         └───────────────────────────┘    │
│                                                                          │
│  TIER 3: MULTI-PRINCIPAL (FUTURE)                                        │
│  ────────────────────────────────                                        │
│  Teams, companies, organizations                                         │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │ Team License ($199/year) | Hosted Service ($X/user/mo)            │  │
│  │ Multiple principals, shared knowledge, cross-agent coordination   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## TIER 1: Solo Principal (FREE & Open Source)

**Philosophy:** Make doing it the right way, the fast way.

### Core Framework: the-agency-starter

| Component | Status | Notes |
|-----------|--------|-------|
| **Repository** | ✅ Exists | github.com/the-agency-ai/the-agency-starter |
| **40+ tools** | ✅ Done | Full toolset in tools/ |
| **install.sh** | ✅ Done | One-command install, auto-installs Claude Code |
| **CLAUDE.md** | ✅ Done | Constitution with conventions |
| **PHILOSOPHY.md** | ✅ Done | "Right Way = Fast Way" documented |
| **/welcome** | ✅ Exists | Interview-based onboarding |
| **init-agency** | 🔴 Missing | Referenced in Ch4 but not implemented |

### Free Products

| Product | Description | Status | Priority |
|---------|-------------|--------|----------|
| **Markdown Browser** | Read-only viewer for Agency docs | 🔴 PROP-0004 | P1 - Workshop |
| **Workbench Free** | Shell + Agent Status module | 🔴 PROP-0011 | P2 |
| **TheCaptain Basic** | Tool discovery, rule-based guidance | 🟡 Partial | P2 |
| **Chapters 1-4 Free** | First 4 chapters of the guide | 🟡 Draft | P1 |

### Community Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| **GitHub repo public** | 🟡 Private, synced | Ready to go public Jan 23 |
| **Discord server** | 🔴 Not created | Credentials ready in secrets |
| **GitHub Discussions** | 🔴 Not enabled | Async support |
| **Workshop token** | ✅ Created | Expires Jan 12, 2026 |

---

## TIER 2: Solo Premium (Paid Add-ons)

### Gumroad Products

| Product | Price | Contents | Status |
|---------|-------|----------|--------|
| **The Agency Guide** | $29 | Complete 12-chapter book (PDF/EPUB) | 🟡 Chapters drafting |
| **Starter Pack** | $49 | Book + video walkthrough + templates | 🔴 Video not recorded |
| **Premium Bundle** | $99 | Everything + 3mo MockAndMark + Discord role | 🔴 Needs setup |

### Premium Tools (Subscription)

| Product | Price | Description | Status | Source |
|---------|-------|-------------|--------|--------|
| **Markdown Manager** | $X/mo | Full editor, review comments, versioning | 🔴 PROP-0008 | |
| **TheCaptain Advanced** | $X/mo | AI-powered guidance, proactive suggestions | 🔴 | |
| **MockAndMark** | $X/mo | Design tool | 🔴 | External |
| **Workbench Premium** | $X/mo | All modules (Pulse Beat, Content, etc.) | 🔴 PROP-0011 | |
| **Open Feedback** | $X/mo | AI-powered contextual feedback platform | 🔴 PROP-0012 | |

### Book Chapters Status

| Chapter | Title | Status |
|---------|-------|--------|
| Ch 1 | The Problem with AI Teams | 🟡 Draft v3, reviewed |
| Ch 2 | What is The Agency | 🔴 Pending |
| Ch 3 | Agents | 🔴 Pending |
| Ch 4 | Getting Set Up | 🟡 Draft v1, reviewed |
| Ch 5 | First Project | 🔴 Pending |
| Ch 6 | Workstreams | 🔴 Pending |
| Ch 7 | Collaboration | 🔴 Pending |
| Ch 8 | Quality | 🔴 Pending |
| Ch 9 | Scaling | 🔴 Pending |
| Ch 10 | Workbench | 🔴 Pending (scope unclear) |
| Ch 11 | Advanced | 🔴 Pending |
| Ch 12 | Future | 🔴 Pending |

---

## TIER 3: Multi-Principal (Future)

### Team Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Multiple Principals** | Add team members | 🔴 Future |
| **Shared Knowledge** | Team-wide knowledge base | 🔴 Future |
| **Cross-Agent Coordination** | Agents from different principals collaborate | 🔴 Future |
| **Staff Manager** | Principal/user management module | 🔴 PROP-0011 |
| **Team Analytics** | Cross-principal dashboards | 🔴 Future |
| **Admin Console** | Billing, audit, org settings | 🔴 Future |

### Delivery Options

| Option | Price | For |
|--------|-------|-----|
| **Self-Host License** | $199/year | Run on your infrastructure |
| **Hosted Service** | $X/user/mo | We run it for you |

---

## What Can Ship by Jan 23?

### Definitely Ready (✅)

| Item | Status |
|------|--------|
| the-agency-starter repo | ✅ 40+ tools, install.sh, synced |
| PHILOSOPHY.md | ✅ Core principles |
| /welcome onboarding | ✅ Interview-based, tested |
| Workshop materials | ✅ WORKSHOP.md complete |
| Discord/Gumroad credentials | ✅ Stored in secrets |
| Pre-work WhatsApp message | ✅ Drafted |
| Pre-approved permissions | ✅ .claude/settings.json |
| Workshop token | ✅ Expires Jan 12 |

### Achievable with Focus (🟡)

| Item | Work Required | Owner |
|------|---------------|-------|
| **Make repo public** | Decision + README polish | jordan |
| **Create Discord server** | 1-2 hours setup | jordan |
| **Gumroad products** | Create 3 products | jordan |
| **Free chapters (1-4)** | Polish pass | housekeeping |
| **Markdown Browser** | 4-8 hours implementation | web + housekeeping |
| **init-agency tool** | 2-4 hours | housekeeping |

### Stretch Goals (🔴)

| Item | Notes |
|------|-------|
| Full 12-chapter book | Time-constrained |
| Video walkthrough | Record after workshop |
| Workbench Free | MVP possible |
| Premium subscriptions | Infrastructure needed |

---

## Minimum Viable Jan 23 Launch

If we had to ship with minimal scope:

### Tier 1: Free (MUST HAVE)

1. **GitHub:** Make the-agency-starter PUBLIC
2. **Discord:** Create server with channels
3. **Content:** Chapters 1-4 free on website/Gumroad

### Tier 2: Paid (SHOULD HAVE)

4. **Gumroad:** "The Agency Guide" $29 (even if incomplete)
5. **Gumroad:** "Starter Pack" $49 (book + future video placeholder)

### Marketing (MUST HAVE)

6. **Announcement:** Twitter thread + HN post
7. **Workshop recording:** From Jan 9 workshop

---

## Implementation Priorities

### Week 1: Jan 6-12 (Workshop Focus)

| Priority | Task | Owner | Status |
|----------|------|-------|--------|
| P0 | Test install.sh end-to-end | housekeeping | ✅ Verified Jan 6 |
| P0 | Test /welcome flow | housekeeping | ✅ Verified Jan 6 |
| P0 | Verify AGENCY_TOKEN clone | housekeeping | ✅ Working Jan 6 |
| P0 | Workshop slides | jordan + opus | 🔴 |
| P0 | Finalize pre-work WhatsApp | jordan | ✅ Drafted Jan 6 |
| P0 | Pre-approved permissions | housekeeping | ✅ Added Jan 6 |
| P0 | Sync the-agency-starter repo | housekeeping | ✅ Done Jan 6 |
| P0 | **Fri Jan 9 14:00 Workshop** | ALL | |

### Week 2: Jan 13-19 (Polish)

| Priority | Task | Owner |
|----------|------|-------|
| P1 | Create Discord server | jordan |
| P1 | Create Gumroad products | jordan |
| P1 | Implement init-agency | housekeeping |
| P1 | Implement Markdown Browser | web + housekeeping |
| P1 | Polish chapters 1-4 | housekeeping |
| P2 | Real examples (yak shaving, broken windows) | jordan |
| P2 | Record video from workshop | jordan |

### Week 3: Jan 20-23 (Launch)

| Priority | Task | Owner |
|----------|------|-------|
| P0 | Final testing | housekeeping |
| P0 | Make repo public | jordan |
| P0 | Write announcement post | jordan + opus |
| P0 | **Jan 23 Announcement** | ALL |

---

## Key Products by Tier

### Free (Solo Principal)

| Product | Type | Deliverable |
|---------|------|-------------|
| **the-agency-starter** | Repo | github.com/the-agency-ai/the-agency-starter |
| **The Agency Guide (Ch 1-4)** | Content | Free chapters |
| **Markdown Browser** | Tool | apps/markdown-browser |
| **Discord Community** | Community | discord.gg/theagency |

### Paid (Solo Premium)

| Product | Type | Price | Deliverable |
|---------|------|-------|-------------|
| **The Agency Guide** | Book | $29 | PDF/EPUB via Gumroad |
| **Starter Pack** | Bundle | $49 | Book + video + templates |
| **Premium Bundle** | Bundle | $99 | All + premium access |

### Future (Multi-Principal)

| Product | Type | Price | Deliverable |
|---------|------|-------|-------------|
| **Team License** | License | $199/yr | Self-host multi-principal |
| **Hosted Service** | SaaS | $X/user/mo | Managed multi-principal |

---

## Dependencies & Blockers

### Critical Path

```
Workshop (Fri Jan 9)
├── install.sh verified
├── /welcome works
└── Token access works
         │
         ▼
    Workshop learnings
         │
         ▼
    Gumroad products created
    Discord server created
         │
         ▼
    Jan 23 Announcement
```

### Blockers

| Blocker | Impact | Resolution |
|---------|--------|------------|
| init-agency missing | Ch4 doesn't work | Build it |
| Repo private | No public access | Make public |
| No Discord server | No community | Create it |
| No Gumroad products | Can't sell | Create them |

---

## Revenue Projections (Illustrative)

| Product | Price | If 100 sales | If 500 sales |
|---------|-------|--------------|--------------|
| The Agency Guide | $29 | $2,900 | $14,500 |
| Starter Pack | $49 | $4,900 | $24,500 |
| Premium Bundle | $99 | $9,900 | $49,500 |

**Note:** These are illustrative. Focus is on adoption first, revenue second.

---

## Success Metrics for Jan 23

### Must Achieve

- [ ] Repo public and accessible
- [ ] Discord server live with channels
- [ ] At least 1 Gumroad product live
- [ ] Announcement posted (Twitter, HN)

### Should Achieve

- [ ] 50+ GitHub stars in first week
- [ ] 100+ Discord members in first week
- [ ] 10+ book sales in first week

### Nice to Have

- [ ] HN front page
- [ ] Workshop video published
- [ ] All Gumroad products live

---

_Product backlog for The Agency Jan 23 launch_
_Created: 2026-01-06_
_Principal: jordan_
