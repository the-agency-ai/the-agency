# Introduction to AI Augmented Development

### with

### Claude Code

### The Agency · Valueflow

<br><br>

Republic Polytechnic · 13 April 2026

Jordan Dea-Mattson · Principal, The Agency Group AI · CPTO, OrdinaryFolk

---

# How We Got Here

I started experimenting with AI augmented development around **April 2025** — the same time Claude Code appeared.

Everything before that? Honestly, it didn't do much.

Then I started being impressed.

**Christmas 2025** was the inflection point. Claude Code's capabilities jumped. We saw this across the industry.

I did zero-to-one and zero-to-100 exercises. Came away very impressed — but there was **a lot of friction. A lot of pain.**

So I started solving those problems.

That's what became **The Agency** and **Valueflow.**

---

# Who Am I

**Jordan Dea-Mattson**

CPTO (Chief Product Technical Officer) · Head of Product and Technology

**OrdinaryFolk** · Healthtech · Singapore

- 4 decades: Apple, Adobe, Indeed, Yahoo, startups
- PM for the Apple 68K Development Environment (MacsBug, MDS, MPW)
- MacHack: "It's all Jordan's fault"
- Advisor: Singapore Polytechnic, Open Government Products
- **12 AI agents** working with me in parallel
- **2 agencies** simultaneously — The Agency + OrdinaryFolk/monofolk

---

# My Two Hats

**Hat 1 — The Creator** · The Agency + Valueflow · *Building the methodology*

**Hat 2 — The Practitioner** · CPTO, OrdinaryFolk · *Applying it daily with 12 agents*

![The OODA loop between my two hats](ooda-two-hats.svg)

---

# Schedule

| Time | What |
|------|------|
| 09:00–10:00 | Setup |
| 10:00–11:00 | **Part 1:** The Sea Change |
| 11:00–12:00 | **Part 2:** Claude Code |
| 12:00–12:30 | **Part 3:** Valueflow + The Agency |
| 12:30–13:30 | Lunch |
| 13:30–15:00 | **Part 4:** Guided Build |
| 15:00–15:40 | Elevator Pitches |
| 15:40–16:45 | **Part 5:** Independent Build |
| 16:45–17:00 | Show & Tell |

---

# This is NOT Vibe Coding.

<!-- TODO: Insert Vibe Coding book cover image here -->

---

# Coding is dead.

---

# We are builders.

---

# The Abstraction Ladder

### As Seen Through My Career

![The Abstraction Ladder](abstraction-ladder.svg)

---

# "Asking 'can you code without AI?' is like asking a React developer to write their OS in C."

---

# The Technological Singularity?

You've heard of the technological singularity?

Turns out it's not a single event. It's a **cascade.**

We are in the **software development singularity** right now.

---

# What Distinguishes Great Engineers?

1,926 Microsoft engineers were surveyed. Top 5 attributes:

- Writing good code ← **the only coding skill**
- Adjusting for future value and costs
- Practicing informed decision-making
- Avoiding making others' jobs harder
- Learning continuously

**4 of 5 are NOT coding skills.**

AI is automating #1. The other four are what Valueflow amplifies.

*Li, Ko, Begel. "What Distinguishes Great Software Engineers?" Empirical Software Engineering, Springer, 2019.*

---

# Fast · Good · Cheap

![Fast Good Cheap Triangle](fast-good-cheap.svg)

**With discipline and AI augmented development, you can have all three.**

That's the revolution.

---

# The Christmas Project

**The challenge:** Job interview → build a full telemedicine application

**The timeline:** Christmas Eve to New Year's Day

**The team:** 7 Claude agents, 14 hours/day

**The cost:** $200/month vs $35K+ for a human team

**The result:** "Landed with dry tanks at 93% utilization"

I didn't know telemedicine. I understood the **problem** and how to break it down.

That system is now being pulled from for design and implementation at OrdinaryFolk.

---

# Domain Fluency + AI

# >

# Either Alone

<br>

The skill that matters: **understanding a problem and how to break it down.**

---

# Career Progression

![Career Progression Continuum](career-progression.svg)

---

# Part 2: Claude Code

## From Anthropic to Agentic Harness

---

# Anthropic — Safety First

- Dario Amodei: VP Research at OpenAI
- Daniela Amodei: VP Safety & Policy at OpenAI
- December 2020: they left. 14 researchers followed.
- Founded Anthropic, 2021

**"It is incredibly unproductive to try and argue with someone else's vision."**

---

# Why Safety Matters to You

**Safety is alignment.**

**Alignment means lower hallucination.**

**Alignment is not something abstract.**

When you trust agents to run overnight, when you trust them with your codebase, when you trust them to ship — alignment is the foundation of that trust.

That's why Claude is the right foundation for serious agent work.

---

# The 4 Ds of AI Fluency

*From Anthropic's AI Fluency research and the Anthropic Academy course*
*We gratefully acknowledge their contribution*

- **Delegation**
  - Knowing what to hand off and what to keep
- **Description**
  - Clearly communicating context, goals, constraints
  - "AI can only build what you can describe"
- **Discernment**
  - Evaluating AI output — trust but verify
- **Diligence**
  - You're responsible for what ships
  - "AI ate my homework" is not a valid excuse

---

# What Is an Agentic Harness?

A platform for defining and running AI agents:

- Context management
- Tool execution
- Lifecycle hooks
- Session persistence
- Multi-agent coordination

**Claude Code is an agentic harness tuned for coding.**

Boris Cherny built it on a generalized foundation, then focused it on the coding use case. That's why it's extensible — the general harness is underneath.

---

# `claude`

What happens when you type it:

- Starts a session
- Reads your CLAUDE.md (standing instructions)
- Reads your settings (permissions, hooks, tools)
- Ready — you talk, it acts

---

# Context Window

The fundamental constraint.

- Your "working memory" — everything in the conversation
- **Token economics:** context tokens cost money AND quality
- "If I asked you to read a 50MB log dump, you'd lose every tree in the forest."
- **Managing context is THE critical skill**

---

# Token Economics

The Agency is **parsimonious** with tokens.

People complain about running out → they're burning tokens on:

- Streaming command output nobody reads
- Reading entire files when they need one line
- Loading every doc into context "just in case"

**Discipline = more productive sessions, lower cost, better output.**

---

# CLAUDE.md

Standing instructions. Project memory. The working agreement.

- `~/.claude/CLAUDE.md` — global (your preferences)
- `./CLAUDE.md` — project root (project rules)
- `./src/CLAUDE.md` — subdirectory (scoped context)

Every lesson learned becomes a standing instruction.

**This is where discipline lives.**

---

# The Elements of Claude Code

- **Tools** — Bash, Read, Write, Edit, Grep, Glob, Agent
- **Plan Mode** — think before you act (local)
- **Ultraplan** — cloud planning with Opus 4.6
- **Hooks** — automation at lifecycle events (SessionStart, Stop, PreToolUse)
- **Skills** — `/` discoverable actions
- **MCP Servers** — extend capabilities (browser, databases, APIs, Figma)
- **Compact** — surviving context overflow
- **Handoffs** — session continuity across restarts

<!-- TODO: Reorder and refine this list — needs attention -->

---

# Jamon Holmgren's 8 Practices

- ✅ Excellent test suite
- ✅ Excellent docs
- ✅ Curated codebase
- ✅ Review agents
- ✅ Well-written specs
- ~~Review every line of every change~~
  - **We use Quality Gates + Multi-Agent Review**
- ✅ **Run agents at night** ← the discipline test
- ✅ Hand-write features sometimes

"If your system can't run autonomously while you sleep, your docs, tests, and specs aren't good enough yet."

---

# Part 3: Valueflow + The Agency

## The AI ADLC

---

# The Problem

All existing SDLCs were designed for a **non-agentic world.**

Nobody has reimagined the development lifecycle for human-agent collaboration.

<!-- Reference: AWS AI-DLC, Arthur.ai ADLC, EPAM — exist but focused on single-agent or building-agents-not-with-agents -->

---

# The Research That Exists

**Nicole Forsgren** + DORA (2014–2025, 39,000+ professionals)

Proved: software delivery performance is **measurable** and predicts organizational outcomes.

**Four Key Metrics:** deployment frequency, lead time, change failure rate, MTTR

But these measure **code commit → production.**

<!-- TODO: Show Accelerate + DevOps Handbook book covers -->

---

# The Gap Nobody Filled

**Upstream** (idea → code): ideation, research, requirements, design, planning — **unmeasured**

**Downstream** (production → value): adoption, feedback, value realization — **unmeasured**

**Agentic**: multi-agent coordination, human-agent workflows, agent quality gates — **not addressed**

Forsgren measured half the problem. **Valueflow measures all of it.**

*Forsgren, Humble, Kim. "Accelerate." IT Revolution, 2018.*

---

# Valueflow — The AI ADLC

![Valueflow Pipeline](valueflow-pipeline.svg)

The first methodology for **structured human-agent collaborative development.**

From The Agency Group AI.

---

# The Multi-Agent Dimension

This is NOT you and one AI assistant.

- You as a **principal** running an **agency** — 12 agents in parallel
- Each agent: identity, memory, handoffs, quality gates
- Agents review each other, test each other
- Your agency collaborates with **other agencies** run by other humans
- "I run my agency. And I collaborate with other agencies."

---

# The Agency — The Platform

**The Agency** implements Valueflow.

- 60+ tools
- Quality gates at every boundary
- Multi-agent coordination
- Session continuity (handoffs, ISCP)
- Enforcement (Triangle: tool + skill + hookify rule)

---

# Claude Code Alone vs The Agency

<!-- TODO: Build-up animation showing directory contents growing -->

| | Claude Code | + The Agency |
|---|---|---|
| Start | Empty directory | Empty directory |
| After `git init` | `.git/` | `.git/` |
| After setup | `.claude/` | `.claude/` + `claude/` + `usr/` + `CLAUDE.md` |
| **First run** | Blank canvas | Hooks fire, handoff read, enforcement active |
| **Result** | Smart assistant | **Structured methodology** |

---

# Quality Gates

- Multi-Agent Review (MAR) at every boundary
- Different depths for different boundaries
- Red-green discipline — failing test first, then fix
- Binary triage — fix it or it's not an issue
- **Agents review agents** — this is how we scale review

---

# The Enforcement Triangle

| Layer | What | Why |
|-------|------|-----|
| **Tool** | Does the work | Permissions |
| **Skill** | Tells you when/how | Discovery |
| **Hookify rule** | Blocks the bypass | Compliance |

"If it's not enforced by code, it's a suggestion."

---

# OODA

Observe → Orient → Decide → Act

- Inner loop: single iteration
- Middle loop: phase
- Outer loop: project

**Tighten the loop.**

---

# Case Study: Yesterday

One captain session:

- Fixed broken CI (tests failing for weeks)
- Designed contribution model (three rings of trust)
- Filed 8 feedback items to Anthropic
- Ran 4 parallel Figma research agents
- Planned mdslidepal (this tool!) — contract + MAR + reconciliation
- Refactored core instruction file (738 → 85 lines, 89% reduction)

**Valueflow in action.**

---

# HX and AX

- **HX** — Human Experience (the principal)
- **AX** — Agentic Experience (the agents)

Most tools today: great HX, **horrible AX.**

The Agency treats both equally.

---

# Lunch

Back at 13:30.

---

# Part 4: Guided Build

## Seed to Deploy

---

# The Toy Project

**Personal page + mini-blog → deployed to Vercel**

- About me section
- Mini-blog with 2–3 posts
- Next.js + Tailwind + markdown
- **From idea to live URL in 90 minutes**

---

# Step 1: The Seed

Tell your captain:

"I want to build a personal page with a mini-blog. Here's my name and a sentence about me."

---

# Step 2: Define (PVR)

Your captain guides you through requirements.

- What pages?
- What features?
- What does success look like?

**This is Description from the 4 Ds.**

---

# Step 3: Design (A&D)

Captain proposes: Next.js, Tailwind, markdown files.

You review. You ask why.

**This is Discernment.**

---

# Step 4: Plan

Captain breaks it into iterations:

- Project scaffold + about page
- Blog listing + individual posts
- Styling and polish
- Vercel deploy
- (Stretch) AI Q&A section

**Think before you act.**

---

# Step 5: Build

Captain executes. You watch and review.

"If something looks wrong, hit Escape and ask why."

After each iteration: review → approve → next.

**This is the OODA loop.**

---

# Step 6: Deploy

- Sign up for Vercel (free)
- Connect GitHub repo
- Captain handles the config
- **You have a live URL**

---

# 🎉

You just went from idea to deployed website through a structured methodology in 90 minutes.

Share your URL!

---

# Elevator Pitches

2 minutes each.

**"I want to build [X] because [Y]."**

---

# Independent Build

Your idea. Your captain. Valueflow.

Jordan floats — ask for help anytime.

Goal: running locally, ideally deployed.

---

# Show & Tell

Volunteers: demo what you built.

---

# What's Next — The Vision

---

# Markdown is the Lingua Franca

Not .doc. Not .pptx. Not Google Docs.

**Markdown.**

It's what agents read. It's what agents write. It's what survives compaction, handoffs, and version control.

Every tool we build is markdown-native.

---

# The Ecosystem

- **Markdown Pal** — reviewing and navigating markdown (macOS + iOS)
- **mdslidepal** — presenting from markdown (these slides!)
- **Mock and Mark** — visual communication for markdown-native workflows

All built with Claude Code. All built with Valueflow. All open source.

---

# How I Actually Work

- **Granola** — capture every meeting as structured knowledge
- **Remote Control** — voice input from mobile while walking
- **Over/Over-and-Out** — radio protocol for structured agent conversation
- **Dispatch monitoring** — 4+ agents running in parallel, event-driven awareness
- **Multi-agency** — principal on two agencies (The Agency + OrdinaryFolk) simultaneously, every day

---

# How These Slides Were Made

This morning: breakfast walk to McDonald's.

Voice input via Claude Desktop Remote Control.

Captain held my input (Over protocol), mirrored back what I heard, made changes, I refreshed.

**That loop — human directing, agent building, tool rendering — is what mdslidepal enables.**

And it's all from markdown.

---

# Key Takeaways

- **This is NOT Vibe Coding** — it's engineering
- **Context is everything** — manage it or lose it
- **Description drives quality** — AI builds what you describe
- **Trust but verify** — apprentice to master
- **Quality gates matter** — agents review agents
- **You are builders** — the abstraction continues

---

# Diligence Disclosure

In keeping with the Fourth D:

**The Agency** was built entirely with Claude Code — every tool, every skill, every hookify rule, every line of framework code.

**Valueflow** was designed through structured human-agent collaboration — seeds, PVRs, A&Ds, plans, all produced via the methodology itself.

**This workshop** — the outline, the research, the slides, the deck tool (mdslidepal) — was built in the last 48 hours using Claude Code, The Agency, and Valueflow.

We are responsible for what we ship. And we disclose how it was made.

---

# Acknowledgments

**Ms Wong Wai Ling**
Director, School of Infocomm (SOI), Republic Polytechnic
*For taking a risk on this workshop and making it a reality.*

**Mr Abel Ang**
Chairperson, Republic Polytechnic
*For recommending me to the SOI Advisory Committee. Without him, this wouldn't be happening.*

**Ms Phyllis Ling**
Manager (Admin), Republic Polytechnic
*For her help with logistics.*

**Anthropic and the Claude AI team**
*For building the foundation this is all built on.*

And anyone else I might have missed — thank you.

---

# Built with What We Taught You

Everything you experienced today was built using the tools and methodology we just showed you:

- **These slides** → built with **mdslidepal** (written yesterday, first use today)
- **The workshop outline** → planned using **Valueflow** (Seed → PVR → Plan)
- **The research** → run by **parallel agents** (4 agents, background)
- **The content review** → via **Over/Over-and-Out protocol** (voice input, breakfast walk, Remote Control)
- **All of it** → **Claude Code + The Agency + Valueflow**

We practice what we preach.

---

# Thank You

- **Web:** the-agency-group.ai
- **GitHub:** github.com/the-agency-ai/the-agency
- **X:** @AgencyGroupAI

Jordan Dea-Mattson · jordandm@gmail.com
