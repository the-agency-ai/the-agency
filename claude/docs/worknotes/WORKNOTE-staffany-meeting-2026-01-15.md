# WORKNOTE: StaffAny Meeting - The Agency Overview & Pitch

**Date:** 2026-01-15
**Attendees:** Jordan, Janson Seah (StaffAny)
**Purpose:** The Agency overview and adoption discussion

---

## StaffAny Business Update

- Cash flow positive and sustainable business achieved in 2025
  - Team size: 40-45 people, lean operations
  - Strong Southeast Asia focus with HR software and payroll localization
- 2026 expansion plans
  - Strengthening Malaysia footprint significantly
  - Indonesia: stable market share, covers operational costs
- Localization remains major challenge for regional expansion

---

## Jordan's AI Development Project: "The Agency"

- SDLC framework for AI-augmented development addressing coordination gaps
  - Current problem: developers using AI tools individually without team coordination
  - Solution: structured workflows, processes, patterns and tooling for multiple agents + principals
- Key technical breakthroughs achieved
  - Multiple agents working in parallel coordination
  - UI design system extraction from Figma to Claude
  - Context management and state saving for agent workflows
  - Automated testing with screenshot comparison to mocks
- Product offerings structure
  - Open source "Agency Starter" (launching at Quad Code meetup)
  - Paid tools: Mock and Mark app ($20/month), feedback collection system
  - Consulting services for implementation and team transformation

---

## Current Role at Ordinary Folk

- Head of Product position (6-month probation to CTO promotion track)
- Healthcare D2C company: profitable, cash flow positive
  - High CAC but strong LTV ratios
  - Chronic condition treatments, stigmatized conditions
- Built complete system redesign over Christmas week using 7 parallel Claude instances
  - Front-end rebuild and back-end e-commerce infrastructure
  - Integrated AI agents for medical advice and customer support

---

## Collaboration Discussion

- Janson interested in adopting "The Agency" framework at StaffAny
- Proposed approach
  1. Greenfield project implementation (preferred over transformation)
  2. One-month pilot with dedicated team
  3. Success metrics and evaluation after 30 days
- Pricing structure discussed
  - Consulting fees + Claude token costs
  - Hosting fees for paid services
  - IP sharing agreements needed
- Next steps
  - Jordan to prepare proposal with fee ranges
  - Janson to discuss with CPO (Kai and Albert)
  - Target: one-month consultation/implementation project

---

## The Agency Features Presented

### 1. Overall Concept
- An SDLC-style framework for AI-augmented development
- Coordinates **multiple AI agents + multiple human principals** instead of everyone using tools ad-hoc
- Emphasizes **convention over configuration**, with tooling that enforces disciplined workflows

### 2. Core Capabilities and Workflow

**Coordinated Multi-Agent Work**
- Running up to **seven Claude Code agents in parallel**, collaborating on a single project
- Explicit patterns and processes for how agents and humans work together

**Two Flows: Product and Project**
- _Product flow_: start from product vision → AI breaks into epics, sprints, iterations; humans focus on big-picture and review
- _Project flow_: request-based work (e.g., refactors, specific changes) with clear docs and artifacts managed by agents

**Context and State Management**
- Systematic saving and restoring of state so you can stop/restart without losing context
- Instrumentation and logging so agents don't flood the context window with raw stdout
- Agents get success/failure, run IDs, and only the necessary results
- Clear strategy for extracting repeated behaviors into tools (especially safe read-only operations) with pre-granted permissions to reduce "mother may I" fatigue

### 3. UI / Design Tooling

**Design System Integration**
- Agent can **extract a design system from Figma** and "teach" it to Claude so generated UIs consistently match the design language

**Automated UI Testing**
- Uses **Playwright** (or similar) for UI tests that:
  - Run flows
  - Take screenshots
  - Compare them to mocks
  - Trigger automatic rework if they don't match

**Mock and Mark App (Paid)**
- Two modes:
  - **Mock**: super low-fidelity sketching (balsamiq-style or scribbles on paper) that feeds directly into the workflow and design system
  - **Mark**: annotate screenshots (scribble on UI PNGs) to specify changes; this flows straight into the agent workflow
- Target price: about **$20/month**, justified by speed and productivity gains

### 4. Back-End / Agent Infrastructure

**Agent Orchestration**
- System to coordinate multiple agents and enforce structured conventions (inspired by Ruby on Rails: convention over configuration enforced by tools)

**Agent-Friendly Logging**
- Tools write to a logging system; agents query logs when needed instead of ingesting everything into context

**Knowledge and Context Funnel**
- Layered design that moves from general to specific so context/knowledge is tightly managed and effective for agents

### 5. Feedback and Customer Insight Tooling (Paid Service)

**Rich In-Product Feedback Channel:**
- User can click an icon at any point in the app; system:
  - Captures device info, app state, what they were doing
  - Opens a conversation to classify input (bug, feedback, etc.) plus always an open-ended option
  - Allows multiple issues that can later be split into distinct tickets
- AI groups feedback to surface patterns (e.g., "people are struggling here", "crashes there")
- Offered as a hosted service: fees cover hosting, tokens, and a service margin

### 6. Agency Starter (Open Source) and Commercial Model

**Open Source "Agency Starter"**
- Installer + starter kits that can:
  - Set up new or existing projects
  - Auto-configure things like Supabase, Vercel
  - Get a project deployed to the cloud in a few hours
- Initial version tuned for **single principal + multiple agents**

**Upgraded / Paid Versions**
- Support for **multiple principals** and more complex team workflows
- Paid add-ons:
  - Mock and Mark app
  - Feedback collection service
  - Other advanced tooling not open-sourced

**Consulting and Transformation**
- Implement the Agency on greenfield projects
- Later support broader team transformation to AI-augmented development
- Evaluate which developers can adapt to this model and how to upskill or reassign others

### 7. Proof-of-Concept Example (Ordinary Folk)

- **Redesigned and rebuilt** their system over Christmas week using seven Claude Code instances in parallel
- Built:
  - A new front-end (high-quality UI consistent with design system)
  - E-commerce back end
  - Two AI agents: a **clinical/medical advisor** and a **customer support agent**, each with separate knowledge bases
- Demonstrated that once the design system was integrated, built the UI shown to Janson in about **six hours**

---

## Janson's Response

### Strong Interest and Validation
- Explicitly said it was a **"great"** and **"amazing"** project:
  - "I think you have a really cool project over here working on, you know, principal agent agency."
  - "Amazing project. How can I help and use it?"
- Immediately **interested in adopting it**:
  - "Do you want to adopt it?" / "I think it's something I'll try."

### Willingness to Experiment at StaffAny
- Proposed **trying it on specific projects**:
  - Wants to champion using the Agency for **two or three projects**, especially **greenfield work**:
    - "We have three, two projects. We should experiment with this workflow."
  - Agreed that **greenfield first** is better than full transformation.

### Open to a One-Month Pilot Engagement
- Liked the **one-month pilot** framing:
  - "We can target, you know, hey, let's have a one month, we call it a consultation, slash implementation, hands on, whatever you call that. Deliverable outcome."
- Emphasized wanting **clear success criteria**:
  - "We need to be clear on of course the fees for that project, what you hope to achieve…"

### Next-Step Alignment with Leadership
- Wants to involve **CPO and leadership**:
  - "We need to have a second chat with my CPO for sure like Kai and Albert."
- Sees his role as an internal **champion**:
  - "I think I will help by being a champion to say hey, you know, we have three, two projects. We should experiment with this workflow."

### Pricing and Budgeting Expectations
- Asked for a **proposal with fee ranges and structure**:
  - Wants clarity to compare with hiring another headcount:
    - "What I'm compromising is hiring one more person, for example, I'm very willing to invest in because if this works out well, I don't have to hire five people."
  - Requested:
    - Estimated project/consulting fees
    - Ongoing/maintenance or subscription costs
    - Clear sense of what success looks like and what he's paying for

### Risk-Tolerant but Outcome-Driven
- Signaled he is **"risk open"**:
  - "I'm risk open in a way whereby it's attempt."
- But wants concrete outcomes in a short timeframe:
  - Comfortable with a one-month attempt with clear deliverables and evaluation.

---

## Summary

The Agency was presented as a structured, tool-enforced SDLC for AI-augmented development with:
- Concrete multi-agent orchestration
- Design-system-driven UI generation
- Context management
- Feedback tooling
- Hybrid open source + paid model

Janson responded very positively, wants to trial it at StaffAny on greenfield projects, and asked for a proposal outlining scope, fees, success metrics, and follow-on subscription/maintenance options before looping in his CPOs.

---

## Action Items

- [ ] Jordan to prepare proposal with fee ranges
- [ ] Janson to discuss with CPO (Kai and Albert)
- [ ] Target: one-month consultation/implementation project

---

*Captured from meeting notes - 2026-01-15*
