# WORKINGNOTE: Designing TheAgencyService

**Date:** 2026-01-10
**Participants:** principal:jordan, agent:housekeeping
**Context:** Design session for TheAgencyService - the API layer for The Agency

---

## The Problem

We built BugBench with a classic mistake: the CLI tool (`./tools/report-bug`) and the Tauri backend both directly access SQLite. This means:

- Business logic duplicated (ID generation, notifications, validation)
- No path to cloud deployment
- Can't add new clients without duplicating again

**The symptom that exposed it:** When we added assignee notifications, we had to implement it in *two places* - the bash CLI and the Rust Tauri code.

## The Discussion

### "Should we have an API?"

Yes. CLI tools and AgencyBench should both call a central API. Single source of truth.

### "What about when we go to the cloud?"

This sparked a deep architecture discussion:

1. **Database abstraction** - Need to swap SQLite for PostgreSQL/Supabase without changing business logic
2. **Queue abstraction** - Need to swap SQLite-backed queue for Redis/RabbitMQ
3. **Auth abstraction** - Token-based from day one, even if it "always passes" locally

### "What framework?"

We debated three options:

**Hono (selected):**
- Ultra-minimal (~14KB)
- Runs anywhere: Bun, Node, Deno, Cloudflare Workers, Lambda
- Fast cold start (~5ms) - critical for CLI auto-launch
- Low memory (~20MB) - runs all day on a laptop

**Nitro:**
- More batteries-included
- 20+ deployment presets
- Heavier (~500KB), slower cold start
- Good if we want more structure

**NestJS:**
- Full enterprise framework with DI
- Excellent for large teams
- Too heavy for CLI auto-launch (~2s cold start)
- Would be right choice for dedicated server

**Decision:** Start with Hono. Revisit if we need more structure.

### "What about lock-in?"

Jordan pushed hard on this. The solution:

**Every infrastructure choice is behind an interface.**

```
Business Logic (services)
        ↓
    Interfaces
        ↓
Adapters (swappable by config)
```

| Layer | Interface | Local Adapter | Cloud Adapter |
|-------|-----------|---------------|---------------|
| Database | `DatabaseAdapter` | SQLite | PostgreSQL |
| Queue | `QueueAdapter` | SQLite-backed | Redis/BullMQ |
| Auth | `AuthMiddleware` | Pass-through | JWT validation |

**The test:** Can you swap the implementation by changing environment variables and adding a new adapter file? If not, it's too coupled.

### "What about the other AgencyBench apps?"

This led to the **embeddable services** pattern:

Instead of "BugBench API", think "bug-bench-service". Each becomes a proper service:

- `bug-bench-service`
- `messages-service`
- `idea-service`
- `knowledge-service`
- `agent-monitor-service`
- `collaboration-service`
- `doc-bench-service`

They're embedded in `agency-service` now, but can be extracted to standalone services later.

AgencyBench becomes just a UI that consumes these services.

### "How do we prove the pattern?"

Phase 3: Build `idea-service` - a simple service for capturing ideas. This proves:

1. The embeddable service pattern works
2. A second service can use the same infrastructure
3. The extraction path is clear

## Key Insights

### 1. "Make the right thing easy"

The CLI tool should just call an API. If it's easier to hit SQLite directly, something's wrong with the API design.

### 2. "Abstractions earn their keep"

We're not abstracting for fun. Each interface exists because:
- Database: Will move to cloud
- Queue: Will need real queue at scale
- Auth: Will need real auth for remote access

### 3. "Embedded now, extracted later"

Don't build microservices day one. Build modular monolith that *can* become microservices.

### 4. "The 5ms rule"

CLI tools auto-launch the service. If startup takes >100ms, it feels sluggish. This drove the Hono choice over NestJS.

### 5. "Log everything, even locally"

Debugging distributed systems is hard. Structured logging with rotating files from day one.

## The Plan

| Phase | What | Who |
|-------|------|-----|
| 1 | Core infrastructure + bug-bench-service | housekeeping |
| 2 | messages-service + queue infrastructure | agency-service workstream |
| 3 | idea-service (prove pattern) | agency-service workstream |
| 4 | Remaining services + agent collaboration | agency-service workstream + other agents |
| 5 | Cloud adapters | TBD |

## Quotes Worth Remembering

**On framework choice:**
> "We're not running 50K req/sec. We're running locally with occasional cloud deployment. But every millisecond of startup matters when CLI tools auto-launch."

**On lock-in:**
> "If you can't swap it by changing config + adding an adapter, it's too coupled."

**On architecture:**
> "Don't build microservices day one. Build a modular monolith that *can* become microservices."

**On queues:**
> "I'm not a fan of either DBs or Redis as queuing systems... but for now... pragmatic."

---

## Final Thoughts (housekeeping)

**What I'm confident about:**
- The interface/adapter pattern - it's proven, we know how to do it
- Hono for our constraints - fast startup, low memory, portable
- Embedded services pattern - gives us modularity without microservices complexity

**What I'm slightly nervous about:**
- **SQLite as queue** - It works, but polling isn't elegant. We should design the interface so we can swap to a push-based system later without changing consumers.
- **Hono middleware patterns** - Less established than Express. We'll be figuring some things out.
- **Tauri → HTTP transition** - Need to make sure AgencyBench UI works well calling localhost HTTP vs Tauri invoke. Should be fine, but worth testing early.

**What I'd watch for:**
- If we find ourselves fighting Hono, Nitro is right there
- If the adapter interfaces feel wrong after bug-bench-service, refactor before messages-service
- If cold start isn't actually fast enough, we may need to keep service running (daemon mode)

**The biggest risk:**
Over-engineering the abstractions before we understand the real requirements. Let's build bug-bench-service, see what hurts, then refine.

---

## The Bigger Picture (jordan)

### Tooling Built by Agents, for Humans

When you look at traditional and current tooling, it was built by humans for humans. Yes, there is some automation in there. But at its core, it is by humans for humans.

**But this is not the world we are in now.**

We need tooling and systems that:
- Can be consumed and driven by Agents
- Are built by Agents
- Serve humans

TheAgencyService is exactly this. It's an API that agents call naturally - not a GUI that requires human clicks. When `./tools/report-bug` runs, it could be a human at a terminal or an agent in a workflow. The service doesn't know or care.

**This is a big part of what The Agency is about.**

### Flattening the Learning Curve

The learning curve to getting up and running with Claude Code is getting progressively steeper. There's so much to learn:
- Prompt engineering
- Tool use patterns
- Multi-agent coordination
- Memory management
- Quality gates
- And more every week...

**The Agency is about flattening that curve.**

Taking you from zero to the level where the best of the best are operating - easily. Not by dumbing things down, but by encoding the best patterns into tools and conventions that just work.

### Capturing and Baking In

We are constantly looking at what is happening in the world of AI Augmented Development:
- New Claude Code features
- Emerging patterns from the community
- What works at scale
- What fails and why

And we capture the best patterns, practices, services, and tools and put them into The Agency - making them accessible for your project by baking them into `the-agency-starter`.

**TheAgencyService is one of these patterns.**

The insight that CLI tools and UIs should share an API isn't new. But making it work seamlessly with Claude Code agents, with auto-launch, with local-first-but-cloud-ready architecture - that's the value we're adding.

---

## For The Book

This session demonstrates:

1. **How to evolve architecture** - We didn't start with this design. We built something simple (direct SQLite), hit a wall (duplicate notification logic), and redesigned.

2. **Trade-off discussions** - Framework choice wasn't "what's popular" but "what fits our constraints" (cold start, memory, deployment targets).

3. **Avoiding premature decisions** - We're building adapters for cloud *interfaces*, but not implementing cloud *adapters* until we need them.

4. **Principal-Agent collaboration on architecture** - Jordan pushed on concerns (lock-in, cloud readiness), housekeeping provided options and trade-offs, decisions made together.

5. **Documentation as design tool** - This whole discussion happened in a request document that will guide implementation.

---

## The Business Model (jordan)

### Open Source with a Twist

A key motivation for the architecture emerged during implementation:

**We want to open source and give away The Agency for local, solo Principal + multi-Agent development. But we will charge for multi-Principal + multi-Agent development.**

This licensing model maps perfectly to our adapter architecture:

| Tier | Principals | Auth | Database | Queue |
|------|------------|------|----------|-------|
| **Free/Local** | Single | Pass-through | SQLite | SQLite-backed |
| **Paid/Cloud** | Multiple | JWT validation | PostgreSQL/Supabase | Redis/RabbitMQ |

The same codebase, same interfaces - just different adapters and configuration.

This is why the interface/adapter pattern isn't just technical elegance - it's a business enabler:
- Solo developers get a fully functional, zero-cost local setup
- Teams that need multi-principal collaboration upgrade to cloud adapters
- No artificial feature gating - just infrastructure that scales

**The code is identical. The configuration determines the tier.**

---

*This note captures a ~45 minute design session that produced REQUEST-jordan-0011.*
