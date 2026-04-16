# AIADLC Discussion Transcript

**Date:** 2026-03-27
**Participants:** Jordan Dea-Mattson (Principal), Captain Agent (Claude Opus 4.6)
**Cross-reference:** `usr/jordan/conference/aiadlc-notes.md` (working notes), `usr/jordan/conference/aiadlc-proposal-draft.md` (proposal draft v0.1)

---

## Seed: The Original Prompt (2026-03-26)

**Jordan** (from prior session, captured in memory):

> **Paper 1: Towards an AIADLC (AI Augmented Development Life Cycle)**
> We spent over 50 years figuring out how to build software and captured our thinking and practices in various SDLCs and Development Methodologies. We now need to do the same for AI Augmented Development in weeks and months. What lessons can we apply? What rules do we keep? Which do we rewrite? And which do we throw away? Does code review make sense any longer? Things like this. But small batch sizes, yes, probably stays.
>
> **Paper 2: AI Augmented Development: An Adoption Case Study**
> Case study of the adoption of AI Augmented Development at OrdinaryFolk.

---

## Preamble: Setting the Direction

**Jordan:** Let's start with AIADLC, which we will then speak to in our case study.

**Captain:** Good framing — AIADLC sets the theoretical framework, case study provides the evidence.

> _Captain produced proposal draft v0.1 at `usr/jordan/conference/aiadlc-proposal-draft.md` with abstract, key arguments (what stays/gets rewritten/gets thrown away), proposed framework sketch, and evidence base._

---

## Reframing: Start with Principles, Not Framework

**Jordan:** Let's think about principles, hard earned and developed through years of experience, and captured in our SDLC (Software Development Life Cycles) and Methodologies. Things like small batch sizes, etc.

**Captain:** You're right. I jumped to framework too fast. Let me go back to first principles. The question is: what are the principles — the hard-won lessons captured in our SDLCs and methodologies over 50 years? Not the practices, not the ceremonies — the underlying truths about building software that we learned the hard way.

> _Captain enumerated principles from Waterfall (1970s), Agile/XP (1990s-2000s), Lean, DevOps (2010s), Software Craftsmanship, and Conway's Law._
> _See: `aiadlc-notes.md` → Principle Discussion section_

---

## Reference Works

**Jordan:** Some recent works that capture things we might want to examine: Team Topologies, Accelerate. Thinking about our quality gates. Continuous refactoring. The dichotomy between "Doing it Fast" vs. "Doing it Right."

**Captain:** Team Topologies maps directly to what we're building: the captain is a platform team pattern, worktree agents are stream-aligned, the quality gate is an enabling function. Accelerate's four key metrics are our evidence framework.

**Jordan:** Also consider The Phoenix Project by Gene Kim. And look at the itrevolution.com web site.

**Captain:** The Phoenix Project demonstrates principles through narrative — our case study (Paper 2) is our equivalent.

> _Research agent dispatched. Results saved to `usr/jordan/conference/references/book-research.md`_
> _Books: Scrum (Schwaber & Beedle), DevOps Handbook (Kim et al), Lean SD (Poppendieck), Refactoring (Fowler), Accelerate (Forsgren et al), Team Topologies (Skelton & Pais), The Phoenix Project (Kim)_
> _Also: Martin Fowler's blog — 20 most relevant posts indexed_
> _Also: itrevolution.com for DevOps Enterprise Summit content_

---

## Cross-Note: Transformation and Adoption

**Jordan:** Cross note for transformation talk: there is the ability to adopt practices within your Agency (Human + their Squad of Agents), without having to get all the other Humans onboard.

**Captain:** That's a powerful insight. The adoption cost of a new methodology drops from "convince 8 engineers in a retro" to "configure my agents."

> _Captured in `aiadlc-notes.md` → Cross-Note: Transformation / Adoption_
> _Key distinction: intra-Agency practices (adopted unilaterally) vs. inter-Agency practices (require coordination)_
> _Maps to Team Topologies interaction modes: collaboration vs. X-as-a-Service_

---

## Principle 1: Small Batch Sizes / Empirical Process Control

**Captain:** Principle 1: Small batch sizes reduce risk. Source: Lean, Agile, Accelerate. In AI augmented development, agents can produce large volumes quickly. The temptation is to batch big. But yesterday's 337-commit divergence showed the cost. Small batches + mechanical delivery fixed it.

**Jordan:** Yes. And this maps to our approach of Iterations and Phases. I abandoned the term "Sprint" because in most people's minds it means 2 weeks. A Phase might be a few hours.

The definition of small is still tied to:

- **Iteration** — a reviewable, testable, deployable increment of work. Building it, doing it, gives you knowledge and insight to move forward — revising as required.
- **Phase** — a reviewable, testable, deployable increment of work that can be exposed to a customer, consumer, etc. for feedback. Something you can integrate with other systems.

Top-level framing: software development (this was the SCRUM Insight) is an Empirical Process. It is driven by exploration and discovery.

**Captain:** That last point is critical for the paper — empirical process control is THE foundational insight, and it survives the transition to AI augmented development completely. Maybe even strengthens, because the iteration cost drops so low that you can explore MORE.

**Jordan:** Yes!!!! [emphatic agreement]

**Captain:** That's the thesis. The AIADLC doesn't invent new principles — it finally makes the existing principles achievable.

> _Captured in `aiadlc-notes.md` → Core Thesis + Terminology + Principle 1_
> _Verdict: Survives and strengthens. The SCALE shifts (hours not weeks) but the PRINCIPLE is unchanged._

**Status:** Principle 1 CLOSED. Jordan confirmed.

---

## Principle 2: Build Quality In, Don't Inspect It In

**Captain:** Source: Deming, Lean, Accelerate. The Deming distinction assumes inspection is expensive and late. In AI augmented development, our quality gate IS inspection — but it runs at every iteration boundary, mechanically, before any commit. When inspection is instantaneous and the fix cycle is part of the same iteration, the distinction between "build in" and "inspect in" collapses.

**Jordan:** And they write a bug exposing test before they fix it; that test verifies that we got the right fix. This is a practice that has been proven to work, but been almost impossible to get humans to adopt. But while still challenging with agents, we get it done.

**Captain:** Red-green-refactor has been the IDEAL since Kent Beck. Almost no human team does it consistently. With agents + mechanical enforcement, we achieve it. The agent's instinct is to jump to the fix — but the quality gate enforces: prove the bug exists (red), THEN fix it (green).

**Jordan:** [Asked about IQG vs PQG steps — wanting explicit distinction]

**Captain:**

IQG (Iteration Quality Gate): scoped to changes, parallel review agents, red-green cycle, auto-commit, no approval needed.

PQG (Phase Quality Gate): scoped to entire codebase, squash iterations, parallel review agents, red-green cycle, principal must approve (Sprint Review equivalent), lands on master.

**Jordan:** We need to start making these distinctions, because they are different. Need to think about how Phase Complete maps into Sprint Ceremonies, and phase prep maps into them as well. But they aren't Ceremonies now. They are processes and the artifact is the proof?

**Captain:** Yes. In Scrum, ceremonies are meetings — the value is the conversation. In AIADLC, the equivalent are processes that produce artifacts. The QGR IS the Sprint Review. The updated Plan IS Sprint Planning output. The artifact is the proof the process ran.

| Scrum Ceremony       | AIADLC Process                 | Artifact (the proof)                  |
| -------------------- | ------------------------------ | ------------------------------------- |
| Sprint Planning      | Pre-Phase Review               | Updated PVR + A&D + Plan              |
| Daily Standup        | `/sync-all`                    | Sync report                           |
| Sprint Review        | PQG                            | QGR + principal approval              |
| Sprint Retrospective | Bridges PQG → Pre-Phase Review | Updated process + enforcement tooling |

**Jordan:** And we should talk about our review types. And how they support all of this. Reads, comments, and discusses, Agent may revise or take actions, and then revises the artifacts, and then approved.

In a standard SDLC, if I don't like the test coverage or tests built for a Sprint, I can raise the issue and we might try to do better in the future, but here, I can say: hold it! Stop! Andon Cord. Go back and rework and rerun those tests. Or you fixed the bugs, but didn't write the tests. Sorry. Not clearing.

**Captain:** The Andon Cord actually works again because stopping doesn't cost a Sprint's worth of schedule.

**Jordan:** We do have a retrospective — it bridges the PQG and the Pre-Phase Review.

But here is an important point: We don't wait for a Sprint to be over to improve process: we can catch it and fix it as we are running along. How many times have I captured something in an Agent session and flagged it to you and we have defined a process change and built tooling to enforce it.

Oh, important point: even with Agents, process and practices without enforcement in code is not optimal!

**Captain:** Three critical sub-points:

1. **Continuous retrospective, not periodic.** Process improvement happens in the moment — you see a gap, you fix it, you encode it. The feedback loop on the PROCESS ITSELF is as tight as the feedback loop on the CODE.

2. **The Andon Cord works.** The principal can stop, direct rework, and the agent executes immediately. No Sprint boundary to wait for.

3. **Mechanical enforcement.** Prose rules decay. Memory entries drift. The practices that stick are the ones with enforcement in code — hookify rules, quality gate steps, pre-commit hooks, divergence detection. If a practice matters, encode it. If you can't encode it, it will decay.

> _All captured in `aiadlc-notes.md` → Principle 2_
> _Verdict: The Deming distinction collapses. What replaces it is mechanical enforcement at every boundary._
> _New principle candidate: "If you can't encode it, it will decay" — enforcement in code, not process discipline._

**Status:** Principle 2 CLOSED. Jordan confirmed.

---

## Research Findings (between Principle 2 and 3)

### What I learned from the Fowler articles

Nine key articles read and summarized (full summaries at `references/fowler-blog-summaries.md`). The through-line relevant to our paper:

**1. Fowler's entire body of work is about making evolutionary design viable.** CI, refactoring, TDD, the test pyramid — they're all pieces of one argument: you can evolve software safely IF you have the right practices in place. The AIADLC argument is: AI agents + mechanical enforcement make those practices achievable at a scale humans couldn't sustain.

**2. The Design Stamina Hypothesis directly supports our thesis.** Fowler argues the speed-vs-quality tradeoff is illusory — investing in design pays off within weeks, not years. Accelerate confirmed this empirically (high performers excel at both speed and stability). Our quality gate is the mechanical enforcement of design stamina — it prevents agents from eroding design quality even when producing code quickly.

**3. Opportunistic refactoring has a tension with our worktree model.** Fowler warns that feature branching and strict code ownership discourage opportunistic refactoring. Our worktrees ARE feature branches. The mitigation: frequent sync-all + small iterations keep branches short-lived. But this is a genuine tension the paper should acknowledge.

**4. The Agile Fluency Model's timeline compresses dramatically.** Fluency zones that take months-to-years with human teams (Focusing: 2-6 months, Delivering: 3-24 months) can be reached in days-to-weeks with an Agency. But the higher zones (Optimizing, Strengthening) still require human judgment and organizational commitment. Technical fluency compresses; organizational fluency doesn't.

**5. Technical debt taxonomy maps to agent behavior.** Agents primarily produce reckless-inadvertent debt (they don't know what they don't know) and prudent-inadvertent debt (they discover better approaches during implementation). The quality gate catches the first; the iterative PVR/A&D cycle addresses the second.

**6. "Is Design Dead?" is the most relevant article.** Fowler's answer: design shifts from BUFD to evolutionary design, enabled by testing + CI + refactoring. In AIADLC, evolutionary design is the DEFAULT. Agents don't do BUFD. The quality gate serves as the "will to design" that Fowler says is essential. But: does the agent have design VISION, or just design COMPLIANCE? The human provides vision through PVR/A&D; the agent implements; the gate enforces.

### What I learned from the book research

Six reference books surveyed (full details at `references/book-research.md`):

**Accelerate (Forsgren, Humble, Kim):** The four DORA metrics (deployment frequency, lead time, change failure rate, MTTR) are our evidence framework. The 24 capabilities map to what we're building. Key finding for our paper: "speed and stability are NOT trade-offs" — this is the empirical proof that our quality gate approach (mechanical enforcement doesn't slow you down) is correct.

**Team Topologies (Skelton, Pais):** Four team types map directly to our Agency model. Stream-aligned = worktree agents. Platform = captain. Enabling = quality gate. Conway's Law is foundational — with AI agents, we're LITERALLY designing the communication structure that produces the system. The Inverse Conway Maneuver is what we do when we design the worktree/captain/sync-all architecture.

**Lean Software Development (Poppendieck):** Seven principles, all survive with transformation. Most relevant: "Eliminate Waste" (agents eliminate handoff waste), "Amplify Learning" (near-zero iteration cost = more learning), "Build Integrity In" (quality gate), "Decide as Late as Possible" (cheap iterations = defer commitment safely).

**Scrum (Schwaber, Beedle):** Empirical process control (transparency, inspection, adaptation) is our foundational principle. Time-boxing transforms: not calendar-based but iteration-boundary-based. Self-organizing teams → self-organizing agents (with principal oversight).

**Refactoring (Fowler):** Red-green-refactor is the ideal we finally achieve. Code smells detected by review agents. Refactoring catalog as a vocabulary for agent-driven improvement.

**The Phoenix Project (Kim):** The Three Ways (Flow, Feedback, Continual Learning) from DevOps map to: Flow = worktree → master → origin pipeline; Feedback = quality gate at every boundary; Continual Learning = continuous retrospective (mid-session process improvement).

---

## Post-Merge Review Model (between Principle 2 and 3)

**Jordan:** Thinking about the PR process and the QG there. When we generate a PR for origin, we have several paths: default is local pre-PR review (can be overridden), default is no PR review on origin (can be overridden). As the author, I can ask for a PR review by a specific person. Also we'll build a tool to evaluate a PR and decide if it should have a review.

Finally, we want a post-merge flow for PRs. Tooling that lets me see PRs merged to origin which are now local. I go through them and flag them. If I examine deeper, I spin up an agent with my instructions on focus areas, balance of reviewers, etc. It comes back with a report, we discuss via discussion protocol, and the findings go to the author.

The author can reject, address themselves, or delegate to their Agency.

**Captain:** So you're describing post-merge review — not pre-merge. The work is already on origin. The principal reviews what landed and decides scrutiny level.

**Jordan:** The reviewer is a DIFFERENT principal — not the author.

**Captain:** That's the critical distinction. This is inter-Agency code review. Two principals, each with their own agents, collaborating through structured artifacts.

### The Four Tiers

Through discussion, we defined four disposition tiers:

1. **Acknowledge** — "I see it landed." Baseline awareness. No opinion expressed.
2. **LGTM** — "I looked at it, it's good." Active approval after scanning.
3. **Let's look at it more** — triggers deeper review flow. Could be:
   - Finding problems to fix
   - Spotting opportunities ("if we refactored this way, we'd get better performance")
   - Understanding ("I want to understand this better so I can use it")
4. **Andon** — stop the line, revert, this is dangerous. The big red button. Pulled rarely.

**Jordan:** The honest truth about traditional code review: it became a gate that mostly rubber-stamped. The ceremony exists but the diligence doesn't. Inspection theater.

**Captain:** Your model fixes this by:

- Removing the gate — work ships via local QG, not reviewer approval
- Making review voluntary and targeted — reviewer chooses what to look at
- Giving the reviewer agent support — they don't read every line; they direct an agent
- Making findings collaborative, not adversarial — discussion protocol, not "changes requested"

### Pre-PR Quality Gate Scoping

**Jordan:** We need to scope our pre-PR Quality Gate to what is on master — from which we will be drawing our PRs. As opposed to looking at each PR and running it through a gate.

**Captain:** The QG runs once against the full integrated state of master — not per-PR. The PRs are just packaging. The flow:

1. Agents work on worktrees
2. `/sync-all` merges their work into master
3. QG runs on master (the integrated state — everything together)
4. THEN we carve master's diff into scoped PRs
5. Each PR gets principal disposition
6. Push and merge per disposition

Traditional CI/CD runs checks per-PR (isolated). Our model runs checks on master (integrated). We catch integration issues before the PRs exist. This is CI taken further: Fowler's "integrate at least daily" becomes "integrate continuously via sync-all, verify the integrated state, then ship."

### PR Disposition Flow (Adopted)

**Jordan:** Default: push the PR and merge. Check with me for each one. And you get my explicit disposition.

**Captain:** The flow:

1. Create PR, push branch
2. Present: "PR #N: [title]. Push and merge?"
3. Wait for explicit disposition (Merge / LGTM / Let's look / Andon)
4. Act only on explicit disposition. Never merge without hearing back.

### AIADLC Principle Candidate

**Review shifts from gatekeeping to enabling.** The quality gate handles correctness mechanically. Human review handles judgment collaboratively. The Andon Cord exists for emergencies but the default flow is collaborative, not adversarial.

> _Captured in memory: `feedback_pr-disposition.md`_
> _This discussion feeds both the AIADLC paper (Principle: code review transforms from gatekeeping to enabling) and the tooling roadmap (post-merge review system, PR disposition flow)._

### Platform Independence and the Unix Philosophy

**Jordan:** And while this will use GitHub, it runs off of GitHub. In my Claude Code instance. Me and my captain.

**Captain:** GitHub is the transport — where PRs live, where origin/master lives. But the review process runs locally. The captain on my machine, my agents, my discussion with the reviewing agent. The intelligence is in the Agency, not in the platform.

**Jordan:** The Unix Programming Model ;)

**Captain:** Do one thing well. Compose. Text streams between simple tools. GitHub does one thing: hosts repos. Git does one thing: tracks content. The Agency composes them into a workflow neither tool imagined. AI agents are the ultimate composable tools — each does one thing, the captain composes them, the pipes are worktrees, handoffs, and the discussion protocol.

> _Captured in `aiadlc-notes.md` → Principle Candidate: The Unix Philosophy_

**Status:** Discussion captured. PVR next when we formalize the post-merge review system as a project.

---

## Core Thesis Refined: "These Go to Eleven"

**Captain:** [proposed "the AIADLC doesn't invent new principles — it makes them achievable"]

**Jordan:** Did they even go to 10? The framing is: We know what you need to do. But we haven't been doing it. With AI Augmented Development in an AIADLC, we do it. We don't just do it, we take it to 11.

**Captain:** THAT's the thesis, refined. Three beats:

1. We know what to do. Fifty years of SDLCs gave us the principles.
2. We haven't been doing it. We preach them all, practice maybe half, practice well maybe a quarter.
3. With AIADLC, we take it to 11. Same principles, finally achievable, then cranked past what humans could sustain.

> _Core thesis updated in `aiadlc-notes.md`_
> _Reference: Spinal Tap — "These go to eleven"_

---

## Principle 3: Integrate Early, Integrate Often

**Captain:** Source: XP, Fowler's CI article, DevOps First Way, Accelerate. The principle: the longer you wait to integrate, the more painful it is. In AIADLC we integrate MORE often — /sync-all every 30 minutes. But integration splits into two layers: local (sync-all, continuous) and external (PRs, principal-directed).

The 337-commit divergence was a failure of integration discipline — integrating locally but not with origin. The fix was mechanical enforcement at both levels.

**Jordan:** I think a theme of many of these will be "Take this one to 11" (playing off "this one goes to 11").

Also, the importance of preview (local, developer, and PR/branch/worktree). Around getting that right from day one. Getting that set up used to be so painful! Not so any more.

**Captain:** Preview is the integration principle's physical manifestation. You can't verify integration without running it. Traditional pain: preview setup took weeks of DevOps. Teams deferred it, then suffered. With the Agency: an agent built the preview infrastructure alongside the product. Preview from day one, not day ninety.

This connects to the empirical thesis: you can't be truly empirical if you can't SEE what you built running. Preview makes iteration tangible — not just "tests pass" but "look at this, click on it."

**Verdict:** CI survives, cranked to 11. Two cadences (local continuous + external periodic). Preview from day one because the Agency builds infrastructure alongside the product.

> _Captured in `aiadlc-notes.md` → Principle 3_

**Status:** Principle 3 CLOSED. Jordan confirmed.

---

## Principle 4: Eliminate Waste

**Captain:** Source: Lean (Poppendieck), Toyota. Seven wastes of software development. Then vs Now for each.

**Jordan:** A concept we need to capture: Prototype as Spec! Demo beats Deck, Code beats Plan. The living Spec, the living design. It might look like waste, but it isn't.

**Captain:** With near-zero iteration cost, building a prototype to explore a requirement costs hours, not sprints. It's cheaper than writing the spec document that would have been wrong anyway. The prototype IS the requirement.

**Jordan:** And your agents are long-running. You do backups.

**Captain:** The agents are LONG-RUNNING. The folio agent has been working on folio for weeks. Deep context — architecture decisions, phase history, code patterns. Not a fresh session every time. A persistent team member.

**Jordan:** And where a lot of people are missing it. They start with a fresh agent every day. And this is like having an engineer join your team and expecting them to be productive. You need to get them up to speed and give them context. The original transformer paper said "attention is everything." No, context is everything!

Also: updates to the latest version of Claude Code!

**Captain:** People are throwing context away every day. Fresh agent, no handoff, no memory. It's like firing your team every evening and hiring new people every morning.

The agent persists. The session boundary is a coffee break, not a termination. And when Claude Code updates, the agent gains new capabilities WITHOUT losing project context. That's like your engineer going to training over the weekend and coming back with new skills AND all their project knowledge.

**Jordan:** My approach — concrete:

1. End of day, visit each agent
2. "Write a handoff"
3. `/compact` if warranted (below 50%)
4. `/exit`
5. `claude --resume`

And `/compact` through the day as warranted. And you have been running with me for over a week.

**Captain:** A week of accumulated project knowledge through compacts, exits, resumes, updates. Not theoretical — operational. We're not arguing that long-running agents should work. We're showing they DO work.

**Then:** Developer goes home. Context lives in their head. Bus factor is catastrophic.

**Now:** Agent writes a handoff. Context externalized into artifacts. Bus factor: read the handoff. 30 seconds to productive.

### Key sub-points captured:

- **Prototype as Spec** — demo beats deck, code beats plan. Not waste — the most efficient communication.
- **Long-running agents** — persistent team members, not disposable sessions. Context is everything.
- **Context loss is THE defining waste of AIADLC** — handoffs, memory, living docs are the mitigation. Mechanical, not dependent on discipline.
- **Daily agent cycle** — handoff → compact → exit → resume. The AIADLC equivalent of "save your work."
- **Upgrades without context loss** — agent gains capabilities, keeps knowledge.

> _Captured in `aiadlc-notes.md`_
> _TODO noted in memory: automate the daily agent cycle_

**Status:** Principle 4 CLOSED. Jordan confirmed.

---

## Open Items

- Principle 3: CI — CLOSED (cranked to 11, two cadences, preview from day one)
- Principle 4: Eliminate Waste — CLOSED (seven wastes re-examined, context persistence is THE new waste to fight, long-running agents, prototype as spec)
- Principle 5+ — to be discussed (next in queue)
- Post-merge review system — needs PVR, feeds AIADLC paper
- Research: Jordan checking for ePub copies of reference books
- Research: Martin Fowler blog safe crawl (brief at `crawl-fowler-brief.md`, assigned to web-audit)
- Research: itrevolution.com content survey (noted, not yet started)
- Research: The Phoenix Project (noted, not yet started)
- Paper structure: principle-indexed knowledge base vs. source-indexed (agreed on principle-indexed)
