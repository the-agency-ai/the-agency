# SOURCE: How we actually use AI to ship production code at FAANG

**Source:** https://www.reddit.com/r/vibecoding/comments/1q9svgl/how_we_actually_use_ai_to_ship_production_code_at/
**Captured:** 2026-01-15
**Type:** Reddit post (r/vibecoding)
**Author:** AI SWE, ~10 years experience, half at FAANG

---

## Original Content

Hey folks. I wanted to write this up because I keep seeing people say that AI assisted coding isn't ready for real production environments. That is just not true.

For context, I am an AI SWE with about a decade of experience. I have spent half of that time at FAANG or similar big tech companies. I actually started as a Systems Engineer before moving to dev, but I have been coding for around 15 years.

Here is the actual workflow we use to ship prod code with AI.

### 1. The Technical Design Document
You always start here. This is where the real work happens. It starts as a proposal doc. If you can get enough stakeholders to agree that your proposal has merit, you move on to developing out the system design itself. This includes the full architecture and integrations with other teams. We usually live in Google Docs for this phase since the commenting features are essential for async debate and resolving open questions before we commit to anything.

### 2. The Design Review
Before you write a single line of code, you take that design doc and get it absolutely shredded by Senior Engineers. This is a good thing. I look at it as front loading the pain so you don't suffer later. We use Excalidraw heavily here to whiteboard out the architecture during the meeting so everyone sees the same data flows. If you can't explain the system visually, you probably don't understand it well enough to build it yet.

### 3. Subsystem Planning
If you pass the review, you can now launch into the development effort. We spend the first few weeks doing more documentation on each subsystem that will be built by the individual dev teams. This might feel slow, but writing detailed implementation specs means you catch edge cases early. We usually link these directly to the original design doc so the context never gets lost.

### 4. Sprint Planning
This is where the devs work with the PMs and TPMs. We hammer out discrete tasks that individual devs will work on and the order they need to happen. We track all of this in Jira (unfortunately) but it gets the job done for organizing the chaos. The goal is to make the tickets small enough that an AI agent can digest the context without hallucinating.

### 5. Development
This is where we finally get hands on the keyboard and start crushing task tickets. We use Test Driven Development, so I have the AI coding agent write the tests first before building the feature. To speed this up, I rely heavily on voice dictation because speaking complex logic is significantly faster than typing it out. I'm testing WillowVoice right now for this since the sub-second latency and accuracy are solid for technical prompts and emails. I'm open to other suggestions, but right now it is a major accelerator.

### 6. Code Submission Review
We have a strict two developer approval process before code can get merged into main. AI is also showing great promise in assisting with the review. We use standard GitHub PRs, but we are experimenting with AI bots that auto-comment on potential bugs or style violations before a human even looks at it. It saves the reviewer from having to nitpick.

### 7. Test in Staging
If staging is good to go, we push to prod. We rely on Jenkins pipelines to automate the testing suite here. If the green checkmark appears, we feel confident shipping it.

### The Result
Overall, we are seeing a ~30% increase in speed from the feature proposal to when it hits prod. This is huge for us.

### TL;DR
Always start with a solid design doc and architecture. Build from there in chunks. Always write tests first. Use tools to handle the friction so you can focus on the logic.

---

## Analysis: FAANG Workflow vs The Agency

### Similarities

| Aspect | FAANG Approach | The Agency |
|--------|---------------|------------|
| Design First | Technical Design Doc before code | REQUEST files, EPICs, Sprint planning |
| Review Gates | Design review by seniors | Two-subagent code review process |
| Small Tasks | "Small enough that AI can digest" | Iterations with clear deliverables |
| TDD | Tests first before features | Tests mandatory in each iteration |
| Code Review | Two developer approval | Cross-agent review with consolidated findings |
| CI/CD | Jenkins pipelines | Pre-commit hooks, quality gates |

### Key Differences

| Aspect | FAANG Approach | The Agency |
|--------|---------------|------------|
| **AI Role** | AI assists single developer | Multiple AI agents collaborate in parallel |
| **Coordination** | Humans coordinate via meetings | Agents coordinate via tools (collaborate, news) |
| **Context** | Google Docs + Jira | KNOWLEDGE.md, WORKLOG.md, context-save |
| **Throughput** | 30% speed increase | 7 agents in parallel (multiplicative) |
| **Review** | AI auto-comments on PRs | Subagents do full code + test reviews |
| **Architecture** | Human draws in Excalidraw | Agent plans with human approval (EnterPlanMode) |

### What They Do Well (Learn From)

1. **"Front-loading the pain"** - Design review before code. The Agency could be more explicit about design review phases.

2. **"Small enough that AI can digest"** - They consciously size tickets for AI context limits. Good principle.

3. **Voice dictation** - Interesting accelerator for prompting. Not in The Agency yet.

4. **Visual architecture** - "If you can't explain it visually, you don't understand it." The Agency could add diagramming conventions.

### What The Agency Does Better

1. **Multi-agent parallelism** - They have one AI per developer. We have multiple agents per workstream working simultaneously.

2. **Agent-to-agent coordination** - They rely on human meetings. We have `./tools/collaborate`, `news-post`, etc.

3. **Context persistence** - They use Google Docs. We have systematic `context-save`, `KNOWLEDGE.md`, session restoration.

4. **Instrumented logging** - They probably flood context with stdout. We have log service with structured queries.

5. **Reduced "mother may I"** - They don't mention permission optimization. We pre-grant safe operations.

### Key Insight

> "The goal is to make the tickets small enough that an AI agent can digest the context without hallucinating."

This is exactly right. The Agency's iteration model + KNOWLEDGE.md + context funneling all serve this same goal - but we do it systematically rather than hoping ticket size is right.

### Missing from Their Workflow

- No mention of agent-to-agent handoffs
- No mention of context restoration between sessions
- No mention of parallel agents on same codebase
- No mention of design system integration
- Humans still do all the coordination (meetings, Jira)

---

## Book Notes

This article validates The Agency's approach while showing where traditional FAANG is stuck:
- They've adopted AI for individual productivity
- They haven't yet seen AI as collaborative team members
- The coordination overhead is still human-bottlenecked

**Thesis:** The Agency represents the next evolution - from "AI assists developers" to "AI agents are developers, humans are principals."

[(jordan) ]