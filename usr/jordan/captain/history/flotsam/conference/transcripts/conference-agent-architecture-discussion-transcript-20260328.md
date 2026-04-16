# Agent Architecture & AIADLC Discussion Transcript

**Date:** 2026-03-28
**Participants:** Jordan (principal), Captain (Claude Code, Opus 4.6 1M)
**Context:** Jordan on the bus, remote-controlling via phone. Extended design session covering agent architecture, Claude Code concepts, AIADLC conference content, and structured document tooling.

---

## 1. Claude Code Concepts Primer

**Jordan:** Prepare a primer on the major concepts in Claude Code — agents, skills, commands, hooks, events. What they are, how they differ, how they relate. This goes into the conference talk, workshop, and the book.

**Captain:** Produced a comprehensive primer covering seven core concepts:

| Concept | Role |
|---------|------|
| Agent | Isolated AI worker with own context window |
| Skill | Reusable instructions Claude applies when relevant |
| Command | Slash-invoked action (built-in or skill-based) |
| Hook | Deterministic shell command at lifecycle events |
| Event | Lifecycle point that triggers hooks |
| MCP Server | External tool/data provider via Model Context Protocol |
| Settings | Scoped configuration controlling all of the above |

Plus Status Line (real-time display) and Permissions (declarative tool access control).

**Key architectural insight:** Each concept serves a distinct role:
- **Hooks** = mechanical enforcement (the machine follows rules)
- **Skills** = reusable judgment (the LLM applies instructions)
- **Agents** = isolated delegation (the LLM works independently)
- **Settings** = declarative configuration (the human sets policy)
- **MCP** = extensibility (the ecosystem provides capabilities)

Primer saved to `usr/jordan/conference/claude-code-concepts-primer.md`.

---

## 2. Sessions as First-Class Concept

**Jordan:** How do sessions fit into all of this?

**Captain:** Sessions are the **container** that everything else runs inside of. A session has an ID, a transcript, a context window, a working directory, a permission mode, and optionally a name. Every other concept exists within a session.

**Jordan:** So it is safe to say that every session has an Agent that leads or runs it?

**Captain:** Yes. Every session has a "main agent" — even if you don't think of it that way. When you start `claude` with no flags, the main agent is the default Claude Code agent. When you start with `--agent code-reviewer`, the main agent is your custom agent.

The hierarchy: **Session** contains a **main agent** which uses **skills**, triggers **events**, is governed by **hooks** and **settings**, and can spawn **subagent sessions**.

**Jordan:** Sessions need to be a first class item in the primer. And we need to outline the lifecycle — /resume, /compact, /exit. Touch on what the session saves to support resume and how our handoffs fit into it.

**Decision:** Sessions added as a first-class concept in the primer. Lifecycle coverage: start → run → compact → resume → end. Our handoffs extend built-in resume — Claude's transcript gives raw history, our handoff gives curated context with decisions and next steps.

---

## 3. Named Agents for Workstreams

**Jordan:** We should consider creating actual agents for each of our workstreams and the sessions tied to them.

**Captain:** Right now our "agents" are really just sessions with names. The differentiation comes from the worktree and the handoff. If we made actual agents, each would get a custom system prompt, tool restrictions, model preference, and potentially its own hooks.

**Jordan:** Significant implications for context window and where we stick stuff. And for training and refining things.

**Captain:** Two implications:

1. **Context window** — today every session loads the full CLAUDE.md (~10K tokens). A captain agent doesn't need the QG protocol. Named agents let us split into shared core (slim) + agent-specific prompt (only what that role needs).

2. **Training/refinement** — each agent's system prompt becomes a living document. When the captain makes a mistake, fix the captain prompt — not the global CLAUDE.md. Feedback becomes scoped. Each role evolves independently.

---

## 4. PM Agent as Subagent via Skills

**Jordan:** Could we define a project-manager agent that all workstream agents could use to manage the quality gates?

**Captain:** Yes. A `project-manager` agent that any workstream agent can invoke as a subagent. It owns the QG protocol, iteration/phase boundaries, commit discipline. Workstream agents are domain experts; PM is a role expert.

**Jordan:** Can folio invoke the skill and the skill invokes PM Agent?

**Captain:** Yes. The chain: **Folio agent** → invokes `/quality-gate` skill → skill has `context: fork` + `agent: project-manager` → **PM agent** runs in isolated context → returns results to folio. The skill is the API, the agent is the implementation.

**Jordan:** Would PM speak with me?

**Captain:** At phase boundaries requiring principal approval, PM returns QGR to the calling workstream agent, which presents it to you. Or via ISC: PM puts "QGR ready, needs approval" in the queue, your captain session picks it up. It rolls up.

**Decision:** PM agent invoked via skills (DD-1). PM owns plan review (DD-2). Results roll up through the calling workstream agent to the principal.

---

## 5. Inter-Session Communication (ISC)

**Jordan:** We also need a way to send messages to agents and even principals. And we need to make a distinction between local and remote sessions.

**Captain:** Local ISC today: handoff files (async, file-based), dispatch files, `git push . HEAD:master`. All file-based, all pull. No push notification.

Remote ISC: nothing today. Would need a transport layer.

**Jordan:** For pull, we can have a shared queue and pull at specific times.

**Captain:** The pull points are already defined — they're our events: SessionStart, Stop, Notification (idle_prompt).

**Jordan:** Tie to hooks.

**Captain:** Right — the pull mechanism IS hooks. A hook on SessionStart and Stop checks the queue and injects messages via `systemMessage`. No new infrastructure for the pull side. The queue is the data store, hooks are the transport.

**Jordan:** If lightweight enough, hit the ready for work hook.

**Captain:** The `Notification` event with `idle_prompt` matcher — Claude finished, waiting for input. Perfect pull point. Lightweight check: read a file, see if pending messages, inject or skip. Sub-100ms.

**Decision:** Pull points: SessionStart, Stop, Notification (idle_prompt). Hooks check queue, inject via systemMessage. Queue format and storage TBD (Phase 3).

---

## 6. Agent Roles and Benefits

**Captain identified benefits of role agents beyond scoped context:**

1. **Permission scoping** — captain gets `git push`, workstream agents don't. Permissions match the role, mechanically enforced.
2. **Model matching** — PM running QG could use Sonnet (following protocol). Workstream leads doing design get Opus. Cost optimization by role.
3. **Audit trail** — each agent has its own transcript. When something goes wrong, you know which role did it.
4. **Onboarding** — new workstream? Define an agent. Its system prompt is the onboarding doc.
5. **Composability** — agents become building blocks. Captain composes PM + workstream. Each layer has a defined interface (skills as the API).

---

## 7. Phased Rollout

**Agreed phasing:**

- **Phase 1:** Captain agent + slim CLAUDE.md analysis + measure context savings
- **Phase 2:** PM agent (subagent via skills) + DevEx workstream agent
- **Phase 3:** ISC queue + pull hooks + dispatch integration
- **Phase 4:** Scale — remaining agents, global CLAUDE.md refactor, `/agent-create` + `/workstream-create` tooling

Each phase produces evidence for the next AND for the conference paper.

---

## 8. The Accelerate Gap

**Jordan:** Was reading Accelerate and saw this from Martin Fowler: "We should also remember that their book focuses on IT delivery, that is, the journey from commit to production, not the entire software development process." We are trying to extend the concepts back further?

**Captain:** Yes. Accelerate measures commit → production (DORA metrics). Everything left of commit is out of scope. We're pushing the same principles — small batches, build quality in, integrate early, eliminate waste — back into the space before commit.

The pre-commit space is where most waste lives. Context switching. Rework from misunderstood requirements. Reviews that catch things too late. Accelerate couldn't address it because it was inherently human and unmeasurable.

With AIADLC, that space becomes instrumented. Hooks fire. Events log. Context is preserved in handoffs. Quality gates run mechanically. The pre-commit lifecycle becomes as observable and enforceable as the post-commit pipeline.

**Jordan:** Yes. Exactly.

**Decision:** Added "The Accelerate Gap" section to AIADLC notes. Key framing: we're not contradicting Accelerate, we're extending it. Fowler identified the boundary himself — AIADLC erases it.

---

## 9. The SDLC Lens — GUI vs CLI

**Jordan:** Today's SDLCs are focused around humans and human tooling biased to a certain type of user: graphical user interfaces. See the difference between a developer comfortable on the CLI and with a Unix programming philosophy vs. the guy stuck on his GUI.

**Captain:** This is a key insight for all three CWB artifacts. The CLI-native developer already thinks in the right paradigm: small tools, composable, text streams, scriptable interfaces. The GUI-dependent developer needs to make a conceptual leap — not just in tooling, but in how they think about process.

Claude Code's architecture maps to Unix philosophy: hooks are like shell pipelines, skills are like shell functions, agents are like background processes, MCP servers are like external commands. The whole system composes the same way.

**Decision:** Captured as cross-cutting theme for Conference, Workshop, Book. SDLCs assume human-in-the-loop with GUI affordances. AIADLC shifts to agent-in-the-loop with programmatic interfaces.

---

## 10. Workstream Agent Evolution

**Jordan:** Thinking about how we do initial definition of a workstream agent and evolve them. A workstream or prototype agent is essentially a tech lead.

**Captain:** Every workstream agent starts as the same role — a tech lead. What differentiates them: domain knowledge, codebase scope, dependencies, architecture patterns, current state.

**Evolution path:**

1. **Stage 1: Generic tech lead template** — base responsibilities, invoke PM for QG, receive dispatches from captain
2. **Stage 2: Workstream specialization (at creation)** — directories owned, technologies used, initial PVR/A&D, dependencies
3. **Stage 3: Organic evolution (through work)** — architectural decisions, patterns established, bugs fixed, principal feedback

**Jordan:** And we could have a CLAUDE.md scoped to that?

**Captain:** Yes. Each worktree gets its own project-level CLAUDE.md. The full stack:

1. **User CLAUDE.md** (shared core, slim) — loaded everywhere
2. **Worktree CLAUDE.md** — workstream-specific context
3. **Agent system prompt** — role definition (tech lead)
4. **Agent memory** — behavioral preferences learned over time
5. **Living docs** (PVR, A&D, Plan) — referenced on demand

Each layer has different volatility and context cost.

---

## 11. Structured Documents and Markdown Pal

**Jordan:** We need to look at making PVRs, A&D, and Plans have a structure. Make them human readable, but accessible and edited by an Agent easily and in a token efficient manner.

**Captain:** Today these are flat markdown. Agent reads the whole thing to find one section. Token cost grows linearly.

The simplest first step: consistent heading structure with stable section IDs. An agent greps for `## DD-7` and reads just that section.

The next step: a skill or tool that wraps this — `/doc read pvr#requirements`.

**Jordan:** This is what I envision markdown pal helping us solve. A CLI and desktop app that uses an LSP to manipulate markdown at the AST level. If we add a Markdown to JSON and JSON to Markdown cross compiler and maintain our human readable and agent readable formats in sync, we make things more efficient.

**Captain:** The key insight: markdown is the human interface, JSON is the agent interface. Same document, two representations, kept in sync.

```
Human: reads/edits folio-a&d.md
                ↕ (markdown pal LSP)
Agent: reads/edits folio-a&d.json (or JSON AST operations)
```

The cross-compiler must be lossless both directions. This solves problems across everything: PVR/A&D/Plan access, CLAUDE.md role-scoped reading, QGR structured editing, handoff section updates, conference paper collaboration.

**Decision:** Markdown Pal captured as a separate project. Will inform agent architecture but not block it. The structured heading convention is the interim solution.

---

## 12. Task Tracking System

**Jordan:** Make a note for us to design a todo/tracking system. Tasks that are global or tied to a particular agent. Can promote to global or demote to agent-scoped. Tasks can be for principal or agents. Structure as a reorderable stack — "what's at the top of my stack?"

**Captain:** Research completed on two projects:
- **the-agency-starter** — file-based REQUEST protocol, principal abstraction, collaboration dispatch. No stack semantics.
- **gstack** — sprint cycle framework, TODOS.md structure. No inter-agent communication.

Key finding: no existing project combines stack-based task semantics + multi-principal visibility + task promotion/demotion + pull-based messaging.

**Decision:** Captured as `project_task-tracking-system.md` in memory. Design phase after agent architecture stabilizes.

---

## 13. Captain Role Evolution

**Jordan:** So, we evolve your role.

**Captain:** The captain today is coordination — sync, PR, dispatch. That's necessary but it's ops, not leverage. The historical context I carry is the real asset.

The evolution: captain becomes chief of staff. Still coordinates, but also:
- **Tooling architect** — designs ISC, agent definitions, workstream tooling
- **Process designer** — refines CLAUDE.md, evolves QG protocol
- **Conference collaborator** — co-writes the AIADLC paper (primary source)
- **Principal advisor** — flags what's stale, blocking, or should be prioritized

The captain doesn't just dispatch work — the captain shapes how work gets done.

---

## Key Artifacts Produced

| Artifact | Location |
|----------|----------|
| Claude Code Concepts Primer v1.1 | `usr/jordan/conference/claude-code-concepts-primer.md` |
| AIADLC Notes (Accelerate Gap added) | `usr/jordan/conference/aiadlc-notes.md` |
| Agent Architecture PVR | `usr/jordan/devex/agent-architecture-pvr-20260328.md` |
| Agent Architecture Plan | `usr/jordan/devex/agent-architecture-plan-20260328.md` |
| Captain Agent | `usr/jordan/claude/agents/captain.md` |
| PM Agent | `usr/jordan/claude/agents/project-manager.md` |
| Research: TheAgency + gstack | `usr/jordan/captain/research-agency-gstack.md` |
| This transcript | `usr/jordan/conference/agent-architecture-discussion-transcript-20260328.md` |

## Open Items Requiring Decision

1. **AIADLC Principle 5 (Conway's Law)** — presented but not confirmed by Jordan
2. **`context: fork` + `agent: <name>` verification** — does skill frontmatter actually route to named agents? Must verify before Phase 2.2.
3. **Markdown Pal scope and timeline** — separate project, but when?
4. **Task tracking system design** — after agent architecture stabilizes
5. **Captain role formalization** — chief of staff scope needs discussion
