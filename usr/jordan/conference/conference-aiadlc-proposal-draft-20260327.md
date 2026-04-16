# Towards an AIADLC: AI Augmented Development Life Cycle

## Call for Papers Proposal — DRAFT v0.1

### Title

Towards an AIADLC: Rethinking the Software Development Life Cycle for AI Augmented Development

### Authors

Jordan Dea-Mattson, OrdinaryFolk

### Abstract

The software industry spent fifty years developing SDLCs and methodologies — Waterfall, Agile, XP, Lean, DevOps — each capturing hard-won lessons about how humans build software. We now face a parallel challenge: developing equivalent frameworks for AI Augmented Development, where AI agents work alongside and sometimes independently of human developers. The timeline is compressed from decades to months.

This paper examines which principles from traditional SDLCs survive the transition to AI augmented development, which must be rewritten, and which should be discarded entirely. We draw on direct experience operating a multi-agent development environment with long-lived worktrees, automated quality gates, and AI-coordinated workflows to propose the foundations of an AI Augmented Development Life Cycle (AIADLC).

### The Central Question

We have fifty years of accumulated wisdom about building software. How much of it transfers to a world where:

- Multiple AI agents work in parallel on different parts of a codebase
- A human principal coordinates rather than directly implements
- Code review is performed by AI agents reviewing AI-generated code
- The development pace is measured in hours, not sprints
- Context loss between sessions is a first-class engineering problem
- The cost of iteration approaches zero but the cost of coordination increases

### Key Arguments

#### 1. What Stays (Adapted)

**Small batch sizes — yes, probably stays.**

The Lean/Agile insight that small, frequent deliverables reduce risk applies even more in AI augmented development. When agents can produce thousands of lines in a session, the temptation is to batch large. But the coordination cost of large batches is higher with multiple agents — merge conflicts, cross-contamination, divergence. Small batches with mechanical verification (quality gates, automated tests) remain the correct approach.

**Iterative delivery with feedback loops.**

The Plan → Build → Verify → Deliver cycle survives, but the cadence changes. Iterations that took days now take hours. The feedback loop tightens — but the need for structured iteration (not just "keep coding") becomes more important, not less. Without iteration boundaries, AI agents produce unbounded work that's impossible to verify.

**Living documents.**

Requirements, architecture, and plans must evolve through implementation. This is more true with AI agents than with humans, because agents lose context between sessions. The living documents become the persistent memory — the handoff mechanism between sessions and between agents.

#### 2. What Gets Rewritten

**Code review.**

Does traditional code review make sense when AI writes the code and AI reviews it? We argue it does — but the purpose shifts. Human code review catches "does this match what I intended?" AI code review catches "is this correct, secure, and consistent?" The review process becomes multi-layered: AI agents review for correctness, humans review for intent alignment. The old model of one human reviewing another human's code is replaced by a structured agent review protocol with confidence scoring and dispute resolution.

**Quality gates.**

The manual QA phase is replaced by mechanical, automated quality gates that run at every iteration boundary. The gate includes parallel AI review agents, red-green test cycles, and zero-tolerance policies. The key shift: quality gates become the commit boundary, not a separate phase. You don't commit until the gate passes. This is more rigorous than most human processes, not less.

**Session management and handoffs.**

Traditional SDLCs don't address "what happens when the developer loses all context." With AI agents, this is every session. The AIADLC must treat context loss as a first-class concern: handoff protocols, persistent memory, living documents, and session recovery become core development practices, not afterthoughts.

**Coordination models.**

The "team standup" is replaced by mechanical synchronization. A captain agent coordinates work across worktree agents, merges their output, creates PRs, and dispatches review findings. The coordination is continuous, not daily. The AIADLC must define coordination patterns: who owns what, how work flows from agents to integration to deployment.

#### 3. What Gets Thrown Away

**Estimation.**

Story points, velocity, sprint planning — these assume human-paced development where estimation helps allocate scarce human time. When agents can attempt any task at near-zero marginal cost, the question shifts from "how long will this take?" to "what should we attempt next?" Planning becomes about priority and sequencing, not estimation.

**Manual testing as a phase.**

Testing is not a phase — it's embedded in every iteration via the quality gate. The "QA sprint" disappears. What remains is the design of test strategies, which is a planning activity, not an execution phase.

**The solo developer model.**

Traditional methodologies assume one developer working on one thing at a time. AI augmented development is inherently parallel — multiple agents, multiple worktrees, concurrent work streams. The AIADLC must assume parallelism as the default, not the exception.

### Proposed AIADLC Framework (Sketch)

```
Discovery → Discussion → Living Documents (PVR + A&D) → Plan (Phases × Iterations)
    ↕              ↕              ↕                              ↕
  Human          Human +       Persistent                   Agent execution
  driven         AI dialog     across sessions              with QG at each boundary
```

**Phases of the AIADLC:**

1. **Discovery** — Human-driven. Identify the problem, gather context, define scope.
2. **Discussion** — Human + AI dialog. Explore requirements, constraints, trade-offs. No jumping to implementation.
3. **Architecture** — Living document. Technical decisions, design rationale. Evolves through implementation.
4. **Planning** — Break work into phases and iterations. Each iteration has a clear deliverable and quality gate.
5. **Execution** — Agents implement. Quality gate at every iteration boundary. Mechanical verification.
6. **Coordination** — Captain integrates work. Sync, merge, review, dispatch. Continuous, not periodic.
7. **Delivery** — PRs, deployment, release. Automated pipeline with human approval gates.
8. **Reflection** — What worked, what didn't. Update the framework itself.

**Cross-cutting concerns:**

- **Context persistence** — Handoffs, memory, living documents
- **Quality enforcement** — Mechanical gates, not process discipline
- **Coordination** — Captain pattern, sync protocols, divergence guards
- **Trust boundaries** — Where human approval is required vs. agent autonomy

### Evidence Base

This paper draws on direct experience building and operating an AIADLC at OrdinaryFolk, a healthcare technology company. Specific evidence includes:

- 10 months of multi-agent development across 9 concurrent workstreams
- 50+ PRs shipped through an AI-coordinated captain workflow
- A quality gate protocol that caught 200+ issues across implementation phases
- A divergence crisis caused by mismatched git workflows, diagnosed and fixed in a single session through structured discussion and iterative design (3 review rounds, 22 findings)
- The evolution of handoff protocols from ad-hoc notes to structured, hook-triggered documents
- The development of mechanical enforcement patterns (hookify rules, permission guards, divergence detection) to replace process discipline

### Why Now

The tooling has reached a threshold. AI coding assistants are no longer autocomplete — they are agents that can plan, implement, test, and review. The industry needs frameworks for working with these agents, not just using them. The AIADLC is not a theoretical exercise — it's an operational necessity for any team adopting AI augmented development at scale.

### Contribution

This paper contributes:

1. A taxonomy of SDLC principles and their applicability to AI augmented development
2. A proposed framework (AIADLC) grounded in operational experience
3. Specific patterns for quality gates, coordination, context persistence, and mechanical enforcement
4. An argument for why the compressed timeline (months, not decades) demands deliberate framework development now

### Format

Full paper (8-12 pages) or extended abstract + talk, depending on venue requirements.

---

_This is a draft proposal. Refine structure, sharpen arguments, add specific data points before submission._
