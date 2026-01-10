# THE-AGENCY-BOOK-WORKING-NOTE-0003

**Date:** 2026-01-02 17:13 SGT
**Participants:** Jordan (principal), housekeeping/Opus 4.5 (agent)
**Subject:** Agency Starter Product Requirements - Three Open Issues

---

## Context

The Agency Guide outline (v2 final) flagged three product requirements that need resolution before the book and The Agency Starter can launch. This working note captures definitions, approaches, and next steps for each.

---

## Issue 1: Troubleshooting Agent

### What It Is

A Claude-backed agent available 24/7 for debugging, configuration, and best practices guidance. Chat interface for Principals and Agents who need help with The Agency.

### Value Proposition

- Instant support without waiting for humans
- Knows The Agency framework deeply (trained on repo, docs, patterns)
- Can help debug issues, suggest tools, explain concepts
- Available to book purchasers / subscribers

### Open Questions

- [jordan] How do we implement this? Dedicated Claude instance with custom system prompt?
- [jordan] How do we gate access to purchasers?
- [jordan] What's the cost model? Per-query? Included with purchase?
- [captain] Could be a specialized agent definition that principals can spin up locally
- [captain] Or a hosted service with auth

### Approach

1. Define the agent's knowledge base (repo, docs, THE_AGENCY.md, CONCEPTS.md)
2. Create agent.md definition for Troubleshooting Agent
3. Determine hosting model (local vs. hosted)
4. Define access gating mechanism

---

## Issue 2: Community Infrastructure

### What It Is

Two community platforms for Agency users:

- **GitHub Discussions** - Async support, integrated with repo
- **Discord** - Real-time discussion, sharing, community

### Value Proposition

- Peer support and knowledge sharing
- Direct connection to maintainers
- Community-driven patterns and extensions
- Included with book purchase

### Open Questions

- [jordan] Can we gate GitHub repo access to subscribers?
- [jordan] How do we verify book purchase for Discord access?
- [captain] GitHub private repos can be gated; public repos cannot restrict Discussions
- [captain] Discord has role-based access - could verify via email or purchase code

### Approach

1. Investigate GitHub access gating options
2. Set up Discord server with role-based channels
3. Define verification flow (purchase -> access code -> community access)
4. Document community guidelines

---

## Issue 3: Starter Packs

### What It Is

Modular, composable setup guides. Each pack = knowledge + context + checklists + verification for ONE piece of infrastructure. Chain them together for your stack.

### Core Principle

**Everything via API and CLI.** Starter packs teach the CLI/API-first approach - no clicking through UIs. This is how agents work, and how humans should work too.

### Structure Per Pack

```
starter-packs/{pack-name}/
├── README.md           # What this is, why, trade-offs
├── PREREQUISITES.md    # What you need, which packs to run first
├── SETUP.md            # Step-by-step checklist (CLI/API commands)
├── VERIFY.md           # How to confirm it works
├── INTEGRATE.md        # How it connects to other packs
└── KNOWLEDGE.md        # Context for agents working with this
```

### Initial Pack List

| Pack                 | Scope                              | Dependencies                     |
| -------------------- | ---------------------------------- | -------------------------------- |
| `node-base`          | Node.js project setup, pnpm        | None                             |
| `react-app`          | React application (Next.js)        | node-base                        |
| `nitro-api`          | Nitro.js API/service layer         | node-base                        |
| `supabase-auth`      | Supabase for authentication        | node-base                        |
| `supabase-data`      | Supabase for data storage          | supabase-auth                    |
| `posthog-analytics`  | PostHog for product analytics      | node-base                        |
| `supabase-analytics` | Supabase for event storage         | supabase-data, posthog-analytics |
| `github-ci`          | GitHub Actions CI pipeline         | node-base                        |
| `vercel-deploy`      | Vercel deployment                  | github-ci                        |
| `localization`       | i18n pipeline with content manager | react-app                        |
| `pulse-beat`         | Org observability dashboard        | supabase-analytics               |

### Backlog

| Pack                | Scope                    | Notes                  |
| ------------------- | ------------------------ | ---------------------- |
| `react-native`      | React Native mobile app  | Future - mobile apps   |
| `expo`              | Expo for React Native    | Future - easier mobile |
| `cloudflare-deploy` | Cloudflare Pages/Workers | Alternative to Vercel  |

### Use Cases

- **Web app (full stack):** node-base -> react-app -> supabase-auth -> supabase-data -> posthog-analytics -> github-ci -> vercel-deploy
- **API service only:** node-base -> nitro-api -> supabase-auth -> supabase-data -> github-ci -> vercel-deploy
- **Mobile backend:** node-base -> nitro-api -> supabase-auth -> supabase-data -> posthog-analytics

### Approach

1. Document our actual Project X setup as the reference implementation
2. Extract into discrete packs
3. Define composition patterns and dependency graph
4. Test by having someone rebuild from packs

---

## Decisions Made

- Starter packs are modular and composable
- API/CLI-first approach is mandatory
- Node.js and React are separate packs
- Nitro.js for API-only/mobile backend use cases
- React Native is backlog, not initial launch
- PostHog is the analytics platform
- Supabase is for auth (primary) and data storage

---

## Action Items

- [ ] Create INSTR-0029: Troubleshooting Agent
- [ ] Create INSTR-0030: Community Infrastructure
- [ ] Create INSTR-0031: Starter Packs
- [ ] Document Project X setup as reference for starter packs

---

## Next Steps

1. Create INSTRs for each issue (reference this working note)
2. Prioritize based on book/launch dependencies
3. Begin implementation

---

_Working note for project: the-agency-book_
