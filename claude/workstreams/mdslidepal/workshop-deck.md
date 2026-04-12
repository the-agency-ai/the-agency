# Introduction to AI Augmented Development

### with Claude Code · The Agency · Valueflow

Republic Polytechnic · 13 April 2026

Jordan Dea-Mattson

Principal · The Agency Group AI

CPTO · OrdinaryFolk

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

---

# Coding is dead.

---

# We are builders.

---

# The Abstraction Ladder

| Era | Layer | Jordan's role |
|-----|-------|--------------|
| 1980s | Hardware | Flipped switches on a front panel |
| 1984 | Machine code | PM on MacsBug (68K debugger) |
| 1984 | Assembly | PM on MDS (Mac Dev System) |
| 1986 | HLL | PM on MPW (Mac Programmer's Workshop) |
| 1990s+ | C, C++, Java, JS | Through the decades |
| 2020s | Frameworks | React, Next.js, NestJS |
| 2025+ | **AI Augmented** | Claude Code + Valueflow + The Agency |

---

# "Asking 'can you code without AI?' is like asking a React developer to write their OS in C."

---

# The Software Development Singularity

Not a single event — a cascade.

We are in it **right now.**

---

# What distinguishes great engineers?

Li, Ko, Begel (2019) — 1,926 Microsoft engineers

1. Writing good code ← **the only coding skill**
2. Adjusting for future value and costs
3. Practicing informed decision-making
4. Avoiding making others' jobs harder
5. Learning continuously

**4 of 5 are NOT coding skills.**

AI is automating #1. The other four are what Valueflow amplifies.

---

# Fast · Good · Cheap

Pick two.

**With discipline, you can have all three.**

That's the revolution.

---

# Who Am I

**Jordan Dea-Mattson**
CPTO · Head of Product and Technology · OrdinaryFolk

- 4 decades: Apple, Adobe, Indeed, Yahoo
- PM for the Apple 68K Development Environment
- MacHack: *"It's all Jordan's fault"*
- Advisor: Singapore Polytechnic, Open Government Products
- **12 agents** working in parallel, **2 agencies** simultaneously

---

# The Christmas Project

- Job interview → built a full telemedicine app
- Christmas Eve to New Year's Day
- 7 agents, 14 hours/day
- **$200/month** vs $35K+ human team
- "Landed with dry tanks at 93% utilization"
- Didn't know telemedicine — understood the **problem**

---

# Domain Fluency + AI > Either Alone

The skill that matters:

**Understanding a problem and how to break it down.**

---

# Career Progression

| Step | Level | AI Collaboration |
|------|-------|-----------------|
| 1. Directed contribution | Apprentice | Without tuning — creates more work than value |
| 2. Independent (well-defined) | Journeyman | With CLAUDE.md + quality gates |
| 3. Independent (ambiguous) | Senior Journeyman | With multi-agent review |
| 4. Working through others | Master Craftsman | With full Valueflow, autonomous overnight |

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

- Public Benefit Corporation — mission over profit
- Constitutional AI (2022) — safety via principles
- Lower hallucination, higher reliability
- **When you trust agents to run overnight, alignment isn't abstract**

---

# The 4 Ds of AI Fluency

1. **Delegation** — what to hand off, what to keep
2. **Description** — context + goals + constraints
3. **Discernment** — evaluate output, trust but verify
4. **Diligence** — you're responsible for what ships

*"AI ate my homework" is not a valid excuse.*

---

# What is an Agentic Harness?

A platform for defining and running AI agents.

- Context management
- Tool execution
- Lifecycle hooks
- Session persistence
- Multi-agent coordination

**Claude Code is a generalized agentic harness.**

Boris Cherny needed a coding agent. He built it on a general-purpose harness.

---

# `claude`

What happens when you type it:

1. Starts a session
2. Reads your CLAUDE.md (standing instructions)
3. Reads your settings (permissions, hooks, tools)
4. Ready — you talk, it acts

---

# Context Window

The fundamental constraint.

- Your "working memory" — everything in the conversation
- **Token economics:** context tokens cost money AND quality
- The log dump problem: *"If I asked you to read a 50MB log dump..."*
- **Managing context is THE critical skill**

---

# CLAUDE.md

Standing instructions. Project memory. The working agreement.

```
~/.claude/CLAUDE.md     ← global
./CLAUDE.md             ← project root
./src/CLAUDE.md         ← subdirectory
```

Every lesson learned becomes a standing instruction.

**This is where discipline lives.**

---

# The Elements

- **Tools** — Bash, Read, Write, Edit, Grep, Glob, Agent
- **Plan Mode** — think before you act
- **Ultraplan** — cloud planning with Opus 4.6
- **Hooks** — automation at lifecycle events
- **Skills** — `/` discoverable actions
- **MCP Servers** — extend capabilities
- **Compact** — surviving context overflow
- **Remote Control** — Claude Desktop, browser, mobile

---

# Token Economics

The Agency is **parsimonious** with tokens.

People complain about limits → they're burning tokens on:
- Streaming command output
- Reading entire files when they need one line
- Loading every doc into context

**Discipline = more productive sessions, lower cost, better output.**

---

# Jamon Holmgren's 8 Practices

1. ✅ Excellent test suite
2. ✅ Excellent docs
3. ✅ Curated codebase
4. ✅ Review agents
5. ✅ Well-written specs
6. ❌ ~~Review every line~~ — **not possible at scale**
7. ✅ **Run agents at night** ← the discipline test
8. ✅ Hand-write features sometimes

On #6: we don't review manually. **Agents review agents.** Quality gates.

---

# Part 3: Valueflow + The Agency

## The AI ADLC

---

# The Problem

All existing SDLCs were designed for a **non-agentic world.**

Nobody has reimagined the development lifecycle for human-agent collaboration.

---

# Valueflow — The AI ADLC

```
Idea → Seed → Research → Define → Design → Plan → Implement → Ship → Value
```

The first methodology for **structured human-agent collaborative development.**

From The Agency Group AI.

---

# The Multi-Agent Dimension

This is NOT you and one AI assistant.

- **Principal** running an **agency** — 12 agents in parallel
- Each agent: identity, memory, handoffs, quality gates
- Agents review each other, test each other
- Your agency collaborates with **other agencies**

---

# The Agency — The Platform

**The Agency** implements Valueflow.

60+ tools · quality gates · multi-agent coordination · session continuity · enforcement

---

# Claude Code alone vs The Agency

| | Claude Code | + The Agency |
|---|---|---|
| After `git init` | `.git/` | `.git/` |
| After setup | `.claude/settings.json` | `.claude/` + `claude/` + `usr/` + CLAUDE.md |
| First run | Blank canvas | Hooks fire, handoff read, enforcement active |
| **Result** | Smart assistant | **Structured methodology** |

---

# Quality Gates

- Multi-Agent Review (MAR) at every boundary
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

*If it's not enforced by code, it's a suggestion.*

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

1. Fixed broken CI (tests failing for weeks)
2. Designed contribution model (three rings of trust)
3. Filed 8 feedback items to Anthropic
4. Ran 4 parallel Figma research agents
5. Planned mdslidepal (this tool!) — contract + MAR + reconciliation
6. Refactored core instruction file (738 → 85 lines, 89% reduction)

**Valueflow in action.**

---

# HX and AX

- **HX** — Human Experience (the principal)
- **AX** — Agentic Experience (the agents)

Most tools: great HX, **horrible AX.**

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
- Mini-blog with 2-3 posts
- Next.js + Tailwind + markdown
- **From idea to live URL in 90 minutes**

---

# Step 1: The Seed

Tell your captain:

*"I want to build a personal page with a mini-blog. Here's my name and a sentence about me."*

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

1. Project scaffold + about page
2. Blog listing + individual posts
3. Styling and polish
4. Vercel deploy
5. (Stretch) AI Q&A section

**Think before you act.**

---

# Step 5: Build

Captain executes. You watch and review.

*"If something looks wrong, hit Escape and ask why."*

After each iteration: review → approve → next.

**This is the OODA loop.**

---

# Step 6: Deploy

1. Sign up for Vercel (free)
2. Connect GitHub repo
3. Captain handles the config
4. **You have a live URL**

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

# Key Takeaways

1. **This is NOT Vibe Coding** — it's engineering
2. **Context is everything** — manage it or lose it
3. **Description drives quality** — AI builds what you describe
4. **Trust but verify** — apprentice to master
5. **Quality gates matter** — agents review agents
6. **You are builders** — the abstraction continues

---

# 40 years ago, I was flipping switches on a front panel.

Today you deployed a website by having a conversation with an AI agent.

**The tools changed. The craft didn't.**

**You are builders. Go build.**

---

# Acknowledgments

**Ms Wong Wai Ling**
Director, School of Infocomm (SOI), Republic Polytechnic
*For taking a risk on this workshop and making it a reality.*

**Mr Abel Ang**
Chairperson, Republic Polytechnic
*For recommending me to the SOI Advisory Committee. Without him, I wouldn't be here. This wouldn't be happening.*

**Ms Phyllis Ling**
Manager (Admin), Republic Polytechnic
*For her help with logistics.*

And anyone else I might have missed — thank you.

---

# Built with What We Taught You

Everything you experienced today was built using the tools and methodology we just showed you:

- **These slides** → built with **mdslidepal** (written yesterday, first use today)
- **The workshop outline** → planned using **Valueflow** (Seed → PVR → Plan)
- **The research** → run by **parallel agents** (4 agents, background, while we worked on other things)
- **The content** → reviewed via **Over/Over-and-Out protocol** (Jordan on a breakfast walk, voice input via Remote Control)
- **All of it** → **Claude Code + The Agency + Valueflow**

We practice what we preach.

---

# Thank You

- **Web:** the-agency-group.ai
- **GitHub:** github.com/the-agency-ai/the-agency
- **X:** @AgencyGroupAI

Jordan Dea-Mattson · jordandm@gmail.com
