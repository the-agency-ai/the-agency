---
type: seed
workstream: agency
date: 2026-04-10
subject: "AI Augmented Development Workshop — Republic Polytechnic — Outline"
---

# AI Augmented Development Workshop

**Date:** Monday 14 April 2026, 10:00–17:00
**Location:** Republic Polytechnic, Singapore
**Participants:** ~20 lecturers
**Format:** 6 hours working time (10:00 start, 1 hour lunch)

---

## Schedule Overview

| Time | Block | Duration |
|------|-------|----------|
| 10:00–10:20 | Setup: Bootstrap + Claude Login + Remote Control | 20 min |
| 10:20–11:00 | Part 1: The Sea Change | 40 min |
| 11:00–11:45 | Part 2: Claude Code — The Tool | 45 min |
| 11:45–12:15 | Part 3: TheAgency + Valueflow — The Methodology | 30 min |
| 12:15–13:15 | **Lunch** | 60 min |
| 13:15–14:45 | Part 4: Guided Build — Seed to Deploy | 90 min |
| 14:45–15:25 | Elevator Pitches | 40 min |
| 15:25–16:30 | Part 5: Independent Build | 65 min |
| 16:30–17:00 | Show & Tell + Wrap | 30 min |

---

## Setup (10:00–10:20)

**Goal:** Everyone connected and ready before any content starts.

### Pre-work (done at home)
- VMware Workstation installed
- Ubuntu VM created and running
- Claude Desktop installed on Windows and signed in

### Workshop morning
1. Boot VM, open GNOME Terminal
2. Run the bootstrap script (installs Chrome, Homebrew, Node.js, Claude Code, Docker, GitHub CLI)
3. `claude login` — opens browser for OAuth
4. Launch two Claude Code instances with `remote-control`
5. **Switch to Windows** — open Claude Desktop → Code tab
6. Connect to the two Remote Control sessions from Code tab
7. Done — all work happens in Claude Desktop from here

**Key point:** The VM is infrastructure. Claude Desktop on Windows is their workspace.

---

## Part 1: The Sea Change (10:20–11:00)

**Goal:** Set the frame. This is not a tool demo. This is a paradigm shift.

### Opening Punch

**Slide: "This is NOT Vibe Coding."**

> "You may have heard the term 'Vibe Coding.' Gene Kim and Steve Yegge wrote a great book with that title, and there's excellent material in it that we'll draw on today. But I deliberately don't use that term. Vibe coding implies you just vibe and code comes out. What we're doing today is disciplined. It's engineering. It's building."

**Slide: "Coding is dead."**

> "We've thought for way too long that it's about being a coder. It's not. Coding is dead. What we are is builders. We build things. The tools change. The craft doesn't."

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
| 2025–now | AI Augmented | Claude Code + TheAgency |

> "I was PM on the tools that built the Macintosh. The assembler. The debugger. The development environment. At a conference called MacHack — the legendary Mac developer conference that ran for 18 years, midnight keynotes, hack contests until 6 AM — there were three mantras. One of them was 'It's all Jordan's fault.' That's me. I've been at every level of this stack."

> "Every time we moved up a layer, people said the previous layer was the 'real' programming. Assembly programmers looked down on C. C programmers looked down on Java. Everyone looks down on JavaScript. And now everyone says 'but can you code without AI?' It's the same argument every time. And it's wrong every time."

**Slide: "Asking 'can you code without AI?' is like asking a React developer to write their OS in C."**

### The Industry Sea Change

- What's happened in the last year — the acceleration
- AI changing all knowledge work (nod to Kim/Yegge Ch 5)
- The classic tradeoff: Fast vs Good vs Cheap — pick two
  - **With discipline, you can have all three.** That's the revolution.
- Steve Yegge's levels — weave in naturally as reference points

### Who Am I

- Speaker bio — 4 decades, Apple/Adobe/Indeed/Yahoo, startups, Singapore
- Head of Product & Technology at OrdinaryFolk (healthtech)
- AI agents outnumber humans 6:1 on the team
- Advisor on AI Augmented Development to Singapore Polytechnic, Open Government Products, others
- The Christmas project story:
  - Job interview challenge → built a full application Christmas Eve to New Year's Day
  - 7 Claude agents running in parallel, 14 hours/day
  - Cost: ~$200/month (Max 20 plan) vs $35K+ for equivalent human team
  - "I landed with dry tanks at 93% utilization"

### Domain Fluency + AI Beats Either Alone

- Network configuration story — not an expert, but understood the problem
- Could have written the diagnostic tools manually — given a week
- Solved it in hours with Claude
- **The skill that matters: understanding a problem and how to break it down**

---

## Part 2: Claude Code — The Tool (11:00–11:45)

**Goal:** Understand what Claude Code is, why it's the right choice, and its key elements.

### What Is Claude Code

- A platform for defining and running AI agents, tuned for building software
- Terminal-native, UNIX philosophy — extensible, composable, scriptable
- Not an IDE — it's a command-line tool that works with ANY editor, ANY workflow
- You own the toolchain — not waiting for Cursor/Windsurf to ship features

### Why Claude Code Over Alternatives

- **Multi-agent:** Multiple sessions working in parallel (vs Cursor's single-agent)
- **Extensible:** UNIX philosophy — tools, hooks, MCP servers, skills
- **Convention over configuration:** CLAUDE.md as the project constitution
- **Full filesystem access:** Not sandboxed, not limited
- **Terminal-native:** Composable with everything else in your workflow

### ChatGPT / Cursor Compare & Contrast

- ChatGPT: cut-and-paste doesn't work. No persistent context, no project awareness
- Cursor: great single-agent workflow. But single agent. And you don't own the toolchain.
- Claude Code: multi-agent, extensible, convention-driven, you own it

### The Elements of Claude Code

Walk through each with brief explanation:

1. **CLAUDE.md** — standing instructions, project memory, the "working agreement"
   - Hierarchy: `~/.claude/CLAUDE.md` → project root → subdirectories
   - Agents read it on every session start — it's the constitution
   - Every lesson learned becomes a standing instruction
   - "This is where discipline lives"

2. **Context Window** — what it is, why it matters
   - Token economics: context tokens vs billable tokens
   - The log dump analogy: "If I asked you to read a 50MB log dump, you'd lose every tree in the forest. And every token in that dump costs money."
   - Managing context is THE critical skill

3. **Tools** — Bash, Read, Write, Edit, Grep, Glob, Agent (subagents)

4. **Plan Mode** — think before you act
   - "Discuss → Plan → Review Plan → Revise → Implement"
   - The cost of planning is low; the cost of rework is high

5. **Hooks** — SessionStart, UserPromptSubmit, Stop
   - Automation that fires at lifecycle events
   - "Process as code — if it's not in a hook, it's a suggestion, not a rule"

6. **Skills / Commands** — `/` discoverable actions

7. **MCP Servers** — extending capabilities (browser, databases, APIs)

8. **Compact** — what it is, why it happens, how to survive it
   - Context window fills up → compact preserves key context
   - Handoffs and standing instructions survive compacts

9. **Remote Control** — connecting from Claude Desktop, browser, mobile
   - "This is how you're working today — Claude Code runs in the VM, you control it from Desktop"

### Anthropic's 4 Ds of AI Fluency

1. **Delegation** — knowing what to hand off and what to keep
2. **Description** — clearly communicating context, goals, constraints
   - "AI can only build what you can describe"
   - Pattern: What you want + Constraints + Success criteria
   - Vague input → vague output. Specific input → specific output.
3. **Discernment** — evaluating AI output, trust but verify
   - Watch the log trail, interrupt when something looks wrong
   - "Why haven't you looked at the logs?" story
   - Career progression: directed contribution → independent contribution → work through others
4. **Diligence** — you're responsible for what ships
   - "AI ate my homework is not a valid excuse"

### The Career Progression Analogy

Map Claude Code capabilities to traditional SWE levels:

| Level | SWE Equivalent | Claude Code Behavior |
|-------|---------------|---------------------|
| Apprentice | Intern / fresh hire | Without tuning — can create more work than value |
| Journeyman | SWE → Senior SWE | With CLAUDE.md, good descriptions, quality gates |
| Senior Journeyman | Senior SWE | With multi-agent review, autonomous iteration |
| Master Craftsman | Principal SWE | With full Valueflow, running autonomously overnight |

> "Without proper tuning, without the right approach — it's your intern. With discipline, it advances to your next level up fast."

### Jamon Holmgren's 8 Practices (Validation from the Trenches)

Quick reference — Jamon Holmgren (Founder/CTO, Infinite Red), paying $200+/mo:

1. Excellent test suite — agent must run and fix tests
2. Excellent docs — hand-written, agent keeps updated
3. Curated codebase — small files, flat structure, well-named
4. Review agents — Claude reviews Codex, Codex reviews Claude
5. Well-written specs — hand-written, take your time
6. Review every line of every change
7. **Run agents at night — forces you to improve everything above** ← the ultimate discipline test
8. Hand-write features sometimes — stay connected to the code

> "His #7 is the key: if your system can't run autonomously while you sleep, your docs, tests, and specs aren't good enough yet."

---

## Part 3: TheAgency + Valueflow — The Methodology (11:45–12:15)

**Goal:** The framework that makes disciplined AI augmented development repeatable.

### The Problem

- Claude Code is powerful but chaotic without structure
- Context gets scattered across sessions
- No framework for multi-step projects
- Quality is inconsistent without gates
- "Vibe coding chaos" — the Chapter 4 horror stories

### What Is TheAgency

- An open-source framework for when developers and AI agents work together
- Convention over configuration (Rails model)
- Agents with memory and identity
- Structured collaboration — agents review each other, test each other
- Context preservation across sessions (handoffs, CLAUDE.md, transcripts)

### Born from the Trenches — Three Iterations

1. **Christmas 2025** — the OrdinaryFolk build. 7 agents, 14 hours/day, discovered every friction point
2. **January 2026** — agency-starter, first workshop (the one that broke), Agency Bench
3. **February–April 2026** — TheAgency framework, Valueflow methodology, ISCP, Enforcement Triangle

> "Every tool in the framework exists because I hit a wall and built something to get past it. This isn't theory. It's extracted from daily practice."

### Valueflow — The AI SDLC

```
Idea → Seed → Research → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
```

Walk through briefly:
- **Seed** — captured starting point (an idea, a conversation, a problem)
- **PVR** — Product Vision & Requirements (the what and why)
- **A&D** — Architecture & Design (the how and why)
- **Plan** — Phases × Iterations
- **Implement** — Agents execute, QG at every boundary
- **Ship** — PR, deploy, done

### Quality Gates — The Discipline Layer

- Multi-Agent Review (MAR) at every transition
- 4 dimensions: correctness, design, security, testability
- Red-green discipline: write a failing test, then fix
- Binary triage: fix it or it's not an issue. No "low priority."
- Quality Gate Report (QGR) documents everything

### The Enforcement Triangle

Every capability has three parts:
1. **Tool** — does the work
2. **Skill** — tells you when and how to use the tool
3. **Hookify rule** — blocks the raw alternative

> "If it's not enforced by code, it's a suggestion. And suggestions get ignored."

### OODA — The Structural Pattern

- Observe → Orient → Decide → Act
- Maps to everything: Valueflow, Enforcement Ladder, captain triage
- Inner loop (single iteration), middle loop (phase), outer loop (project)
- The goal: tighten the loop. Faster cycles = better outcomes.

### Live Case Study: The Monitor Tool (OODA in Real-Time)

> "Let me show you something that happened TODAY while preparing this workshop."

Story: During workshop prep, we discovered Claude Code's new Monitor tool (v2.1.98). Walk through what happened:

1. **Observe** — Spotted the announcement on X while working
2. **Orient** — Researched it: event-driven background scripts that replace polling. 96% token savings.
3. **Decide** — This replaces our dispatch polling system. Wrote an adoption seed immediately.
4. **Act** — Planned the migration, will implement this weekend

> "From discovery to adoption plan in minutes. The methodology finds and adopts improvements continuously. It improves itself. That's what an AIADLC gives you."

This demonstrates:
- The OODA loop in practice, not theory
- How seeds work — capture → research → decide → act
- Why discipline matters — without the framework, this discovery gets lost in a chat window
- The methodology is alive — it evolves as you use it

### Three Experience Pillars

- **UX** — User Experience (traditional)
- **PX** — Principal Experience (the human directing agents)
- **AX** — Agentic Experience (the agents themselves)
- Most tools favor one side. We treat both equally.

---

## LUNCH (12:15–13:15)

---

## Part 4: Guided Build — Seed to Deploy (13:15–14:45)

**Goal:** Walk everyone through a complete Valueflow cycle, step by step, building a real project that deploys to Vercel.

### The Toy Project: Personal Page + Mini-Blog

**Seed:** "Build a personal page that introduces you, with a mini-blog where you can write posts. Deploy it to Vercel."

- About me section
- Mini-blog with 2-3 posts
- **Stretch goal:** AI-powered Q&A section (requires Anthropic API key)
- Next.js + local markdown for blog posts → Vercel deploy

### Prerequisites (handled by bootstrap)
- Node.js, npm, git installed
- GitHub account (they'll need this for Vercel deploy)
- Vercel account (free hobby tier — sign up during this section)

### Step-by-Step Walkthrough

Everyone works together, guided by Jordan. Their captain (from the workshop CLAUDE.md) knows the curriculum and guides 1:1.

**Step 1: The Seed (5 min)**
- "Tell your captain: I want to build a personal page with a mini-blog. Here's my name and a sentence about me."
- Captain acknowledges, asks clarifying questions (teaching the Description skill)

**Step 2: PVR (15 min)**
- Captain guides them through defining what they want
- What pages? What features? What does success look like?
- Captain produces a PVR document
- Teach: "This is the Description from the 4 Ds in action"

**Step 3: A&D (10 min)**
- Captain proposes: Next.js, Tailwind, markdown files for blog posts
- Brief discussion of why these choices
- Captain produces A&D document
- Teach: "Your agent just did architecture. You reviewed it. That's Discernment."

**Step 4: Plan (10 min)**
- Captain breaks it into iterations:
  1. Project scaffold + about page
  2. Blog listing + individual post pages
  3. Styling and polish
  4. Vercel deploy
  5. (Stretch) AI Q&A section
- Captain produces a plan
- Teach: "This is Plan Mode. Think before you act."

**Step 5: Execute Iterations 1-3 (30 min)**
- Captain executes, students watch and review
- Teach verification: "Watch what it's doing. If something looks wrong, hit Escape and ask why."
- After each iteration: review, approve, move to next
- Teach: "This is the OODA loop in action — observe, orient, decide, act"

**Step 6: Deploy to Vercel (15 min)**
- Sign up for Vercel (free)
- Connect GitHub repo
- Captain handles the deploy configuration
- Everyone has a live URL

**Step 7: Celebrate (5 min)**
- Everyone shares their URL in the chat
- "You just went from idea to deployed website through a structured methodology in 90 minutes."

---

## Elevator Pitches (14:45–15:25)

**Goal:** Each participant shares their seed idea for the independent build.

- 20 participants × 2 minutes max
- Jordan enforces the cutoff
- Format: "I want to build [X] because [Y]"
- Brief feedback from Jordan on each: scope check, feasibility, suggestions

---

## Part 5: Independent Build (15:25–16:30)

**Goal:** They take their own idea through Valueflow with their captain, while Jordan floats.

- Each student has their seed from the elevator pitch
- Their captain (in the workshop CLAUDE.md) knows Valueflow and guides them
- Jordan floats between students, gives suggestions, unblocks issues
- Goal: get to at least a running local version, ideally deployed

### Collaboration Setup

- All students' captains are configured to collaborate with Jordan's captain
- Jordan can see what everyone is working on
- If a student gets stuck, their captain can escalate to Jordan's captain

---

## Show & Tell + Wrap (16:30–17:00)

**Goal:** Celebrate what was built, reinforce key learnings, point to next steps.

### Show & Tell (20 min)
- Volunteers demo what they built (URL or screen share)
- Brief applause, brief feedback

### Key Takeaways (5 min)
1. **This is NOT Vibe Coding** — it's disciplined, it's engineering, it's building
2. **Context is everything** — CLAUDE.md, handoffs, managed context
3. **Description drives quality** — AI can only build what you can describe
4. **Trust but verify** — the career progression from apprentice to master
5. **Quality gates matter** — every issue fixed, red-green, no broken windows
6. **The abstraction continues** — you're the next generation of builders

### What's Next
- TheAgency is open source — https://github.com/the-agency-ai/the-agency
- Keep the VM — it's your development environment now
- Join the community (links)
- Workshop materials stay in the repo they cloned
- Jordan's contact info for follow-up

### Closing

> "40 years ago, I was flipping switches on a front panel. Today you deployed a website by having a conversation with an AI agent. The tools changed. The craft didn't. You are builders. Go build."

---

## Workshop Artifacts to Prepare

| Artifact | Status | Notes |
|----------|--------|-------|
| Setup guide (GDoc) | ✅ Done | Sent to participants |
| Bootstrap script | ✅ Tested | `workshop-bootstrap.sh` |
| Workshop start script | 📝 Draft | Needs redraft for Remote Control + Desktop flow |
| Workshop repo | ❌ TODO | `the-agency-ai/aiad-workshop` — CLAUDE.md + CAPTAIN.md |
| `agency init` tested on repo | ❌ TODO | Verify init layers cleanly over workshop content |
| Slides / keynote | ❌ TODO | Key slides identified in outline |
| Toy project spec | 📝 In outline | Personal page + mini-blog |
| Vercel deploy tested | ❌ TODO | Verify flow works end-to-end |
| Collaboration config | ❌ TODO | Students → Jordan captain connection |
| Jamon Holmgren quote slide | ❌ TODO | 8 practices, permission to cite |
| Monitor tool adoption | ❌ TODO | Implement this weekend — replace dispatch polling |
| Monitor case study slide | ❌ TODO | OODA live example for Part 3 |

---

## Source Materials

All workshop content drawn from:
- Jordan's workshop transcripts (Jan 9, Jan 10, Jan 15, Mar 14, Apr 3, Apr 4, Apr 6, Apr 9, Apr 10)
- Vibe Coding by Gene Kim & Steve Yegge (book analysis)
- Anthropic's 4 Ds framework
- MacHack history / "It's All Jordan's Fault"
- MacsBug, MDS, MPW product history
- Jamon Holmgren's 8 practices (X post)
- OODA Loop / Process Intelligence dispatches from monofolk
- TheAgency framework documentation
