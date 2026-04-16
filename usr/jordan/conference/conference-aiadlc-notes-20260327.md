# AIADLC — Working Notes

## Core Thesis: "These Go to Eleven"

Three beats:

1. **We know what to do.** Fifty years of SDLCs gave us the principles. They're right.
2. **We haven't been doing it.** Red-green testing, continuous integration, small batches, quality built in, opportunistic refactoring — we preach them all, practice maybe half, practice well maybe a quarter.
3. **With AIADLC, we take it to 11.** Not new principles. The SAME principles, finally achievable, and then cranked past what humans could sustain.

**Empirical process control is THE foundational insight** (Schwaber/Scrum). It survives and strengthens. Traditional Agile said it was empirical but 2-week sprints meant you could explore 2-3 hypotheses per month. The feedback loop was empirical in theory, predictive in practice — you couldn't afford to throw away a sprint's work.

With an Agency (human + agents), the iteration cost approaches zero. You CAN throw away an iteration. You CAN explore approaches in parallel. The empirical process becomes actually empirical for the first time.

We knew. We didn't. Now we do. And then some.

## Terminology

- **Iteration**: a reviewable, testable, deployable increment of work. Building it gives you knowledge and insight to move forward — revising as required.
- **Phase**: a reviewable, testable, deployable increment that can be exposed to customers/consumers for feedback. Something you can integrate with other systems.
- **Agency**: a human principal + their squad of AI agents. The unit of adoption and practice.
- "Sprint" abandoned — in most minds it means 2 weeks. A Phase might be a few hours.

## Principle Discussion

### Principle 1: Small batch sizes reduce risk

**Source:** Lean, Agile, Accelerate (deployment frequency as key metric)

**Verdict:** Survives. Maps directly to Iterations and Phases.

The definition of "small" is NOT tied to time — it's tied to the increment's character:

- Iteration = smallest unit that gives you knowledge to proceed
- Phase = smallest unit that can receive external feedback

The SCALE shifts (hours not weeks) but the PRINCIPLE is unchanged. And because iteration cost is near-zero, you can make batches even smaller than traditional development allowed.

**Evidence:** Yesterday's divergence fix. We shipped 10 PRs in one session. Each was a scoped extraction — one worktree's work. Small batches with mechanical delivery.

---

## Research Queue

- [ ] ePubs from Jordan's Kindle (Scrum, DevOps Handbook, Lean SD, Refactoring, Accelerate, Team Topologies)
- [ ] The Phoenix Project (Gene Kim) — the narrative that made DevOps principles accessible. Novel format showing principles in action.
- [ ] IT Revolution (itrevolution.com) — Gene Kim's publisher/community. Talks, articles, excerpts bridging all these books.
- [ ] Martin Fowler blog — index-first approach, then selective reads on relevant topics
- [ ] Scrum Guide (free PDF): https://scrumguides.org/docs/scrumguide/v2020/2020-Scrum-Guide-US.pdf
- [ ] Research saved to: `usr/jordan/conference/references/book-research.md`

### Principle 2: Build quality in, don't inspect it in

**Source:** Deming, Lean (Poppendieck), Accelerate

**Verdict:** The distinction collapses. When inspection is near-zero cost and the fix cycle is immediate, inspection IS the build process. What replaces the distinction is: **mechanical enforcement at every boundary.**

**Key sub-points:**

**Red-green-refactor finally achieved.** TDD's red-green cycle has been the ideal for 20+ years. Almost no human team does it consistently — the discipline required is too high under deadline pressure. With agents + mechanical enforcement in the quality gate, we get it done. The agent writes a bug-exposing test (must fail), then fixes (test must pass). Still challenging — agents want to jump to the fix — but mechanically enforced.

**This is a principle that was always right but practically unachievable with humans.** AI augmented development doesn't change the principle — it changes the achievability.

**The Andon Cord is real again.** In Scrum, if the principal doesn't like the test coverage, they can raise it but the Sprint is over. In AIADLC, the principal can say "Stop. Go back. Rework those tests. Not clearing." And the agent does it. Right now. Not next Sprint. The Andon Cord — Toyota's "stop the line" — actually works because stopping doesn't cost a Sprint's worth of schedule.

**IQG vs PQG — two scales of quality gate:**

|            | IQG (Iteration)   | PQG (Phase)                      |
| ---------- | ----------------- | -------------------------------- |
| Scope      | Iteration changes | Entire project codebase          |
| Approval   | Auto-commit       | Principal must approve           |
| Squash     | No                | Yes (iterations → single commit) |
| Landing    | Stays on branch   | Lands on master                  |
| Equivalent | —                 | Sprint Review                    |

**Ceremonies become artifacts (the proof):**

| Scrum Ceremony       | AIADLC Process                 | Artifact                                            |
| -------------------- | ------------------------------ | --------------------------------------------------- |
| Sprint Planning      | Pre-Phase Review               | Updated PVR + A&D + Plan with agent review findings |
| Daily Standup        | `/sync-all`                    | Sync report                                         |
| Sprint Review        | PQG                            | QGR + principal approval                            |
| Sprint Retrospective | Bridges PQG → Pre-Phase Review | Updated process + enforcement tooling               |

**The retrospective is continuous, not periodic.** We don't wait for a Sprint to end to improve process. When the principal catches a process gap mid-session — in ANY agent session — they flag it, we define the change, and we build tooling to enforce it. How many times has Jordan caught something, flagged it to the captain, and we've defined a process change and built enforcement in the same session? The hookify rules, the divergence guard, the post-merge command — all came from mid-session observations, not retrospectives.

**Critical insight: even with agents, process and practices without enforcement in code is not optimal.** Prose rules get forgotten. Memory entries drift. CLAUDE.md conventions get skipped under pressure. The practices that stick are the ones with mechanical enforcement — hookify rules, quality gate steps, pre-commit hooks, divergence detection. If a practice matters, encode it. If you can't encode it, it will decay.

---

## Cross-Note: Transformation / Adoption

**A human + their squad of agents (an "Agency") can adopt practices internally without requiring buy-in from other humans.**

This is a fundamental difference from traditional SDLC adoption. In traditional orgs, adopting a new methodology (Agile, XP, Lean) requires convincing the whole team — or at least a critical mass. The adoption cost is high because practices cross human boundaries: pair programming needs two humans, CI needs the whole team to integrate, code review needs reviewers.

With an Agency (one human + their agents), the human IS the team. They can:

- Adopt quality gates without anyone else agreeing to quality gates
- Use living documents without changing the team's doc standards
- Run multi-agent parallel review without needing human reviewers
- Implement mechanical enforcement (hookify, divergence guards) unilaterally
- Change their development flow (phases, iterations, QGRs) without a team retrospective

**The adoption boundary shrinks from "the team" to "one person."**

This has implications:

1. **Adoption speed** — practices can be adopted in hours, not quarters
2. **Experimentation** — one Agency can try a practice without risk to others
3. **Evidence gathering** — the Agency produces evidence (test counts, issue counts, PRs shipped) that can convince others
4. **Organic spread** — successful practices spread by example, not by mandate (this is the sandbox principle)
5. **No consensus required** — the biggest blocker to SDLC adoption is getting everyone to agree. Agencies sidestep this entirely.

**But:** inter-Agency coordination DOES require shared practices. The captain pattern, sync-all, PR conventions — these cross Agency boundaries. The AIADLC needs to distinguish between:

- **Intra-Agency practices** — adopted unilaterally (quality gates, living docs, handoffs)
- **Inter-Agency practices** — require coordination (sync protocols, PR conventions, shared infrastructure)

This maps to Team Topologies' interaction modes: collaboration vs. X-as-a-Service. Intra-Agency is autonomous. Inter-Agency needs explicit contracts.

---

## Principle Candidate: Code Review Shifts from Gatekeeping to Enabling

Traditional code review became inspection theater — a gate that mostly rubber-stamped. The ceremony existed but the diligence didn't.

In AIADLC, code review transforms:

**Pre-merge:** The quality gate handles correctness mechanically. No human reviewer needed for "is the code correct?" — agents + red-green cycle + mechanical enforcement handle that.

**Post-merge:** Human review becomes ENABLING, not GATEKEEPING. A different principal (not the author) reviews what landed. Four tiers:

1. **Acknowledge** — awareness: "I see it landed"
2. **LGTM** — active approval after scanning
3. **Let's look at it more** — deeper review (bugs, opportunities, learning)
4. **Andon** — stop the line (emergency only)

The reviewer directs an agent from their own Agency. Findings go through discussion protocol. Author can reject, address, or delegate. It's collaborative, not adversarial.

**Key insight:** "Let's look" isn't just about finding problems. It's also:

- Spotting opportunities for improvement/refactoring
- Understanding code so the reviewer can use/build on it
- Identifying patterns worth spreading across the codebase

**Pre-PR QG scoping:** QG runs on integrated master, not per-PR. PRs are just packaging. The quality was verified on the integrated state before PRs were carved.

**AIADLC flow:**

1. Agents work on worktrees
2. `/sync-all` merges to master
3. QG runs on master (integrated state)
4. Carve into scoped PRs
5. Principal gives explicit disposition per PR
6. Push and merge per disposition

This is CI taken further: Fowler's "integrate at least daily" → "integrate continuously, verify integrated state, then ship."

**Platform independence:** The review runs locally in the Agency — not on GitHub. GitHub is dumb transport (hosts repos, PRs). The intelligence is in the Agency. You're not locked into any platform's opinion about how review should work.

---

### Principle 3: Integrate early, integrate often

**Source:** XP, Fowler CI article, DevOps First Way, Accelerate

**Verdict:** Survives, cranked to 11. Two cadences.

- **Local integration** (sync-all): continuous, mechanical, every 30 minutes
- **External integration** (PRs to origin): periodic, principal-directed, disposition-gated

**Take it to 11:** CI at 6 was integrate daily. CI at 11 is integrate every 30 minutes, QG on the integrated state, ship PRs same day.

**Preview from day one.** Preview is integration's physical manifestation — you can't verify integration without running it. Traditional setup took weeks. Agency builds preview infrastructure alongside the product.

**Evidence:** The 337-commit divergence was a failure of integration discipline at the external layer. The fix was mechanical enforcement at both levels.

---

### Principle 4: Eliminate waste

**Source:** Lean (Poppendieck), Toyota Production System

**Verdict:** Survives. All seven wastes re-examined. One NEW defining waste.

**The seven wastes at 11:**

1. Partially done work → iterations are hours, sync-all keeps WIP flowing
2. Extra features → discussion protocol + PVR prevent freelancing
3. **Relearning → THE defining waste of AIADLC** (see below)
4. Handoffs → within Agency, artifacts ARE the handoff. Zero information loss.
5. Task switching → agents don't context-switch. One agent, one project.
6. Delays → QG eliminates waiting for review. Auto-commit. Local CI. Preview from day one.
7. Defects → caught at iteration boundary by QG. Red-green proves the fix.

**Context is everything.** The Transformer paper said "attention is all you need." For development: context is all you need. People start fresh agents every day — that's like firing your team every evening and hiring new people every morning.

**Long-running agents.** The agents are persistent team members, not disposable sessions. The folio agent has been working on folio for weeks. Deep context — architecture, phase history, code patterns. The session boundary is a coffee break, not a termination.

**The daily cycle:** handoff → compact → exit → resume. Context externalized into artifacts. Bus factor: read the handoff. 30 seconds to productive.

**Upgrades without context loss.** New Claude Code version drops, agent gains capabilities, keeps project knowledge. Like training over the weekend — come back with new skills AND existing context.

**Prototype as Spec.** Demo beats deck, code beats plan. What looks like waste (building to explore) is the most efficient communication. With near-zero iteration cost, a prototype costs hours. Cheaper than the spec document that would have been wrong.

---

### The Accelerate Gap: Extending Principles Left of Commit

**Source:** Martin Fowler's foreword to Accelerate (Forsgren, Humble, Kim)

Fowler notes: *"We should also remember that their book focuses on IT delivery, that is, the journey from commit to production, not the entire software development process."*

Accelerate measures from **commit to production** — deployment frequency, lead time for changes, MTTR, change failure rate. The DORA metrics. Everything left of commit is explicitly out of scope.

**What we're doing:** Pushing the same principles — small batches, build quality in, integrate early, eliminate waste — back into the space **before commit**. The space where the developer is thinking, designing, coding, reviewing, testing.

**Why Accelerate couldn't go there:** The pre-commit space was inherently human and unmeasurable. You can measure deploy frequency. You can't easily measure "how much context did the developer lose between Tuesday's meeting and Thursday's implementation." You can't instrument a human's thought process.

**Why AIADLC can:** With agents, that space becomes instrumented. Hooks fire at every lifecycle event. Context is preserved in handoffs. Quality gates run mechanically at iteration boundaries. The pre-commit lifecycle becomes as observable and enforceable as the post-commit pipeline.

**The connection to "These Go to Eleven":**
- Accelerate proved the post-commit principles work (the data is overwhelming)
- We're showing the same principles apply pre-commit
- Agents make them achievable there for the first time
- The full lifecycle — idea to production — is now under the same discipline

**What this means for the paper:** We're not contradicting Accelerate. We're extending it. Fowler identified the boundary himself. AIADLC erases that boundary by making the pre-commit space as measurable, enforceable, and optimizable as the post-commit pipeline.

This is the "further back" — and it strengthens every principle we've discussed:
- **Small batches (P1):** iterations measured in hours, not sprints
- **Build quality in (P2):** mechanical enforcement at every boundary, not just CI/CD
- **Integrate early (P3):** sync-all every 30 minutes, not daily
- **Eliminate waste (P4):** context loss — the invisible pre-commit waste — finally addressable

---

---

### Principle 6 (Candidate): Continual Process Improvement — Deming Finally Achieved

**Source:** Deming (Plan-Do-Check-Act), Toyota Production System (kaizen), Lean (Poppendieck)

**The problem Deming identified:** Quality improves through continual, incremental process refinement. Not big-bang transformations — steady, evidence-driven improvement cycles. PDCA. Kaizen.

**Why software never achieved it:** Process change in software development has enormous sunk costs and fixed costs. Changing a process means: rewrite documentation, retrain the team, update tooling, fix scripts, migrate artifacts, endure the transition period where half the team does the old way. The cost of change protected bad processes. So teams iterated around the edges — a new linter rule, a tweak to the CI pipeline — but fundamental process rework was a quarterly event at best. Most orgs never did it at all. We preached continual improvement but practiced periodic adjustment.

**How AIADLC changes this:** The cost of process change drops to near zero. A principal and their agents can:
1. Review the entire process in a discussion (hours, not months)
2. Identify gaps and improvements through evidence (quality gate reports, incident analysis, pattern recognition)
3. Design the new process collaboratively (discussion protocol)
4. Build the tooling to enforce it (hooks, commands, skills, agents) in the same session
5. Propagate changes across all artifacts mechanically (a "process refactoring agent" finds every file, reference, and convention that needs updating)
6. Verify the new process works through the next iteration's quality gate

**The PDCA cycle at 11:**
- **Plan:** Discussion between principal and agents identifies the gap
- **Do:** Agents build the tooling and update the artifacts
- **Check:** Quality gate verifies the change didn't break anything
- **Act:** The change is live, mechanically enforced, for the next iteration

The cycle that used to take a quarter now takes an afternoon. And because it's cheap, you actually do it — every time you find a gap, not once a quarter in a retrospective.

**Evidence (2026-03-28):** In a single captain session, we:
- Reviewed the entire directory structure and sandbox model
- Identified that the model didn't support multiple principals or separate Anthropic's namespace from ours
- Designed a new three-layer structure (.claude/ vs claude/ vs usr/)
- Identified that workstream creation needed a generic base with pluggable starter packs
- Designed the agent architecture (captain, PM, workstream tech leads)
- Built the captain and PM agent definitions
- Built the transcript capture tool to improve how we capture these very discussions
- All in one session. The implementation cost is mechanical.

**Connection to other principles:**
- **Principle 1 (Small batches):** Process changes are small, incremental — not big-bang transformations
- **Principle 2 (Build quality in):** Process enforcement IS quality enforcement. Hooks, hookify, quality gates — all process-as-code.
- **Principle 4 (Eliminate waste):** Process debt is waste. The inability to refactor process cheaply means bad processes persist. When refactoring is cheap, you fix process problems as you find them.

**The Deming connection:** Deming's 14 Points for Management include "Improve constantly and forever the system of production and service." He meant it literally — not annually, not quarterly, but constantly. AIADLC makes "constantly" achievable because the agents do the mechanical work of propagating changes. The human provides the insight; the agents provide the labor.

**For CWB (Conference, Workshop, Book):**

This principle is central to all three:
- **Conference talk:** "Deming finally achieved" is a headline. The audience knows Deming but has given up on continual improvement in practice. Showing it's now real — with evidence — is the hook.
- **Workshop:** Live demonstration. Take a process gap in the workshop participants' workflow, design a fix, build the tooling, propagate it. In 30 minutes, not 30 days.
- **Articles:** "Why Your Retrospective Doesn't Work (And What Does)" — the traditional retro identifies problems but can't economically fix them. AIADLC can.
- **Book:** Full chapter. Historical context (Deming → Toyota → Lean → Agile → DevOps → AIADLC). Each tried to achieve continual improvement. Each hit the cost barrier. AIADLC removes the barrier.

---

## Principle Candidate: The Unix Philosophy

**The platform is dumb infrastructure; the intelligence is in the Agency.**

GitHub does one thing: hosts repos and PRs. Git does one thing: tracks content. The Agency composes them into a workflow that neither tool imagined.

The Unix philosophy — do one thing well, compose, text streams between simple tools — survives and may be more relevant than ever. AI agents are the ultimate composable tools:

- Each agent does one thing (review code, write tests, manage sync)
- The captain composes them
- The pipes are worktrees, handoffs, and the discussion protocol

This maps to the Agency model: the principal is the shell, the agents are the programs, the artifacts (handoffs, QGRs, living docs) are the pipes.
