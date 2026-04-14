---
type: seed
workstream: agency
date: 2026-04-12
subject: "AI Augmented Development Workshop — Republic Polytechnic — Outline v2"
supersedes: workshop-outline-republic-poly-20260410.md
revision_notes: "Incorporates Jordan's mobile review (2026-04-12 breakfast walk). Parts 1-3 fully revised. Parts 4-5 pending Jordan review."
---

# AI Augmented Development Workshop — v2

**Date:** Monday 13 April 2026, 09:00–17:00
**Location:** Republic Polytechnic, Singapore
**Participants:** ~20 lecturers + IMDA observers (Kiren Kumar DCEO + Spenser + Zeph)
**Format:** 7 hours (09:00 start, 1 hour lunch). Setup 09:00–10:00. Content 10:00–17:00.

**TODO:** Send message about loaner laptops for IMDA participants.

---

## Schedule Overview

| Time | Block | Duration |
|------|-------|----------|
| 09:00–10:00 | Setup: Troubleshooting, Laptops, Bootstrap + Claude Login + Remote Control | 60 min |
| 10:00–10:10 | Welcome + Schedule Overview | 10 min |
| 10:10–11:00 | Part 1: The Sea Change | 50 min |
| 11:00–12:00 | Part 2: Claude Code — From Anthropic to Agentic Harness | 60 min |
| 12:00–12:30 | Part 3: Valueflow + The Agency — The AI ADLC | 30 min |
| 12:30–13:30 | **Lunch** | 60 min |
| 13:30–15:00 | Part 4: Guided Build — Seed to Deploy | 90 min |
| 15:00–15:40 | Elevator Pitches | 40 min |
| 15:40–16:45 | Part 5: Independent Build | 65 min |
| 16:45–17:00 | Show & Tell + Wrap | 15 min |

---

## Setup (09:00–10:00)

**Goal:** Everyone connected and ready before content starts. Fighting fires, laptop issues, network problems all happen here, not during content.

### Pre-work (done at home — sent via setup guide)
- VMware Workstation installed
- Ubuntu VM created and running
- Claude Desktop installed on Windows and signed in

### Workshop morning
1. Boot VM, open GNOME Terminal
2. Run the bootstrap script (installs Chrome, Node.js, Claude Code, GitHub CLI)
3. `claude login` — opens browser for OAuth
4. Launch two Claude Code instances with `remote-control`
5. **Switch to Windows** — open Claude Desktop → Code tab
6. Connect to the two Remote Control sessions from Code tab
7. Done — all work happens in Claude Desktop from here

**Key point:** The VM is infrastructure. Claude Desktop on Windows is their workspace.

**Bootstrap script delivery:** TODO — determine how participants get the script (workshop repo clone, URL, USB, pre-installed in VM image).

---

## Welcome + Schedule Overview (10:00–10:10)

Lay out the day. What we'll cover, when, and what they'll build. Set expectations: this is hands-on, not a lecture. By the end of the day, they'll have deployed a real website.

---

## Part 1: The Sea Change (10:10–11:00)

**Goal:** Set the frame. This is not a tool demo. This is a paradigm shift. We are racing through the software development singularity.

### Opening Punch

**Slide: "This is NOT Vibe Coding."**

> "You may have heard the term 'Vibe Coding.' Gene Kim and Steve Yegge wrote a great book with that title — Dario Amodei, the CEO of Anthropic, wrote the foreword — and there's excellent material in it that we'll draw on today. But I deliberately don't use that term. Vibe coding implies you just vibe and code comes out. What we're doing today is disciplined. It's engineering. It's building."

**Slide: Vibe Coding book cover** *(mdslidepal requirement: images)*

**Slide: "Coding is dead."**

> "We've thought for way too long that it's about being a coder. It's not. Coding is dead. What we are is builders. We build things. The tools change. The craft doesn't."

**Reference:** Li, Ko, Begel (2019) — "What Distinguishes Great Software Engineers?" — 1,926 Microsoft engineers. Top 5 attributes: only #1 is a coding skill. #2-#5 are judgment, decision-making, collaboration, continuous learning. *"Even before AI, 4 of the top 5 traits of great engineers were NOT coding. AI is automating the one that was. The other four are what Valueflow amplifies."*

**Slide: "We are builders."**

### The Abstraction Ladder — My Career as the Model

Walk through the history of abstraction, using personal history:

| Era | Layer | What I did |
|-----|-------|-----------|
| 1980s | Hardware | Flipped switches on a front panel |
| 1984 | Machine code | PM on MacsBug — Motorola 68K debugger for the Mac |
| 1984 | Assembly | PM on MDS — Macintosh 68000 Development System |
| 1986 | Assembly + HLL | PM on MPW — Macintosh Programmer's Workshop |
| 1990s–2010s | High-level languages | C, C++, Java, JavaScript, through the decades |
| 2020s | Frameworks | React, Next.js, NestJS |
| 2025–now | AI Augmented | Claude Code + Valueflow + The Agency |

> "I was PM on the tools that built the Macintosh. The assembler. The debugger. The development environment. At MacHack — the legendary Mac developer conference, midnight keynotes, hack contests until 6 AM — there were three mantras. One of them was 'It's all Jordan's fault.' That's me. I've been at every level of this stack."

> "Every time we moved up a layer, people said the previous layer was the 'real' programming. Assembly programmers looked down on C. C programmers looked down on Java. Everyone looks down on JavaScript. And now everyone says 'but can you code without AI?' It's the same argument every time. And it's wrong every time."

**Slide: "Asking 'can you code without AI?' is like asking a React developer to write their OS in C."**

### The Software Development Singularity

- The concept of the technological singularity — not a single event but a cascade of events
- We are RIGHT NOW in the **software development singularity**
- What's happened in the last year — the acceleration
- AI changing all knowledge work (nod to Kim/Yegge Ch 5)
- Fast vs Good vs Cheap — the classic triangle, pick two
  - **With discipline, you can have all three.** That's the revolution.
  - *(TODO: find a solid reference for the triangle)*
- Steve Yegge's levels — weave in as reference points

### Who Am I

- **CPTO (Chief Product Technical Officer)** — Head of Product and Technology at OrdinaryFolk (healthtech, Singapore)
- 4 decades: Apple, Adobe, Indeed, Yahoo, startups
- PM for the Apple 68K Development Environment (MacsBug, MDS, MPW)
- Advisor on AI Augmented Development to Singapore Polytechnic, Open Government Products, others
- **AI agents outnumber humans 12:1+** — not 6:1, it's 12 agents working with me in parallel
- **Working across 2 agencies simultaneously** — the-agency AND monofolk. Principal on both projects, every day, back and forth.

### The Christmas Project

- Job interview challenge → built a full telemedicine application Christmas Eve to New Year's Day
- 7 Claude agents running in parallel, 14 hours/day
- Cost: ~$200/month (Max plan) vs $35K+ for equivalent human team
- "I landed with dry tanks at 93% utilization"
- **Didn't know telemedicine yet** — but understood the problem and how to break it down
- That system is now being pulled from for both inspiration and design at OrdinaryFolk — sometimes reimplementing against a cleaner, better-refined design
- Demonstrates: **domain fluency + AI beats either alone**

### The Career Progression Model

Map your 4-step model to agent collaboration levels:

| Step | Career Level | AI Collaboration Level | Yegge Level |
|------|-------------|----------------------|-------------|
| 1. Directed contribution | Apprentice | Without tuning — creates more work than value | *(map)* |
| 2. Independent contribution (well-defined) | Journeyman | With CLAUDE.md, good descriptions, quality gates | *(map)* |
| 3. Independent contribution (ambiguous) | Senior Journeyman | With multi-agent review, autonomous iteration | *(map)* |
| 4. Working through others | Master Craftsman | With full Valueflow, running autonomously overnight | *(map)* |

*(TODO: Cross-map with Yegge's specific levels from Vibe Coding)*

### Domain Fluency + AI Beats Either Alone

- Network configuration story — not an expert, but understood the problem
- Could have written the diagnostic tools manually — given a week
- Solved it in hours with Claude
- **The skill that matters: understanding a problem and how to break it down**

---

## Part 2: Claude Code — From Anthropic to Agentic Harness (11:00–12:00)

**Goal:** Understand Anthropic, why they matter, what Claude Code is, and the key concepts for working with it effectively.

### Anthropic — Safety First

Start here. Before you talk about the tool, talk about the company that built it and WHY they built it differently.

- **The break with OpenAI:** Dario Amodei was VP of Research at OpenAI. Daniela Amodei was VP of Safety & Policy. In December 2020, Dario left. Fourteen researchers followed. They founded Anthropic in 2021.
- **Why:** "It is incredibly unproductive to try and argue with someone else's vision." Sam wanted to go one direction. Dario and Daniela said no. They wanted safety integrated into training from the start, not bolted on after.
- **Public Benefit Corporation:** Anthropic's board can legally prioritize mission over profit. The "Long-Term Benefit Trust" can elect directors. This is structural, not aspirational.
- **Constitutional AI (2022):** Trains harmlessness via self-improvement using principles (RLAIF). Anthropic claims RLAIF produces better alignment than standard RLHF.
- **Joint safety eval with OpenAI (2025):** Claude trades higher refusal rates for lower hallucination. More conservative = more reliable for autonomous agent work.
- **Why this matters for YOU:** When you're running agents overnight, building with agents autonomously, trusting agents with your codebase — alignment and safety aren't abstract. They're the foundation of trust. Anthropic started from safety. That's why Claude is the right foundation for serious agent work.

### The 4 Ds of AI Fluency (Anthropic's Framework)

Bring these in here — before any tools discussion. This is the philosophical lens for everything that follows.

1. **Delegation** — knowing what to hand off and what to keep
2. **Description** — clearly communicating context, goals, constraints
   - "AI can only build what you can describe"
   - Vague input → vague output. Specific input → specific output.
3. **Discernment** — evaluating AI output, trust but verify
   - "Why haven't you looked at the logs?" story
4. **Diligence** — you're responsible for what ships
   - "AI ate my homework is not a valid excuse"

### What Is an Agentic Harness?

Introduce the concept before you introduce the specific tool:

- An **agentic harness** is a platform for defining and running AI agents
- It provides: context management, tool execution, lifecycle hooks, session persistence, multi-agent coordination
- Claude Code is a **generalized** agentic harness — it wasn't built just for coding
- Boris Cherny needed to build an agent that could code. He built it on top of a general-purpose harness. The coding capabilities are layered on top.
- That's why it's extensible (hooks, MCP, skills, tools) — the harness is general, the coding focus is a layer

### UNIX Philosophy (for this audience)

> "One tool does one job and does it well."

This audience may not know this — explain briefly. Claude Code follows this philosophy: small composable tools, pipes, text as the universal interface. This is why it's terminal-native, not an IDE.

### The `claude` Command — What Happens When You Type It

Start with the concrete. Type `claude` in a terminal. What happens:

- Claude Code starts a session
- It reads your CLAUDE.md files (standing instructions)
- It reads your settings (permissions, hooks, tools)
- It's now ready — you talk to it, it acts

### Context Window — The Fundamental Constraint

Introduce this BEFORE CLAUDE.md. The context window is the foundational concept; CLAUDE.md is one of several things that consumes context.

- What the context window is — the "working memory" of the conversation
- Token economics: context tokens vs billable/usage tokens
- The log dump analogy: "If I asked you to read a 50MB log dump, you'd lose every tree in the forest. And every token in that dump costs money."
- **Managing context is THE critical skill**
- Token economics as a competitive advantage — the-agency is **parsimonious** with tokens
  - People complain about running out of tokens → they're burning them on huge dumps
  - Streaming command output, reading entire files when you need one line, loading every doc into context
  - Discipline here = more productive sessions, lower cost, better output

### Claude Code Is Hard to Set Up

Two honest points:

1. **Claude Code is hard to get set up, especially if you're new to it.** That's why we did the bootstrap script and the setup guide.
2. **If you don't set it up well, you hit significant token economic issues** — both usage (burning money) and context (burning quality). This is tied to Part 3 — it's why The Agency exists.

### The Elements of Claude Code

*(Find the earlier research where we catalogued Claude Code elements — may be in README-THEAGENCY.md. Start from that list.)*

Walk through each briefly:

1. **CLAUDE.md** — standing instructions, project memory, the "working agreement"
   - Hierarchy: `~/.claude/CLAUDE.md` → project root → subdirectories
   - Every lesson learned becomes a standing instruction
   - "This is where discipline lives"

2. **Tools** — Bash, Read, Write, Edit, Grep, Glob, Agent (subagents)

3. **Plan Mode vs Ultraplan**
   - **Plan Mode:** local, think before you act. "Discuss → Plan → Review Plan → Revise → Implement." The cost of planning is low; the cost of rework is high.
   - **Ultraplan:** cloud-based planning with Opus 4.6 in a 30-minute container. Your terminal stays free. Review/revise in a browser.
   - **When to use which:** Plan Mode for in-session work you're actively guiding. Ultraplan for complex planning you want to hand off to the cloud while you keep working locally. Cost: Ultraplan uses cloud compute; Plan Mode uses your local session.

4. **Hooks** — SessionStart, UserPromptSubmit, Stop, PreToolUse, PostToolUse
   - Automation that fires at lifecycle events
   - "Process as code — if it's not in a hook, it's a suggestion, not a rule"

5. **Skills / Commands** — `/` discoverable actions

6. **MCP Servers** — extending capabilities (browser, databases, APIs, Figma)

7. **Compact** — what it is, why it happens, how to survive it
   - Context window fills up → compact preserves key context
   - Handoffs and standing instructions survive compacts

8. **Remote Control** — connecting from Claude Desktop, browser, mobile
   - "This is how you're working today — Claude Code runs in the VM, you control it from Desktop"

### Jamon Holmgren's 8 Practices (Validation from the Trenches)

Quick reference — Jamon Holmgren (Founder/CTO, Infinite Red), paying $200+/mo:

1. Excellent test suite
2. Excellent docs
3. Curated codebase
4. Review agents
5. Well-written specs
6. ~~Review every line of every change~~ **← DISAGREE.** Not possible. We do it with agents — quality gates.
7. **Run agents at night — forces you to improve everything above** ← the discipline test
8. Hand-write features sometimes — stay connected

> "His #7 is the key: if your system can't run autonomously while you sleep, your docs, tests, and specs aren't good enough yet."

> "On #6 — I strongly disagree. You cannot review every line of every change at scale. What you CAN do is have agents review agents. That's what quality gates are for. We'll cover this in Part 3."

---

## Part 3: Valueflow + The Agency — The AI ADLC (12:00–12:30)

**Goal:** The methodology and the platform that makes disciplined AI-augmented development repeatable.

**CRITICAL NAMING DISTINCTION:**
- **Valueflow** = the AI ADLC (the methodology). From The Agency Group AI.
- **The Agency** = the platform/framework/tooling that implements Valueflow. From The Agency Group AI.
- These are DIFFERENT things. Valueflow is the methodology; The Agency is the implementation.

### The Problem — No AI ADLC Exists

- All existing SDLCs (Waterfall, Agile, Scrum, Kanban, SAFe, Lean Startup, DevOps) were designed for a **non-agentic world**
- Nobody has reimagined the development lifecycle for human-agent collaborative development
- AWS published an AI-DLC (re:Invent 2025). Arthur.ai and EPAM have agent development lifecycles. These are valuable contributions. *(give the nod)*
- **But:** AWS AI-DLC treats AI as executor with human oversight (single-agent command structure). Arthur.ai/EPAM are for BUILDING AI agents, not building WITH agents. Vibe Coding describes practices, not a lifecycle.
- **What's missing:** A methodology for **structured human-agent collaborative development** — with defined roles, communication protocols, multi-agent coordination, quality gates, and a full idea-to-value lifecycle
- This ties to HX (Human Experience) vs AX (Agentic Experience) — existing methodologies optimize for humans but completely ignore the agentic experience

### What Is Valueflow — The AI ADLC

```
Idea → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
```

Overview first, then brief dig into each:

- **Seed** — captured starting point (an idea, a conversation, a problem)
- **Research (MARFI)** — Multi-Agent Request for Information. Parallel research agents.
- **PVR** — Product Vision & Requirements (the what and why)
- **A&D** — Architecture & Design (the how and why)
- **Plan** — Phases × Iterations
- **Implement** — Agents execute, QG at every boundary
- **Ship** — PR, deploy, done
- **Value** — customer using it, feedback generates new seeds

*(Walk through the Valueflow + OODA diagram. This picture is critical. No slides for this — walk them through it live.)*

### The Multi-Agent Dimension

**This is NOT about you and one AI assistant.** This is the key differentiator.

- You as a **principal** running an **agency** — 12 agents in parallel
- Each agent has identity, memory, handoffs, quality gates
- Agents review each other, test each other
- And your agency collaborates with **other agencies** run by other humans
- "I run my agency. I can have a really big number of agents. And I collaborate with other agencies."

### What Is The Agency — The Platform

**The Agency** implements Valueflow. It's the tooling and framework.

**Demo: the build comparison** *(two-column slide build)*

| Step | Claude Code alone | Claude Code + The Agency |
|------|------------------|--------------------------|
| Start | `my-project/` (empty) | `my-project/` (empty) |
| `git init` | `.git/` | `.git/` |
| Next | `claude` (init) | `agency init` |
| After init | `.claude/settings.json` maybe a `CLAUDE.md` stub | `.claude/` agents, skills, settings + `claude/` tools, hooks, hookify, docs, config, templates, workstreams + `usr/{principal}/` sandbox + `CLAUDE.md` constitution |
| First `claude` run | Blank canvas with a smart assistant | Structured environment: hooks fire, handoff read, dispatch check, enforcement active, methodology embedded |

> "On the left: a smart assistant. On the right: a development methodology with 60+ tools, quality gates, multi-agent coordination, session continuity, and enforcement built in. Same AI underneath. Radically different outcomes."

### Main Components Overview

Overview the main components before digging into detail:

1. **Valueflow** — the AI ADLC (methodology)
2. **Agents** — identity, handoffs, dispatches, multi-agent coordination
3. **ISCP** — Inter-Session Communication Protocol (how agents talk to each other)
4. **Quality Gates** — MAR, red-green, QGR
5. **Enforcement Triangle** — tool + skill + hookify rule
6. **OODA** — the structural pattern (Observe → Orient → Decide → Act)

### Quality Gates — The Discipline Layer

- Different kinds of quality gates for different boundaries (iteration, phase, plan, pre-PR)
- Different kinds of MAR (Multi-Agent Review) — varying agent counts and angles
- Red-green discipline: write a failing test, then fix
- Binary triage: fix it or it's not an issue. No "low priority."
- Quality Gate Report (QGR) documents everything
- **This is how we address Jamon's #6** — we don't review every line manually. Agents review agents.

### The Enforcement Triangle

Every capability has three parts:
1. **Tool** — does the work (pre-approved, no permission prompts)
2. **Skill** — tells you when and how to use the tool (discoverable via `/`)
3. **Hookify rule** — blocks the raw alternative (you can't bypass)

> "If it's not enforced by code, it's a suggestion. And suggestions get ignored."

### OODA — The Structural Pattern

- Observe → Orient → Decide → Act
- Maps to everything: Valueflow, Enforcement Ladder, captain triage
- Inner loop (single iteration), middle loop (phase), outer loop (project)
- The goal: tighten the loop. Faster cycles = better outcomes.

### Born from the Trenches — Three Iterations

1. **Christmas 2025** — the OrdinaryFolk build. 7 agents, 14 hours/day, discovered a LOT of friction points (constantly discovering more)
2. **January 2026** — agency-starter, first workshop (the one that broke), Agency Bench
3. **February–April 2026** — TheAgency framework, Valueflow methodology, ISCP, Enforcement Triangle. Phases overlapped. Applying to monofolk in March–April gave strong validation.

### Live Case Study: Yesterday's Captain Session

> "Let me show you something that happened YESTERDAY while preparing this workshop."

Walk through what happened in a single session:

1. **Fixed broken CI** — tests failing for weeks → fixed, merged PR
2. **Designed the contribution model** — three rings of trust → 1B1 → seed → CONTRIBUTING.md + PR template
3. **Filed 8 feedback items to Anthropic** — discovered `/feedback` broken for 5+ months → researched evidence → drafted, reviewed, filed all 8
4. **Ran 4 parallel Figma research agents** — all in background while doing other work
5. **Planned mdslidepal** (this slide tool) — contract spec → 4-agent MAR → two planning agents → reconciliation → 4 decisions 1B1
6. **Refactored the core instruction file** — 738 lines → 85 lines (89% reduction) — delegated to DevEx agent

> "One session. Multiple value streams. Parallel agents. Quality gates. Cross-repo coordination. That's Valueflow in action."

### Two Experience Pillars

- **HX** — Human Experience (the principal directing agents — UX, ergonomics, trust, control)
- **AX** — Agentic Experience (the agents themselves — permissions, context, identity, communication)
- Most tools today have great HX (DevEx) but **horrible AX**
- The human in the loop is the **principal**
- The Agency treats both equally — because if the agent's experience is broken (permission prompts, context overflow, no identity, no memory), the human's experience breaks too

---

## LUNCH (12:30–13:30)

---

## Part 4: Guided Build — Seed to Deploy (13:30–15:00)

*(Pending Jordan review — carried forward from v1 with minor time adjustments)*

### The Toy Project: Personal Page + Mini-Blog

**Seed:** "Build a personal page that introduces you, with a mini-blog where you can write posts. Deploy it to Vercel."

- About me section
- Mini-blog with 2-3 posts
- **Stretch goal:** AI-powered Q&A section
- Next.js + local markdown for blog posts → Vercel deploy

### Step-by-Step Walkthrough

**Step 1: The Seed (5 min)**
- "Tell your captain: I want to build a personal page with a mini-blog."
- Captain asks clarifying questions (teaching Description)

**Step 2: PVR (15 min)**
- Captain guides through defining what they want
- "This is Description from the 4 Ds in action"

**Step 3: A&D (10 min)**
- Captain proposes: Next.js, Tailwind, markdown files for blog posts
- "Your agent just did architecture. You reviewed it. That's Discernment."

**Step 4: Plan (10 min)**
- Captain breaks into iterations
- "This is Plan Mode. Think before you act."

**Step 5: Execute Iterations 1-3 (30 min)**
- Captain executes, students watch and review
- "This is the OODA loop — observe, orient, decide, act"

**Step 6: Deploy to Vercel (15 min)**
- Sign up for Vercel (free)
- Connect GitHub repo
- Everyone has a live URL

**Step 7: Celebrate (5 min)**
- Share URLs
- "You just went from idea to deployed website through a structured methodology in 90 minutes."

---

## Elevator Pitches (15:00–15:40)

- 20 participants × 2 minutes max
- "I want to build [X] because [Y]"
- Jordan scopes and gives feedback on each

---

## Part 5: Independent Build (15:40–16:45)

*(Pending Jordan review — carried forward from v1)*

- Each student takes their own idea through Valueflow with their captain
- Jordan floats between students, gives suggestions, unblocks
- Goal: running local version, ideally deployed

---

## Show & Tell + Wrap (16:45–17:00)

*(Pending Jordan review — carried forward from v1)*

### Show & Tell (10 min)
- Volunteers demo what they built

### Key Takeaways (3 min)
1. **This is NOT Vibe Coding** — it's disciplined, it's engineering
2. **Context is everything** — CLAUDE.md, handoffs, managed context
3. **Description drives quality** — AI can only build what you can describe
4. **Trust but verify** — apprentice to master progression
5. **Quality gates matter** — agents review agents
6. **The abstraction continues** — you're the next generation of builders

### Closing (2 min)

> "40 years ago, I was flipping switches on a front panel. Today you deployed a website by having a conversation with an AI agent. The tools changed. The craft didn't. You are builders. Go build."

---

## Artifacts TODO (revised)

| Artifact | Status | Blocking? |
|---|---|---|
| Workshop repo (`the-agency-ai/the-agency-workshop`) | ❌ Empty | **YES** |
| `agency init` tested on repo | ❌ | **YES** |
| Slide deck (full outline → slides) | ❌ Plan B sample only | **YES** |
| Toy project spec (reproducible recipe) | 📝 In outline | **YES** |
| Vercel deploy tested E2E | ❌ | **YES** |
| Bootstrap script delivery method | ❌ | **YES** |
| Loaner laptops for IMDA | ❌ Jordan to message | Moderate |
| Valueflow + OODA diagram | ❌ | **YES** for Part 3 |
| Build comparison slides (Claude vs Agency) | ❌ | **YES** for Part 3 |
| Career progression × Yegge levels mapping | ❌ | Moderate |
| Fast/Good/Cheap reference | ❌ | Minor |
| Workshop start script | 📝 Needs redraft | Moderate |
| Collaboration config | ❌ | Nice-to-have |
| "Over and Out" article | 📝 To draft today | Not blocking workshop |
| Vibe Coding book cover slide | ❌ | Minor (image asset) |

---

## Source Materials (expanded)

- Jordan's workshop transcripts (Jan 9, Jan 10, Jan 15, Mar 14, Apr 3, Apr 4, Apr 6, Apr 9, Apr 10, Apr 11–12)
- Vibe Coding by Gene Kim & Steve Yegge (book — Dario wrote foreword)
- Li, Ko, Begel (2019) "What Distinguishes Great Software Engineers?" — Empirical Software Engineering, Springer
- Anthropic founding story — Inc.com, Wikipedia, Yahoo Finance
- Constitutional AI paper — arxiv 2212.08073
- Anthropic-OpenAI joint safety eval (2025)
- AWS AI-DLC (re:Invent 2025, GitHub)
- Anthropic's 4 Ds framework
- MacHack history / "It's All Jordan's Fault"
- MacsBug, MDS, MPW product history
- Jamon Holmgren's 8 practices (X post)
- OODA Loop / Process Intelligence dispatches from monofolk
- TheAgency framework documentation
- Radio procedure words — Wikipedia (prowords, 1860s Morse → WWII voice radio)
- Skantze (2021) "Turn-taking in Conversational Systems" — Computer Speech & Language
- Liberating Structures (Lipmanowicz & McCandless, 2013)
- Yesterday's captain session transcript (case study)
- Today's mobile remote-control voice session transcript (case study)

---

## v2 Revision Notes

**Changed from v1:**
- Start time: 10:00 → 09:00 (setup hour 9-10)
- Schedule rebalanced for earlier start
- Part 1: Added singularity framing, career progression 4-step model, 12:1 ratio, Christmas project expansion, Li et al citation
- Part 2: Restructured — Anthropic safety story first, 4 Ds before tools, agentic harness concept, UNIX philosophy, context window before CLAUDE.md, Plan vs Ultraplan, token economics, Claude Code hard-to-setup honest points, Jamon #6 disagreement explicit
- Part 3: Renamed (Valueflow + The Agency), naming distinction enforced, "no AI ADLC exists" with AWS nod, multi-agent emphasis, build comparison demo, HX/AX instead of UX/PX/AX, born-from-trenches honest framing, yesterday's session as case study
- Parts 4-5: Pending Jordan review — minor time adjustments only
- Artifacts TODO expanded
- Source materials expanded with research citations
