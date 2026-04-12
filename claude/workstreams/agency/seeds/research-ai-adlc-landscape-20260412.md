---
type: research-report
workstream: agency
date: 2026-04-12
captured_by: the-agency/jordan/captain
research_agent: general-purpose (AI ADLC + Anthropic safety + coding-overrated)
status: complete
context: workshop content preparation
---

# Research Report: AI ADLC Landscape, Anthropic Safety Story, and "Coding Is Overrated"

## 1. AI-Augmented/Agentic SDLC — What Already Exists

**The claim that Valueflow is the FIRST is NOT safely defensible as stated.** Multiple frameworks using "ADLC" exist. But there IS a critical distinction that makes Valueflow unique.

### What exists

**AWS AI-DLC (AI-Driven Development Lifecycle)** — Announced re:Invent 2025, open-sourced. Replaces sprints with "bolts" (hours/days), epics with "Units of Work." AI generates artifacts with human oversight. The closest competitor in scope.
- Source: [AWS DevOps Blog](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/)
- Source: [GitHub repo](https://github.com/awslabs/aidlc-workflows)

**Arthur.ai ADLC (Agent Development Lifecycle)** — A lifecycle for building AI AGENT systems (not for using agents to build software). About developing AI products, not AI-augmented development.
- Source: [Arthur.ai blog](https://www.arthur.ai/blog/introducing-adlc)

**EPAM ADLC** — Similar to Arthur.ai: lifecycle for building agentic AI systems. FOR building AI agents, not WITH AI agents.
- Source: [EPAM Insights](https://www.epam.com/insights/ai/blogs/agentic-development-lifecycle-explained)

**Salesforce Agent Development Lifecycle** — Specific to Agentforce platform. Platform-specific, not general methodology.
- Source: [Salesforce Architects](https://architect.salesforce.com/docs/architect/fundamentals/guide/agent-development-lifecycle)

**Microsoft "AI-led SDLC"** — Blog post about integrating Azure/GitHub tooling. Integration guide, not a new methodology.
- Source: [Microsoft Tech Community](https://techcommunity.microsoft.com/blog/appsonazureblog/an-ai-led-sdlc-building-an-end-to-end-agentic-software-development-lifecycle-wit/4491896)

**Kim & Yegge "Vibe Coding"** — Practices and 8-stage adoption framework. NOT a lifecycle methodology — no defined phases, no artifact model, no quality gates. Dario Amodei wrote the foreword.
- Source: [Amazon](https://www.amazon.com/Vibe-Coding-Building-Production-Grade-Software/dp/1966280025)

### The defensible claim

**"Valueflow is the first methodology designed for humans and AI agents to collaboratively build arbitrary software"** — covering the full journey from idea to shipped value, with defined phases, artifact models, quality gates, multi-agent coordination patterns, and a human-agent responsibility model.

What distinguishes Valueflow:
- **AWS AI-DLC** treats AI as executor with human oversight. Valueflow treats human-agent as a collaborative partnership with structured roles (principal/agent), addressable agents, and bidirectional communication (ISCP).
- **Arthur.ai/EPAM/Salesforce** are about building AI agent products, not about using agents to build software. Different problem.
- **Vibe Coding** describes practices, not a lifecycle.
- **Nobody** has published a methodology with: structured agent roles, inter-agent communication protocols, multi-agent review/research/planning, quality gates at every boundary, AND a full idea-to-value lifecycle.

### Recommended workshop framing

"Several companies have begun adapting the SDLC for AI — AWS published AI-DLC, others have proposed agent development lifecycles. Valueflow is, to our knowledge, the first complete methodology designed for structured human-agent collaborative development, with defined roles, communication protocols, quality gates, and a full idea-to-value lifecycle."

## 2. Anthropic Safety/Alignment Story — Citable Facts

**Founding:**
- Dario Amodei was VP of Research at OpenAI. Daniela Amodei was VP of Safety & Policy.
- Dario left OpenAI December 2020. Fourteen researchers followed. Anthropic founded 2021.
- Dario's stated reason: "It is incredibly unproductive to try and argue with someone else's vision." Wanted safety integrated into training from the start.
- Sources: [Wikipedia](https://en.wikipedia.org/wiki/Dario_Amodei), [Inc.com](https://www.inc.com/ben-sherry/anthropic-ceo-dario-amodei-says-he-left-openai-over-a-difference-in-vision/91018229)

**Structure:**
- Anthropic is a Public Benefit Corporation (PBC). Board can legally prioritize mission over profit.
- "Long-Term Benefit Trust" holds Class T shares and can elect directors.
- Source: [Wikipedia](https://en.wikipedia.org/wiki/Anthropic)

**Safety Research:**
- Constitutional AI (CAI): published December 2022 (arxiv 2212.08073). Trains harmlessness via self-improvement using principles, replacing human labeling with AI feedback (RLAIF).
- Source: [Anthropic Research](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback)

**Safety Evaluations:**
- Anthropic and OpenAI conducted joint pilot alignment evaluation in 2025.
- Claude models generally score better on hallucination benchmarks, trading higher refusal rates for lower confabulation.
- Sources: [Anthropic](https://alignment.anthropic.com/2025/openai-findings/), [OpenAI](https://openai.com/index/openai-anthropic-safety-evaluation/)

**Workshop note:** Safety-first founding is well-documented and citable. Alignment advantage is real but nuanced — Claude is more conservative rather than dramatically more accurate on every task.

## 3. "Coding Skill Is Overrated" — Research Citations

**The landmark study:** Li, Ko, Begel. "What Distinguishes Great Software Engineers?" December 2019, *Empirical Software Engineering* (Springer). 1,926 expert engineers at Microsoft. Identified 54 attributes; top 5:

1. Writing good code
2. Adjusting behaviors to account for future value and costs
3. Practicing informed decision-making
4. Avoiding making others' jobs harder
5. Learning continuously

**Only #1 is a coding skill. #2-#5 are judgment, communication, and learning skills.**

- Source: [Springer](https://link.springer.com/article/10.1007/s10664-019-09773-y)
- Source: [PDF](https://faculty.washington.edu/ajko/papers/Li2019WhatDistinguishesEngineers.pdf)

**Workshop framing:** "Even before AI, 4 of the top 5 attributes of great software engineers were NOT coding skills. AI is automating the one that was. The other four — judgment, decision-making, collaboration, continuous learning — are what Valueflow is designed to amplify."

## Summary

| Claim | Status | Recommendation |
|-------|--------|----------------|
| "First AI ADLC" | Partially valid — AWS AI-DLC exists | Qualify: "first with structured human-agent collaboration" |
| Anthropic safety story | Fully citable | Use Wikipedia, Inc.com, arxiv |
| "Coding is overrated" | Peer-reviewed research | Cite Li et al. 2019 |
