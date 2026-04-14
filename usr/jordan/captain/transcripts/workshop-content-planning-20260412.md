---
type: transcript
mode: dialogue
agent: the-agency/jordan/captain
topic: Workshop Content Planning — Republic Polytechnic, Monday 13 April 2026
date: 2026-04-12
started: 2026-04-12
status: active
related:
  - claude/workstreams/agency/seeds/workshop-outline-republic-poly-20260410.md
  - claude/workstreams/agency/seeds/workshop-setup-guide-20260410.md
  - claude/workstreams/mdslidepal/plan-b/sample-workshop.md
  - usr/jordan/captain/transcripts/contribution-model-three-rings-20260411.md (case study source)
---

# Workshop Content Planning — Republic Polytechnic, Monday 13 April 2026

## Context entering

- Workshop outline drafted yesterday (2026-04-10)
- Setup guide + bootstrap script + start script exist
- 22 invites sent; Kiren Kumar (DCEO IMDA) + 2 officers confirmed
- Plan B slide deck (reveal.js) committed and working at `claude/workstreams/mdslidepal/plan-b/`
- mdslidepal-web agent spinning up for Saturday sprint (proper slide tool)
- mdslidepal-mac agent spinning up at proper pace
- Yesterday's session is being used as a **case study** for the workshop
- DevEx handling CLAUDE.md bootloader refactoring + contribution model rollout in parallel

## Key decisions from yesterday's framing

- **"This is NOT Vibe Coding"** — it's building, it's engineering
- **"Coding is dead"** — what we do now is building
- **Abstraction ladder** — switches → assembly → high-level languages → frameworks → AI
- **Student flow** — clone → agency init → claude login → remote-control → Desktop Code tab → toy project → Vercel deploy
- **Enforcement Triangle** as a teaching moment (tool + skill + hookify)
- **OODA + Valueflow** as the structural framework

## Today's session — Jordan's mobile review (voice input, breakfast walk)

Jordan reviewed the full outline on mobile via remote control and streamed feedback using the "Over" radio-communications protocol (batch input, hold processing until "Over" is received). All feedback captured below, organized by section.

### Logistics changes

- **Start at 0900** (not 1000). Setup/troubleshooting 9–10, content runs from 10.
- **Bootstrap script delivery** — need a plan for getting it to participants before/during setup
- **Loaner laptops** — Jordan to send a message about getting loaners for IMDA participants (Kiren Kumar's team: Spenser, Zeph)
- **Workshop repo goes public** — `the-agency-ai/the-agency-workshop` with a `sessions/` directory (or similar name), this session gets its own directory with all handouts so participants can find them

### Part 1: The Sea Change — revisions

- **Vibe Coding book cover** as a slide — also shapes mdslidepal image requirement (must be able to show images)
- **"Coding is dead"** — find **academic references** showing that hard coding skill was less important to success than other skills (soft skills, problem decomposition, communication, domain fluency). Map those parallel skills to Agency/Valueflow capabilities.
- **Fast/Good/Cheap** — need a solid reference for the "pick two" triangle and why discipline lets you have all three
- **Expand "industry sea change" significantly** — current version is insufficient. Frame as a **technological singularity** — not one event but a cascade of events, and we're currently in the **software development singularity**. Pull in the concept of technological singularity explicitly.
- **Career progression — Jordan's 4-step model:**
  1. Directed contribution (told what to do, supervised)
  2. Independent contribution in well-defined circumstances (knows the playbook, executes)
  3. Independent contribution in ambiguous circumstances (figures it out, navigates uncertainty)
  4. Working through others (delegates, coordinates, multiplies)
  - Maps to: Apprentice → Journeyman (steps 2-3 bracket the journeyman space) → Master Craftsman
  - **Cross-map with Steve Yegge's levels** from Vibe Coding
- **Title: CPTO** (Chief Product Technical Officer) — then bring in "Head of Product and Technology" title and riff on the dual nature of the role
- **Agent count correction: 12:1+**, not 6:1. Highlight **12 agents working in parallel with Jordan**. And highlight that he's working across **2 agencies simultaneously** (the-agency + monofolk), balancing as principal on both projects, every day, back and forth.
- **Christmas project expansion** — didn't know telemedicine yet when he built it. But the system he built is now being pulled from for both inspiration and design, and in some cases implementation (though usually reimplementing against a cleaner, better-refined design). This demonstrates the value of the approach even when domain knowledge was incomplete.

### Part 2: Claude Code — revisions

- **Bring the 4 Ds UP EARLIER** — before the tools/elements section, not after. The 4 Ds lay a **philosophical framework** for everything that follows. They should be the lens through which students see the tools.
- **Why Anthropic > OpenAI/others** — tie to the 4 Ds, specifically to Anthropic's focus on **alignment and AI safety** which drives lower hallucination rates. **RESEARCH THIS** — find references to validate the claim and provide citations. This is the thrust Jordan wants to take.
- **Explain UNIX philosophy** for this audience — they may not know it. "One tool does one job and does it well." This is foundational to understanding why Claude Code is built the way it is.
- **Start with `claude` command itself** — literally `claude` — talk about what happens when you type it before introducing any other concept. Let them see the tool before the theory.
- **Context window BEFORE CLAUDE.md** — current outline introduces CLAUDE.md too early. Context window is the foundational concept; CLAUDE.md is one of several things that consumes context. Order: `claude` command → context window → then CLAUDE.md and other elements.
- **Find earlier Claude Code elements research** — Jordan believes we dumped out the elements of Claude Code in an earlier research round, possibly in README-THEAGENCY.md. Start from that list when describing what Claude is.
- **Plan Mode vs Ultraplan** — must contrast: when to use which, the cost of each, how they differ (local vs cloud, blocking vs non-blocking, model differences).
- **Token economics as an Agency advantage** — the-agency is **parsimonious/frugal** with tokens. People complain about usage limits but are burning tokens on huge dumps (command output, log streaming — "like asking someone to read a 50MB log dump"). The-agency's approach to context management is a competitive advantage.
- **Claude Code as a "harness" first** — at the very beginning, talk about Claude Code as a harness that does basic things, then layer on what makes it great for programming. Basic harness → programming capabilities → the-agency's extensions.
- **Claude Code is hard to set up** (point 1). **If you don't set it up well → significant token economic issues** both usage and context (point 2). These tie directly to Part 3 and why the-agency exists.
- **Jamon Holmgren #6 — STRONGLY DISAGREE** with "review every line of every change." Jordan says it's just not possible. Highlight the disagreement explicitly. Then follow-up slide: we don't review every line manually — **we do it with agents** through quality gates. This is where the-agency's QG system comes in.

### Part 3: TheAgency + Valueflow — revisions

- **Drop "Rails model" / "convention over configuration"** reference — insider baseball, will go over this audience's heads. Find a more accessible analogy or just describe what it means directly.
- **"Discovered every friction point" is overclaiming** — say "discovered a lot of them, but we are constantly discovering more." Honest framing.
- **Iterations overlapped** — the three iterations weren't sequential. Could say Feb–April broken into phases, and applying it to monofolk in March–April is where we got a lot of validation. The monofolk work validated the framework.
- **Walk through a Valueflow + OODA diagram** — probably won't have slides for this section, just walk them through the picture. **The picture/diagram is critical.** Also confirms an **mdslidepal requirement**: must be able to display images/diagrams.
- **Different kinds of quality gates and different kinds of MAR** — talk about the variety. Not all QGs are the same depth; not all MARs use the same number of agents.
- **Start the agency section with a components overview** — Valueflow, agents, ISCP, Enforcement Triangle, etc. Overview first, then dig into each component. Don't jump straight into detail.
- **Three experience pillars rework:**
  - Current: UX / PX / AX
  - Jordan's revision: maybe **HX** (Human Experience) and **AX** (Agentic Experience) instead of UX/PX/AX. PX is just human UX under another name.
  - Key point: tools today have great UX/DevEx but **horrible AX** (the agent's experience is terrible — permission prompts, context limits, no identity, no memory between sessions).
  - The human in the loop is the **principal**. That's the framing.

### Part 4: Guided Build — no changes yet
Jordan is up to Part 4 but paused here to hand over for reflection and 1B1.

### New feedback item to capture
**Remote control mobile UI — input dialog collapse/expand:**
When on the mobile app using remote control and giving voice/text input, the dialogue box expands and starts covering the agent's response. There is no way to easily collapse it. Should have a simple **collapse/expand toggle** so the user can:
- See as much of the agent's response as possible (collapsed input)
- See as much of their own response as possible (expanded input)
- Switch between the two easily

### Protocol capture — "Over" / "Over and out"
**Radio communications protocol for remote-control voice sessions:**
- **"Over"** = I'm done with this batch of input. Your turn. Ask questions if you need to.
- **"Over and out"** = I'm done. Ask questions if you need to, but if not, execute.
- Especially important in remote-control sessions where audio input creates many small messages.
- Between "Over" signals: captain should receive, parse, and think about the messages but **NOT respond or act until "Over" is received.**
- Capture as a convention in the captain's instructions. Similar to how radio operators batch their transmissions.

---

*Transcript updated with full mobile review session.*

---

## 1B1 Discussion — Outline Revisions

### Round 1: Part 2 flow and 4 Ds placement

**Captain proposed** new Part 2 structure: agentic harness concept → Anthropic safety → Boris origin → `claude` command → context window → 4 Ds → elements → token economics → Jamon → career progression.

**Jordan's response:**
> "Before we get into the agentic harness, we actually talk about Anthropic and what they've built. Talk about the 4 Ds up there. Talk about their focus on safety. Talk about the break with OpenAI. Because of what Sam wanted to do, and Dario/Daniela said no."

**Decision:** Part 2 starts with Anthropic (the company, the safety story, the break with OpenAI, the 4 Ds as their philosophical framework), THEN moves to what they built (the agentic harness → Claude Code → Boris and the coding focus).

### Round 2: SDLC gap, naming, and additional points

**Jordan's key points:**
1. **The SDLC gap is about the agentic world** — nothing covers SDLC in an agentic world. All existing methodologies (Waterfall, Agile, Scrum, Lean Startup, DevOps) were built for a non-agentic world. Nobody has reimagined the lifecycle for agents. Ties to HX vs AX.
2. **Start Claude Code with Anthropic** — who they are, the safety story, the OpenAI break, then what they built. The 4 Ds go here as Anthropic's philosophical framework.
3. **Naming distinction is critical:**
   - **Valueflow** = the AI ADLC (the methodology)
   - **The Agency** = the platform/framework/tooling that implements Valueflow
   - Both from The Agency Group AI
   - These are DIFFERENT things. Must be consistent.
4. **Research request:** validate that no AI ADLC exists in the wild. Research agent launched.
5. **mdpal-app needs iPadOS + iPhone** — dispatch sent to mdslidepal-mac about platform expansion for future planning.
6. **Case study moment:** this entire voice-driven remote-control collaboration session (McDonald's breakfast walk, voice input, no typing) IS a case study for the workshop. Capture it.
7. **Over/Over-and-out protocol** — radio communications convention for agent interaction. Must be captured in CLAUDE.md and /discuss skill.

**Jordan's confirmation:** "Make it so."

**Decision:** All points confirmed. Research running. Dispatch sent. Naming distinction locked. Outline revision proceeding.

### Protocol: Over / Over-and-Out

**Jordan's directive:** Capture this in CLAUDE.md. Use in 1B1 and /discuss sessions.

- **"Over"** = your turn to talk. A nod. Agent responds, asks questions, discusses.
- **"Over and out"** = your turn. Move to the next element unless you have something to say.
- **Between signals:** agent receives, parses, thinks about messages but does NOT respond or act until "Over" is received.
- **Especially critical for:** remote-control voice sessions where audio input creates many small messages. The agent must batch-receive without interrupting the principal's train of thought.
- **Origin:** radio communications protocol adapted for human-agent interaction.
- **Jordan:** "I wanna get this in there because we need this. It is beautiful."

---

## Continued mobile review — second batch

### Protocol refinement (final version)

Jordan refined the Over/Over-and-out protocol with a full state machine:

| Signal | Agent behavior |
|---|---|
| *(streaming — no signal)* | Receive, parse, think. Do NOT respond. |
| **"Over"** | Mirror back what you heard. Rephrase/reframe. Discuss. Ask questions. **NO action taken.** |
| **"Over and out"** | State intended actions. Ask "does that work?" **Hard gate** for destructive/irreversible actions (wait for explicit yes). **Soft gate** for low-risk work (proceed unless principal objects). |

Key principle: **Until you get "out," you don't take any action.** "Over" is discussion only. "Over and out" is the execution boundary.

This applies to ALL back-and-forth, not just voice/remote-control. Every 1B1, every /discuss, every review conversation.

Auto-start rule: **Any time you enter 1B1, a transcript should be kicked off if one isn't already running.**

### Additional points captured

**The "slamming escape" scenario (for article + workshop):**
> "I wanna describe the situation where I asked you a question and somehow that triggers you to do something. And you go off and start doing a whole bunch of work, in some cases destructive, and I'm sitting there slamming escape until I can interrupt you. And then you go, what was that about? And then we have to unwind."

This is the pain point the Over protocol solves. Every AI coding assistant user has lived this moment.

**Article quality — beefy, cited piece:**
Not a quick blog post. Substantive with research citations. One of the first publications on the-agency-group.ai blog/website.

**Website content architecture — two feeds:**
- **Papers** — substantive, research-cited, deep pieces (the Over piece qualifies)
- **Articles** — blog-style, summaries, thread-weaving, pointing to papers

**Radio protocol dating:**
- Procedure words trace to **1860s Morse telegraphy** (procedural signs)
- Spoken radio prowords formalized during **WWII (1940s)**
- Jordan's preferred framing: "What does a **pre-World War II protocol** teach us" — starting with Morse, formalized later to voice radio

**Demo slides — two-column markdown build:**
Not screenshots. Actual slides with two columns:
- Column A: git init → claude (what you get with raw Claude Code)
- Column B: git init → agency init → claude (what you get with The Agency)
- Progressive build, final comparison after first `claude` run

**Valueflow vs The Agency distinction (continued):**
- **AIADLC is Valueflow.** The Agency is the platform that implements Valueflow.
- Must make this distinction consistently.
- Give nod to other published frameworks (AWS AI-DLC, etc.) but stress the MULTI-AGENT nature as the differentiator
- "This is not about me working with 1 agent. This is me working with multiple agents, and then collaborating with other humans who have their own agents."

**mdpal-app platform expansion:**
Jordan wants mdpal-app (and by extension mdslidepal) to have iPadOS and iPhone versions. Dispatch #211 sent to mdslidepal-mac.

**Research results reported:**
1. **AI ADLC landscape:** AWS AI-DLC is the closest competitor. Defensible claim: "first methodology for structured human-agent collaborative development." Saved as seed.
2. **1B1 + Over protocol novelty:** Confirmed novel — no published formalized protocol for structured human-AI work session turn-taking. Defensible claim.
3. **Radio protocol history:** 1860s Morse → WWII voice radio.

### 1B1 on captain's questions — resolved

1. **Agency plug in article:** Bottom. Lead with pain point, not the sell. ✅
2. **Revised outline timing:** Produce now, Parts 1-3 updated, Parts 4-5 as-is pending review. ✅
3. **Over/Over-and-out execution boundary:** Hard gate for destructive actions (wait for yes), soft gate for low-risk (proceed unless objection). ✅

### Case study note

**Jordan:** "This what we're doing here is an incredible case study. I wanna capture this whole collaboration via remote control and voice notes. Everything I'm doing here is voice. I'm not typing at all. Walked down to McDonald's, grabbed breakfast, ate at McDonald's, now walking home."

This entire session — voice-only mobile input via Claude Desktop remote control, Over/Over-and-out protocol in live use, captain holding and batching, research agents spinning in background while principal walks — IS the case study for the article AND the workshop.

---

*Captain now executing: revised outline v2 + transcript commit. Jordan arriving home shortly.*
