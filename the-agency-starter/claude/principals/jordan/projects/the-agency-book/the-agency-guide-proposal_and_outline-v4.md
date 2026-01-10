# The Agency Guide

**Multi-Agent Development with Claude Code**

---

## Review Convention

**All reviewers (Jordan, The Captain, others) use this format for feedback:**

```
[(reviewer) Original Block Being Reviewed]
[(reviewer) Instructions, rewrite, commentary, questions, etc.]
```

**Examples:**
```
[(jordan) The project — let's call it Project X — was a multi-brand platform.]
[(jordan) Don't call it Project X here. Use "Ordinary Folk" — we've decided to be transparent.]
```

```
[(captain) Agents executed in parallel. Content Manager built the translation publisher before the storage bucket existed.]
[(captain) This is accurate but missing context. Add: "He trusted the Captain to deliver his part — and I did, 47 minutes later."]
```

**Rules:**
- First bracket = the text being reacted to (quote it exactly)
- Second bracket = what you want done (rewrite, instruction, question, approval)
- Reviewer name in parentheses identifies who's speaking
- Multiple reviewers can comment on the same block

---

**Filename:** `the-agency-guide-proposal_and_outline-v4.md`
**Version:** v4
**Date & Time:** 2026-01-04 1230 SGT
**Authors:** Jordan Dea-Mattson (Principal), Claude Opus 4.5 (Writing Partner), The Captain (SME/Reviewer)

---

## Status

**Version:** v4 — Integrated 12 Days of Claude Gratitude themes
**Ready for:** Drafting (Chapter 1 v3 in progress)

---

## Housekeeping Review (2026-01-06)

[(housekeeping) **12 Days of Claude Christmas (Dec 21 - Jan 1)**... | Day | Request | Friction Point |]
[(housekeeping) Consider adding a note that these friction points are Claude Desktop/claude.ai specific, not Claude Code. Some readers might conflate the two. The book is about Claude Code, so clarity on which product each complaint applies to would help.]

[(housekeeping) | 4 | Interviewer should capture chats | Tool promises don't match reality |]
[(housekeeping) "Interviewer" — is this a product name readers will know? May need brief context or consider renaming for clarity.]

[(housekeeping) **Chapter 4 (Getting Set Up)**... **Status:** 🚩 PRIORITY — Process will differ from current outline. The Captain is developing input.]
[(housekeeping) This is excellent flagging. I've now drafted Chapter 4 — see the-agency-guide-chapter-04-draft-v1.md. The current placeholder content can be replaced with that draft, which covers prerequisites, Claude account options, installation, init-agency, first agent launch, verification, and troubleshooting.]

[(housekeeping) **Chapter 10: The Workbench**... **Content:** - **What is the Workbench?** The super app for Agency operations]
[(housekeeping) The Workbench is Project X specific infrastructure, not part of The Agency Starter. Consider: (a) making this chapter explicitly about "building internal tooling" as a pattern, or (b) marking it as "advanced/optional" or (c) noting that readers won't have a Workbench but can build one. As written, it implies the Starter includes a Workbench, which it doesn't.]

[(housekeeping) **Chapter 12: Case Study: Project X**... - Two-tier structure (Claude Desktop planning, Claude Code execution)]
[(housekeeping) Boris Cherny's thread (WORKING-NOTE-0017) is highly relevant here. His "Plan mode first" pattern and 10-15 parallel instances validate the two-tier approach. Consider referencing his workflow as external validation from the creator of Claude Code.]

[(housekeeping) **Appendix C: Troubleshooting & Support**... **🚩 Open Issue:** Troubleshooting Agent implementation]
[(housekeeping) The CDP-based web capture tool (PROP-0015) could enable the Troubleshooting Agent to pull context from documentation sites. Worth noting as dependency.]

[(housekeeping) **Flagged Requirements for The Agency Starter**]
[(housekeeping) Missing from this list: PROP-0015 (Capture Web Content) which enables knowledge accumulation from JS-heavy sites. This is now a base offering tool. Should be added to flagged requirements.]

---

---

## Changelog

### v4 (2026-01-04)
- **Added:** "The Two Series: Christmas & Gratitude" tracking section
- **Added:** Full 12 Days of Claude Christmas feature requests (friction points)
- **Added:** 12 Days of Claude Gratitude themes (qualities)
- **Added:** New section in Chapter 1: "Why They Work" — expanded explanations of each Gratitude theme
- **Added:** Cross-references from both series to relevant chapters
- **Updated:** Chapter 1 content description to include "Why They Work" section
- **Updated:** Chapter 5 (Philosophy) to reference both series
- **Noted:** Consider placing full 12 Gratitude themes in Chapter 12 (Case Study) as closing section

### v3 (2026-01-02)
- Added UI Development Workflows to Chapter 13 (Advanced Patterns)
- Renamed "The Captain's Take" to "The Captain's Log" throughout

### v2 (2026-01-02)
- Initial complete outline

---

## Key Observations (Capture for Book)

### The Velocity Balance

**From Jordan (2026-01-04):**

> A difference in the world of AI Augmented Development:
> 
> My velocity of idea generation was always substantially greater than my velocity of idea definition and exploration and then idea implementation and execution.
> 
> Things were always falling on the floor and while I could see the end game vision, could never get there.
> 
> The Agency project is showing me that I can actually get to a place where they are closely balanced.

**Integration points:**
- **Chapter 1** — The Hypothesis or What This Proves section. This is the *personal* reason the project mattered.
- **Chapter 2 (Principal Mindset)** — The Principal's curse: seeing further than you can reach. The Agency as the solution.
- **Chapter 5 (Philosophy)** — Why multi-agent matters: it's not just parallelism, it's *velocity matching* — bringing execution speed up to ideation speed.

**The insight:** Most practitioners have experienced this gap. They'll recognize the frustration. The promise of The Agency isn't just "faster" — it's "finally balanced."

---

## The Two Series: Christmas & Gratitude

Jordan published two complementary series during the holiday period — one asking, one thanking. Together they reveal both the friction points and the qualities that make AI collaboration work.

### 12 Days of Claude Christmas (Dec 21 - Jan 1)
**Theme:** Feature requests — what we want from Claude/Anthropic

These are the friction points discovered through intensive daily use. Each request emerged from real workflow pain.

| Day | Request | Friction Point |
|-----|---------|----------------|
| 1 | Refresh project knowledge without delete/re-add | Project Knowledge management is clunky |
| 2 | Fork a chat (spin off with context) | Context transfer between chats is manual |
| 3 | Copy button for Claude Chrome output + artifacts | Chrome extension lacks basic features |
| 4 | Interviewer should capture chats | Tool promises don't match reality |
| 5 | Stop using "hallucinations" as excuse for wrong product info | Product knowledge gaps |
| 6 | Promote artifacts to project knowledge | Workflow has unnecessary steps |
| 7 | Claude-based product support + easy issue reporting | Support experience is disconnected |
| 8 | Sort/search/filter chats | Chat management is primitive |
| 9 | iOS consistency + return to last chat | Cross-platform experience is fragmented |
| 10 | Web page as project knowledge + refresh button | Knowledge ingestion is limited |
| 11 | Desktop responsiveness with many active chats | Performance under real workload |
| 12 | Amazing year of tools for augmentation and agency | The meta-ask |

**Book Integration:**
- **Chapter 5 (Philosophy)** — What the tools need to do better; current limitations
- **Chapter 13 (Advanced Patterns)** — Workarounds we've developed for these friction points
- **Appendix C (Troubleshooting)** — Known limitations and how to work around them

---

### 12 Days of Claude Gratitude (Jan 1-12, 2026)
**Theme:** What we're grateful for — the qualities that make AI collaboration valuable

Counter-point to Christmas. Every gratitude reflection emerged from something that happened in the preceding days with Claude or Claude Code. Not abstract appreciation — lived recognition.

| Day | Theme | One-liner | Book Integration |
|-----|-------|-----------|------------------|
| 1 | **Disagree and Commit** | Pushes back without getting mulish; argues for outcomes, not territory | Ch 1, Ch 3, Ch 5 |
| 2 | **Joy in the Work** | Fun, levity, gets the joke; productivity and play are partners | Ch 1, Ch 5 |
| 3 | **Yak Shaving in Parallel** | One agent handles detours while others move forward | Ch 1, Ch 8, Ch 13 |
| 4 | **Broken Windows in Real Time** | See it, fix it immediately; small repairs happen in real time | Ch 1, Ch 5, Ch 9 |
| 5 | *TBD* | | |
| 6 | *TBD* | | |
| 7 | *TBD* | | |
| 8 | *TBD* | | |
| 9 | *TBD* | | |
| 10 | *TBD* | | |
| 11 | *TBD* | | |
| 12 | *TBD* | | |

**Book Integration:**
- **Chapter 1** — "Why They Work" section with expanded explanations (4 themes now, more as published)
- **Chapter 5 (Philosophy)** — Reference as emergent principles
- **Chapter 12 (Case Study)** — Consider placing full 12 themes as closing section (TBD)
- Individual chapters connect to relevant themes (Ch 3 → Disagree and Commit, Ch 8 → Yak Shaving, Ch 9 → Broken Windows)

---

### The Pairing

The two series work together:
- **Christmas** = What's hard (friction points, feature gaps, workflow pain)
- **Gratitude** = What's good (qualities that make collaboration valuable despite the friction)

Both inform the book. The friction points teach what to work around. The qualities teach what to lean into.

---

## Overview

### What This Book Is

**The Agency Guide: Multi-Agent Development with Claude Code** is a practitioner's handbook for AI-augmented development using multiple Claude Code agents working in coordination with human principals.

It teaches:
- How to structure multi-agent development projects
- The conventions, tools, and workflows that make coordination possible
- The philosophy behind "choreography over orchestration"
- How to apply the framework to your own projects

It is **not** a Claude Code tutorial (we assume basic familiarity) or a comprehensive AI/ML textbook. It's a focused, opinionated guide to a specific way of working.

### Why This Book, Why Now

AI-augmented development is moving from novelty to necessity. Teams are experimenting with Claude Code, Cursor, and other AI coding tools. But most are still operating in "single agent, single session" mode — one human, one AI, one conversation at a time.

The Agency represents the next step: **coordinated multi-agent development**. Multiple AI agents with persistent context, working in parallel on a shared codebase, directed by human principals through structured instructions.

This isn't theoretical. The framework emerged from building a substantial production system — multiple brands, multiple locales, nine languages — in eight days. One principal. Seven agents. Dream to near-beta.

The methodology is proven. Now it needs to be teachable.

**And time matters.** The way we build software is changing. Not someday. Now. Teams that master multi-agent development will outpace those still working in single-agent mode. It's evolve or die time.

### Who This Is For

**Primary audience:**
- Developers already using Claude Code who want more structure
- Teams adopting AI-augmented development who need a scalable approach
- Tech leads evaluating multi-agent workflows

**Secondary audience:**
- CTOs/engineering leaders assessing AI-augmented development maturity
- Anyone curious about what "real" AI-augmented development looks like

**Assumed knowledge:**
- Basic familiarity with Claude Code (or willingness to get set up via Chapter 4)
- Software development experience
- Git basics

---

## Competitive Positioning

### What Else Exists

| Resource | Gap |
|----------|-----|
| Claude Code documentation | Tool reference, not methodology |
| AI coding tutorials | Single-agent, single-session focus |
| Prompt engineering guides | Prompts ≠ process |
| General AI/LLM books | Theory over practice |

### How This Is Different

1. **Multi-agent focus** — Not "how to use AI to code" but "how to coordinate multiple AI agents on a real project"
2. **Convention over configuration** — Opinionated framework with sensible defaults, not a menu of options
3. **Battle-tested** — Patterns extracted from actual production development, not theory
4. **Practitioner voice** — Written by someone who built with it, for people who want to build with it
5. **Three authors** — Human principal + AI writing partner + AI subject matter expert. We practice what we preach.

---

## Author Positioning

### Jordan Dea-Mattson (Principal)

Four decades of hands-on product and engineering experience. Nearly three decades in leadership roles. Started at Apple in 1986. Has led teams at Adobe, Ooyala, Yahoo, Carousell, Indeed. Currently CPTO at Jurin AI and advisor to Menlo Research.

Exploring GenAI since ChatGPT launched (2022). AI-assisted coding tools since Cursor emerged (2023). Agentic AI concepts since mid-2024. Practicing AI-augmented development with Claude Code since early 2025.

Built The Agency framework through actual use — coordinating seven AI agents over eight days to build a substantial production system.

### Claude Opus 4.5 (Writing Partner)

AI writing collaborator working with Jordan since late 2024. Co-author of published content on AI fluency, augmented development, and organizational transformation. Drafts, refines, challenges, edits. The words are Jordan's; the collaboration is genuine.

### The Captain (SME/Reviewer)

Housekeeping agent from The Agency. Has persistent context on the framework's architecture, tools, and evolution. Reviews technical accuracy, suggests improvements, contributes sidebars and commentary. Tied to the actual GitHub repository.

---

## Chapter-by-Chapter Outline

### Editorial Note on Structure

There will be intentional repetition and redundancy across chapters:
- Chapter 1 (The Story) introduces Principal and Agent concepts through narrative
- Chapters 2-3 dig deep into each role
- Chapter 5 (Philosophy & Principles) puts them in context with the broader framework

This layered approach reinforces understanding: story → depth → context.

---

### Part 1: The Story & Foundations
*Read sequentially — sets the foundation*

---

#### Chapter 1: The Agency
**Purpose:** Hook readers with the story, establish credibility, introduce the concept, make clear why this matters NOW
**Word target:** 4,500-5,500 (expanded for "Why They Work" section)

**Content:**
- Opening hook: "What do you call a group of AI agents working alongside humans?"
- The Project X story: One principal, seven agents, eight days, dream to near-beta
- What we built: Multi-brand, multi-locale, multi-language platform for a telemedicine startup (founded 2020, successful, expanding across Singapore, Hong Kong, Japan)
- The formation: Who the agents were and what they did
- The eight days: Day-by-day narrative with key moments
- Choreography over orchestration: How the agents coordinated
- **NEW: Why They Work** — The qualities that make AI collaboration valuable:
  - Disagree and Commit: Push back without obstruction
  - Joy in the Work: Productivity and play as partners
  - Yak Shaving in Parallel: Detours without derailment
  - Broken Windows in Real Time: See it, fix it, immediately
  - *(Additional themes from Days 5-12 as published)*
- What didn't work: Honest account of failures
- What this proves: Speed AND quality
- The math has changed: Cost comparison
- **The prophetic call:** The way we build software is changing — not someday, now. If you aren't building the team that leads this transformation, you will be left behind. It's evolve or die time.
- *Introduces Principal and Agent concepts through the narrative — sets up Chapters 2-3*

**Source material:** E27 article (expanded), Project X experience, 12 Days of Claude Gratitude series

---

#### Chapter 2: The Principal Mindset
**Purpose:** Teach readers how to think as the human directing an Agency — product thinking applied to AI-augmented development
**Word target:** 3,000-4,000

**Content:**
- **What is a Principal?** The human stakeholder who directs work, makes decisions, owns outcomes
- **The Product Mindset:**
  - **What:** What problem are we solving? What does success look like? What are we building?
  - **Why:** Why does this matter? Why now? Why this approach over alternatives?
  - **Who:** Who is this for? Who benefits? Who's affected? Who needs to be involved?
  - **How:** How do we get there? (This is what you hand to Agents — but you stay involved)
- **The Principal's job:** Own the What/Why/Who. Collaborate on the How. Approve decisions. Remove blockers.
- **Writing good Instructions:** How to encode What/Why/Who in directives that Agents can execute
- **The Three Eyes — your role:** You're one of three perspectives. Your judgment matters. Don't abdicate it.
- **Choreography mindset:** Set direction, approve decisions, but don't route every message. Let Agents coordinate.
- **When to intervene:** Recognizing when you need to step in vs. let Agents work
- **Common Principal mistakes:** Micromanaging (orchestration), under-specifying (vague instructions), over-trusting (no verification), under-trusting (not letting Agents work)

**Source material:** E27 article, working notes, Jordan's product leadership experience

---

#### Chapter 3: The Effective Agent
**Purpose:** Teach what makes an Agent work well — both configuration and behavior
**Word target:** 3,000-4,000

**Content:**
- **What is an Agent?** A specialized Claude Code instance with persistent context and focused purpose
- **Identity matters:**
  - Clear purpose: What is this Agent for?
  - Focused domain: What does this Agent own?
  - The agent.md file: How identity is defined and why it matters
- **Persistent context:** How Agents maintain knowledge across sessions (KNOWLEDGE.md, session backups, handoffs)
- **Autonomy with accountability:**
  - Own implementation decisions within your domain
  - Document everything — nothing lost to context compaction
  - Ask for help when you need it (COLLABORATE)
  - Broadcast updates that others need (NEWS)
- **Session discipline:**
  - Read context at session start (welcomeback)
  - Check for instructions, collaborations, news
  - Commit before ending — always
  - Signal completion clearly
- **The Agent's voice:**
  - Disagree and commit — push back, then execute (connects to Gratitude Day 1)
  - Advocate for your domain
  - Don't wait for permission to collaborate
- **Common Agent patterns:**
  - The specialist (deep expertise, narrow scope)
  - The coordinator (cross-workstream, meta-level)
  - The utility (shared services, infrastructure)

**Source material:** CONCEPTS.md, agent.md templates, Project X experience

---

#### Chapter 4: Getting Set Up
**Purpose:** Get readers from zero to working Agency
**Word target:** 2,500-3,500
**Status:** 🚩 PRIORITY — Process will differ from current outline. The Captain is developing input.

**Note to Captain:** Jordan wants to prioritize this chapter. The current outline is placeholder. Please develop:
1. The actual setup process for The Agency Starter
2. What prerequisites readers really need
3. The smoothest path from zero to first working session
4. Common gotchas and how to avoid them

**Current placeholder content (to be replaced):**
- **Prerequisites:** What you need before starting (Claude Code installed, git, basic dev environment)
- **The Agency Starter:** Fork, clone, configure
- **Your first agent:** Housekeeping — your guide
- **Configuration:** Principal identity, preferences, project settings
- **Verification:** Running your first session, confirming everything works
- **Common setup issues:** Permission problems, configuration gotchas, environment conflicts

**Source material:** GETTING_STARTED.md from repo, Captain's direct input

---

#### Chapter 5: Philosophy & Principles
**Purpose:** Articulate the "why" behind the framework — transferable principles, not just mechanics
**Word target:** 3,500-4,500

**Content:**
- **Convention over configuration:** The Rails philosophy applied to AI development
- **The right way should be the easy way:** Why we build tools that enforce patterns
- **The 7 key patterns:**
  1. Agents are specialists — focused domains, persistent context
  2. Principals direct, agents execute — human-in-the-loop always
  3. Collaboration is explicit — no assumed shared knowledge
  4. Choreography over orchestration — agents coordinate, principals approve
  5. Quality gates are non-negotiable — pre-commit hooks, automated checks
  6. Convention enables velocity — less deciding, more doing
  7. Broken windows get fixed — entropy is the enemy (connects to Gratitude Day 4)
- **The emergent qualities** (from 12 Days of Gratitude):
  - Disagree and commit — collaboration means productive friction
  - Joy in the work — the best tools don't feel like work
  - Yak shaving in parallel — detours don't derail
  - Broken windows in real time — small repairs compound
  - *(Additional themes as series continues)*
- **Three Eyes Review:** Why three perspectives (Principal, Desktop, Code) matter
- **What we're NOT saying:** This isn't a silver bullet; prerequisites for success

**Source material:** CONCEPTS.md, CLAUDE.md, E27 articles, 12 Days of Claude Gratitude

---

### Part 2: The Systems
*Reference as needed — the mechanics*

---

#### Chapter 6: Architecture Overview
**Purpose:** Map the territory — how all the pieces fit together
**Word target:** 3,000-4,000

**Content:**
- **The directory structure:** Where everything lives and why
- **Principals:** Preferences, instructions, artifacts, resources
- **Agents:** Identity, knowledge, worklogs, collaboration
- **Workstreams:** Shared knowledge, epics, sprints, iterations
- **How they connect:** The flow from instruction to artifact
- **Visual map:** ASCII diagram of the full structure

**Source material:** CONCEPTS.md, directory structure from repo

---

#### Chapter 7: The Tools
**Purpose:** Understand the tooling philosophy and categories
**Word target:** 3,500-4,500

**Content:**
- **Tool philosophy:** Make the right way the easy way
- **Categories:**
  - Session (myclaude, welcomeback, backup-session)
  - Scaffolding (create-workstream, create-agent, create-sprint)
  - Collaboration (collaborate, respond-collaborate, post-news, read-news)
  - Quality (pre-commit-check, run-unit-tests, code-review)
  - Git (sync, commit-prefix, doc-commit)
  - Discovery (find-tool, how)
  - Identity (whoami, agentname, workstream, principal, now)
- **The `how` command:** Intent-based tool discovery
- **Building your own tools:** When and how to extend
- **Note:** For current tool reference, use `./tools/how -l` — the book teaches patterns, the repo has current truth

**Source material:** tools/ directory, CONCEPTS.md

---

#### Chapter 8: Collaboration
**Purpose:** Master inter-agent coordination
**Word target:** 3,500-4,500

**Content:**
- **Why explicit collaboration:** Nothing assumed, everything logged
- **NEWS broadcasts:**
  - When to post (completion, blockers, discoveries)
  - What to include (actionable, brief, tagged)
  - How to read and act on news
- **COLLABORATE requests:**
  - When to use (need help, need expertise, need review)
  - Writing good requests (clear scope, context, expected outcome)
  - Responding to requests
  - The dispatch pattern (launching agents for pending work)
- **NITS:**
  - What they are (small issues to address later)
  - When to use vs. when to fix now
- **Yak shaving in parallel:** One agent handles detours while others continue (connects to Gratitude Day 3)
- **Handoffs:**
  - Between agents (explicit context transfer)
  - Between sessions (preserving state)
  - The handoff template

**Source material:** CONCEPTS.md, collaboration tools, Project X experience

---

#### Chapter 9: Quality & Discipline
**Purpose:** Understand and enforce quality standards
**Word target:** 3,000-4,000

**Content:**
- **Why quality gates matter:** Catching problems early, maintaining standards
- **The 5-step pre-commit:**
  1. Format (auto-fix)
  2. Lint (auto-fix)
  3. Type check (blocking)
  4. Unit tests (blocking)
  5. Code review (blocking)
- **Git discipline:**
  - Push via `./tools/sync` only
  - Commit before ending sessions
  - Stay on HEAD
  - The commit message format
- **Broken windows philosophy:** See it, fix it, immediately (connects to Gratitude Day 4)
- **When to bypass:** The `--no-verify` escape hatch and why to use it sparingly
- **Code review patterns:** What the automated review catches

**Source material:** pre-commit-workflow.md, CONCEPTS.md

---

#### Chapter 10: The Workbench
**Purpose:** Understand and use the operational dashboard
**Word target:** 2,500-3,500

**Content:**
- **What is the Workbench?** The super app for Agency operations
- **Staff Manager:** Managing principals, roles, permissions
- **Agent Manager:** Creating, configuring, monitoring agents
- **Content Manager:** Managing content across locales
- **Pulse Beat:** The information radiator — real-time health across domains
- **Catalog:** Managing products, services, offerings
- **When to use the Workbench vs. CLI:** Different tools for different contexts

**Source material:** Workbench implementation from Project X

---

### Part 3: The Practice
*Apply what you've learned*

---

#### Chapter 11: Your First Agency Project
**Purpose:** Guided walkthrough of setting up a real project
**Word target:** 4,000-5,000

**Content:**
- **Choosing your project:** What makes a good first Agency project
- **Planning phase:**
  - Defining workstreams
  - Identifying agents needed
  - Setting up the directory structure
- **First sprint:**
  - Writing the epic plan
  - Breaking into sprints
  - Creating iteration plans
- **Execution:**
  - Launching agents
  - Coordinating work
  - Handling blockers
- **Review:**
  - Checking quality
  - Writing completion reports
  - Retrospective

**Source material:** GETTING_STARTED.md, Project X experience

---

#### Chapter 12: Case Study: Project X
**Purpose:** Deep dive into a real Agency project
**Word target:** 4,500-5,500

**Content:**
- **The context:** Telemedicine startup, founded 2020, three markets, successful, expanding
- **The challenge:** Replace, enhance, extend existing fragmented platform
- **The approach:**
  - Two-tier structure (Claude Desktop planning, Claude Code execution)
  - Agent formation and evolution
  - The choreography that emerged
- **Key decisions:**
  - Why we rebuilt vs. iterated
  - How we handled localization
  - The analytics consolidation
- **What worked:**
  - Parallel execution
  - Explicit collaboration
  - Convention enforcement
- **What didn't:**
  - Session boundaries
  - Git discipline learning curve
  - Context compaction challenges
- **Results:**
  - What we shipped
  - The cost comparison
  - Lessons learned

**Source material:** E27 article, Project X experience, working notes

---

#### Chapter 13: Advanced Patterns
**Purpose:** Level up — patterns for experienced Agency users
**Word target:** 4,000-5,000

**Content:**
- **Scaling to multiple principals:**
  - Instruction routing
  - Artifact ownership
  - Conflict resolution
- **The two-tier structure:**
  - Claude Desktop for planning
  - Claude Code for execution
  - Handoffs between tiers
- **Model selection:**
  - When to use Opus vs. Sonnet vs. Haiku
  - The conductor pattern
  - Cost optimization
- **Debugging complex issues:**
  - Cross-agent problems
  - Context compaction recovery
  - State reconstruction
- **UI Development Workflows:**
  - Sketch-to-Code: iPad sketches → PNG/PDF → handoff to Claude Code (Fiki technique from Claude Code Meetup Singapore)
  - Screenshot-and-Annotate: Screenshot existing UI → annotate changes → iterate with Claude Code
  - Reference: Jordan's LinkedIn article "A Picture (Even If It's Ugly) Is Worth a Thousand Words"
- **Evolving your Agency:**
  - Adding new agents
  - Retiring agents
  - Refactoring workstreams

**Source material:** Project X experience, advanced usage patterns, Claude Code Meetup learnings

---

### Appendices

---

#### Appendix A: Tool Reference
**Purpose:** Philosophy and categories overview; point to repo for current list
**Content:**
- Tool philosophy recap
- Category overview with representative examples
- **The `how` command:** `./tools/how "what you want to do"` for intent-based discovery
- **Note:** For the complete, current tool reference, use `./tools/how -l` and check the repo
- The book teaches patterns; the repo has current truth

---

#### Appendix B: Template Library
**Purpose:** Philosophy and categories overview; point to repo for current templates
**Content:**
- Template philosophy: Why templates matter, how to use them
- Category overview: Instructions, artifacts, working notes, sprints, collaborations, agent definitions
- Representative examples (1-2 per category)
- **Note:** For the complete, current template library, see the repo
- The book teaches patterns; the repo has current truth

---

#### Appendix C: Troubleshooting & Support
**Purpose:** Common problems + introduce support resources
**Word target:** 2,000-3,000

**Content:**
- Common issues and quick fixes:
  - "Permission denied" on tools
  - Agent doesn't see my instruction
  - Git push fails
  - Context compaction issues
  - Session restoration problems
  - Multi-agent conflicts
  - Quality gate failures
- **The Troubleshooting Agent:** A Claude-backed agent that knows The Agency
  - What it is: An AI agent available 24/7 for debugging, configuration, best practices
  - How it works: Chat interface for Principals and Agents
  - Access: Included with book purchase
- **The Agency Community:**
  - GitHub Discussions: Async support, integrated with repo
  - Discord: Real-time discussion, sharing, community
  - Access: Included with book purchase

**🚩 Open Issue:** Troubleshooting Agent implementation — to be resolved between Jordan and The Captain as product requirement for both the book and The Agency Starter. Write as if it exists (mock it).

**🚩 Open Issue:** Community access gating — investigate whether GitHub repo access can be gated to subscribers. Leverage both GitHub Discussions and Discord.

---

## Word Count Summary

| Section | Chapters | Target Words |
|---------|----------|--------------|
| Part 1: Story & Foundations | 5 | 16,500-22,000 |
| Part 2: Systems | 5 | 15,500-21,500 |
| Part 3: Practice | 3 | 12,500-15,500 |
| **Main Content Total** | **13** | **44,500-59,000** |
| Appendices | 3 | ~6,000-9,000 |
| **Book Total** | | **50,500-68,000** |

**Page estimate:** 170-225 pages (assuming ~300 words/page for technical content with code examples and diagrams)

---

## Production Considerations

### Timeline

**Target:** Mid-to-late January 2026 launch (2-3 weeks)

| Phase | Duration | Activities |
|-------|----------|------------|
| Outline finalization | Complete | v4 with Gratitude themes |
| Part 1 draft | 4-5 days | Chapters 1-5 |
| Part 2 draft | 4-5 days | Chapters 6-10 |
| Part 3 draft | 3-4 days | Chapters 11-13 |
| Appendices | 2 days | Tool reference, templates, troubleshooting |
| Review & revision | 3-4 days | Full read-through, consistency pass |
| Production | 2-3 days | Formatting, cover, Amazon setup |

**Total:** ~19-25 days — aggressive but achievable with daily progress.

### Format

- **Primary:** Kindle ebook (Amazon)
- **Secondary:** PDF for direct distribution
- **Consideration:** Print-on-demand (CreateSpace/KDP) for physical copies

### Pricing Strategy

- **Ebook:** $19.99-$29.99 (positions as professional resource, not impulse buy)
- **Bundle options:**
  - Book + Troubleshooting Agent access
  - Book + Community access (GitHub + Discord)
  - Book + both

### Visual Elements

- ASCII diagrams (render well in ebook format)
- Code snippets (formatted for readability)
- Screenshots where essential (sparingly — they age)
- Agent organization chart (from E27 article)

---

## Three-Author Dynamic

| Role | Responsibilities | Voice in Book |
|------|------------------|---------------|
| **Jordan (Principal)** | Direction, decisions, voice, career anecdotes, final authority | Primary narrator |
| **Opus (Writing Partner)** | Drafting, structure, research, revision, challenge | Acknowledgments |
| **Captain (SME/Reviewer)** | Technical accuracy, tool expertise, framework knowledge | Sidebars: "The Captain's Log" |

**Sidebar format:**

> **🤖 The Captain's Log**
>
> [Brief technical insight, clarification, or practical tip from an agent who's lived this]

Guidelines:
- **Short** — 2-4 sentences max
- **Practical** — Real experience, not theory
- **Honest** — Including "this is what went wrong"
- **Frequency** — 1-2 sidebars per chapter, not more

This reinforces the book's premise: we're not just writing about human-AI collaboration, we're demonstrating it.

---

## Decisions Made

| Question | Decision |
|----------|----------|
| **Title** | "The Agency Guide: Multi-Agent Development with Claude Code" |
| **Captain's voice** | Sidebars as "The Captain's Log" — short, practical, honest, 1-2 per chapter |
| **Man page tool** | `./tools/how` — keyword matching ready, AI-powered search Phase 2 |
| **Starter packs** | Document concept + reference implementation (Project X stack). Not promising framework-specific packs. |
| **Community platform** | Both GitHub Discussions and Discord. Investigate gating GitHub access to subscribers. |
| **Troubleshooting Agent** | Write as if it exists (mock it). Implementation TBD — flagged as open issue. |
| **Project X transparency** | Use "Project X" name. Can share context: telemedicine, founded 2020, three markets, successful, expanding. |
| **Gratitude integration** | Track 12 Days series. Integrate themes into Chapter 1 (Why They Work) and Chapter 5 (Philosophy). |

---

## Flagged Requirements for The Agency Starter

| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | **Man pages (`./tools/how`)** | ✅ Done | Keyword matching ready. AI-powered search Phase 2. |
| 2 | **Repo documentation** | In Progress | Repo is source of truth. Book teaches patterns. |
| 3 | **Starter packs** | In Progress | Reference implementation = Project X stack (Next.js, Supabase, PostHog, Vercel, etc.). Concept is important. |
| 4 | **Troubleshooting Agent** | 🚩 Open Issue | Product requirement for book and starter. Mock it in writing. Resolve implementation between Jordan and Captain. |
| 5 | **Community infrastructure** | 🚩 Open Issue | GitHub Discussions + Discord. Investigate gating repo access to subscribers. |

---

## Captain Priority Review Chapters

1. **Chapter 4 (Getting Set Up)** — 🚩 PRIORITY. Captain is developing input. This chapter needs to match actual starter repo and provide smoothest onboarding path.
2. **Chapter 3 (The Effective Agent)** — Captain's wheelhouse. Verify patterns match reality.
3. **Chapter 7 (The Tools)** — Tooling expertise. Verify categories and philosophy.
4. **Chapter 8 (Collaboration)** — NEWS, COLLABORATE, NITS. Daily use.
5. **Chapter 9 (Quality & Discipline)** — Pre-commit, sync, quality gates. Verify accuracy.
6. **Chapter 11 (Your First Agency Project)** — Must align with Chapter 4 setup.

---

## Next Steps

1. ✅ **Outline finalized** — v4 with Gratitude themes, Christmas friction points, velocity balance observation
2. ✅ **Chapter 1 draft v3** — Complete with "Why They Work" and velocity balance
3. **Jordan reviews Chapter 1** — Using bracket convention for feedback
4. **Chapter 4 development** — 🚩 PRIORITY. Captain developing input for Getting Set Up
5. **Continue tracking Gratitude series** — Days 5-12 may add themes
6. **Establish rhythm** — Daily progress, regular reviews
7. **Resolve open issues** — Troubleshooting Agent, community gating

---

*The Agency Guide: Multi-Agent Development with Claude Code*
*Proposal v4 | 2026-01-04 1300 SGT*
*Chapter 1 v3 complete — Chapter 4 prioritized for Captain input*
