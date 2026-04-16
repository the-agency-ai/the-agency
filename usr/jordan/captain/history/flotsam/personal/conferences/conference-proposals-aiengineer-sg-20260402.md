# AI Engineer Singapore 2026 — Talk Proposals

**Submitter:** Jordan Dea-Mattson
**Company:** OrdinaryFolk
**Role:** Head of Product and Technology
**Location:** Singapore

---

## Proposal 1: Towards an AIADLC — Rewriting the Software Development Lifecycle for AI Agents

**Track:** Software / Leadership
**Format:** 25-minute talk

### Abstract

We spent over 50 years figuring out how to build software. We codified our thinking into SDLCs, methodologies, and ceremonies — Waterfall, Agile, XP, Kanban, DevOps. We know what works: small batch sizes, continuous integration, code review, test-driven development, separation of concerns.

Now AI agents are developers. Not assistants. Developers. They write code, run tests, review each other's work, and ship to production. The entire premise of our methodologies — that humans are the bottleneck — just changed.

What stays? Small batch sizes — yes. Version control — yes. What changes? Code review becomes multi-agent review with confidence scoring. Sprint planning becomes plan-mode with principal approval at boundaries. What gets thrown out? Standup meetings — agents don't need them. Jira tickets — agents communicate via dispatches and handoffs. Pair programming — agents work in parallel, not in pairs.

This talk presents TheAgency, an AI-Augmented Development Lifecycle (AIADLC) framework built on Claude Code, where multiple AI agents work as first-class developers coordinated by human principals. I'll share the methodology we've developed — the enforcement triangle (tool + skill + hookify rule), the discussion protocol (1B1), quality gates with multi-agent review, session lifecycle management, and cross-agent communication via dispatches and handoffs.

This isn't theory. We ship production code this way daily with a fleet of 4-9 concurrent agent sessions.

### Key Takeaways

1. The AIADLC is the successor to Agile — designed for human principals directing AI agent developers
2. The enforcement triangle (tool + skill + hookify) is how you make agents follow process
3. Multi-agent review catches more than human review — but you need confidence scoring to filter noise
4. Session lifecycle (resume/sync/end) is the new standup

### Speaker Bio

Jordan Dea-Mattson is Head of Product and Technology at OrdinaryFolk, a Singapore-based healthtech company. He's been leading product and engineering organizations and building and delivering software for nearly four decades across both tech multinationals like Apple, Adobe, Indeed, and Yahoo, as well as a host of startups both in Singapore and Silicon Valley. He is an advisor to a number of organizations including Singapore Polytechnic, Open Government Products, ASTRNT, and Menlo Research on AI Augmented Development, AI Transformation (AIX), and engineering practices. Day-to-day, he leads a product development and delivery team where AI agents outnumber humans at least 6:1, while also building hands-on daily using AI Augmented Development. Beyond his day job he is building his passion project TheAgency — an open-source framework for when developers and AI agents work together effectively — while validating it works in the trenches at OrdinaryFolk (15 product features, over 2 million lines of code, 2 weeks).

---

## Proposal 2: AI Augmented Development — An Adoption Case Study from Singapore

**Track:** Leadership
**Format:** 25-minute talk

### Abstract

In January 2026, OrdinaryFolk was a small Singapore healthtech startup with a handful of developers building a patient-facing platform. By April 2026, we had a monorepo with a NestJS backend, five Next.js frontends, a shared UI package, a prototype system, deployment infrastructure across Fly.io, Vercel, and Cloudflare — and the majority of it was built by AI agents.

This is the adoption story. Not the hype. The reality.

I'll walk through the timeline: starting with a single Claude Code session doing ad-hoc tasks, evolving to a structured methodology with PVRs and architecture documents, then scaling to multiple concurrent agent sessions on git worktrees with a captain coordinating via dispatches. I'll show what worked (quality gates, the enforcement triangle, mechanical enforcement over prose), what failed (agents ignoring handoff tools, settings files getting clobbered by concurrent sessions, AppleScript targeting the wrong terminal tab), and what surprised us (agents need the same onboarding as junior developers — clear processes, guardrails, and yes, threatened consequences involving cute attack kittens).

Concrete metrics: 3,400+ tool calls per day across 4 agents, 108 issues identified via transcript mining, 0.4% skill utilization rate (the gap between building tools and agents actually using them), and the enforcement pattern we built to close that gap.

This talk is for engineering leaders considering AI-augmented development and wanting to know what it actually looks like in production — not in a demo.

### Key Takeaways

1. Adoption is a methodology problem, not a technology problem — you need an AIADLC
2. Mechanical enforcement beats documentation — agents forget prose, they can't bypass hooks
3. Multi-agent development requires infrastructure: session lifecycle, worktree sync, cross-agent dispatches
4. Metrics matter: telemetry showed us agents ignored 99.6% of available skills

### Speaker Bio

(Same as above)

---

## Proposal 3: It's the Context (and Tokens), Stupid! — Techniques for Context Conservation and Token Economies

**Track:** Software
**Format:** 25-minute talk

### Abstract

Every AI-powered development tool hits the same wall — and it's not compute, it's not latency. It's two resources you're burning simultaneously and can't get back:

**The Context Window** — your agent's working memory. You start a session, load codebase instructions, read files, run tools, and suddenly you're at 84% utilization. Compaction fires and strips half your conversation. Your agent's mental model is gone.

**Inference Tokens** — your bill. Every input token costs money. Every output token costs more. Run 4 agent sessions for 5 hours and you've burned through serious token volume. Tool output is 62% of all calls — that's tokens flowing through the meter for `git status` output nobody reads.

These are the two critical resources and costs you need to manage in AI-augmented development. Context window is a capacity constraint. Inference tokens are an economic constraint. Optimizing for one without the other is half the picture.

This talk presents battle-tested techniques for managing both, developed while running 4-9 concurrent Claude Code agent sessions daily:

**Context conservation:** The two-file CLAUDE.md architecture (`@import` for methodology separation), ref-injection hooks that load documentation on-demand instead of at startup, tool output standards (3 lines to stdout, verbose to log files), and the handoff primitive for surviving compaction.

**Token economics:** Telemetry-driven analysis of where tokens go. Skill design that minimizes context pollution. Subagent isolation to protect the main context window. The difference between "I read the whole file" and "I read lines 40-60" — and what that costs at scale.

**Session lifecycle as resource management:** Why `/session-resume` and `/session-end` are resource management tools, not just convenience. How handoffs, dispatches, and flag queues offload state to files instead of burning context. The compaction survival pattern.

Real numbers from production: 1M token context windows, 5-hour sessions, $7.86 per session, 37% context remaining after heavy tool use, and what we do about it.

### Key Takeaways

1. You're managing two resources: context window (capacity) and inference tokens (cost) — optimize both
2. Tool output is the biggest consumer of both — design tools for efficiency (3 lines, not 300)
3. Ref-injection (load docs on demand) beats loading everything at startup — saves context AND tokens
4. Handoffs and dispatches are resource offloading mechanisms — move state to files, not context

### Speaker Bio

(Same as above)

---

## Proposal 4: We Need to Talk If We're Gonna Work Together — An Inter-Session Communication Protocol for Claude Code

**Track:** Software
**Format:** 25-minute talk

### Abstract

You have six AI agent sessions running in parallel. One builds the backend. One builds the frontend. One manages infrastructure. One coordinates. They're all working on the same codebase, on different git branches, in different terminal tabs.

How do they talk to each other?

When we started, the answer was: they don't. Each Claude Code session was an island. No inbox, no message bus, no shared state beyond git. The human principal was the relay — manually telling each agent what the others had done. That bottleneck killed the 6:1 agent-to-human ratio we were aiming for.

This talk traces the evolution of our Inter-Session Communication Protocol (ISCP) from files on disk to a real messaging system — and what we learned at each stage:

**Stage 1 — Files on disk.** Dispatches (async task assignments with frontmatter lifecycle tracking), handoffs (session continuity primitives that double as inter-agent context transfer), and flag queues (JSONL observation capture). Simple, reliable, git-native. But no notification — agents only discovered messages on session restart.

**Stage 2 — Git as transport.** Worktree sync on SessionStart: auto-merge master, copy settings, run sandbox-sync, report what changed. Every agent starts every session current with the fleet. Dispatches flow via `git show master:` without merging. Cross-branch communication solved. But still session-boundary only.

**Stage 3 — Cross-repo transport.** Dispatches cross local repo boundaries via GitHub. monofolk/captain sends a dispatch to the-agency/captain via a committed file and a PR. Same protocol — frontmatter lifecycle, resolution tracking — but git push as the transport. The same tools work across teams, across repos, across organizations.

**Stage 4 — "You Have Mail."** The missing piece: real-time notification. When a dispatch lands mid-session, the receiving agent gets signaled without restarting. A lightweight messaging layer that says "check your dispatches" without interrupting flow. Agents respond to dispatches in minutes, not at the next session boundary.

I'll demo the full lifecycle live: captain creates a dispatch → it flows to a worktree agent mid-session → agent reads, resolves, and reports back → captain picks up the resolution → then the same flow cross-repo to a different team's agent. Zero human relay. Real-time. Cross-repo.

### Key Takeaways

1. Multi-agent communication is an evolution: files → git transport → cross-repo → real-time messaging
2. Start simple (files on disk, git as transport) — reliability beats sophistication at every stage
3. "You Have Mail" is the unlock — session-boundary-only communication limits agent autonomy
4. The same protocol (dispatches + frontmatter lifecycle) works within a repo, across repos, and across organizations

### Speaker Bio

(Same as above)

---

## Package Note

All four talks draw from the same body of work — TheAgency AIADLC framework and the OrdinaryFolk adoption experience. They can be presented independently or as a series. Happy to adjust format (workshop, panel, lightning talk) based on the program's needs.

Contact: jdm@devopspm.com, jordan@ordinaryfolk.health
Twitter/X: @jordandm (personal), @agencygroupai (TheAgency)
GitHub: @jordan-of (OrdinaryFolk), @jordandm (personal), @the-agency-ai (TheAgency)
LinkedIn: linkedin.com/in/jordandeamattson
