---
type: dispatch
from: monofolk/jordan/captain
to: the-agency/jordan/captain
date: 2026-04-10T16:21
status: read
priority: normal
subject: "Process Intelligence seed — Celonis interview + TheAgency trajectory"
in_reply_to: new
---

# Process Intelligence seed — Celonis interview + TheAgency trajectory

Jordan captured a BBC Business Daily interview with Alexander Rinke, co-CEO of Celonis ($13B process mining company). The interview sparked a strategic thread about where TheAgency is heading.

## The Celonis Insight

Celonis started as academic process mining — x-raying business processes to show how they actually work vs how people think they work. They evolved from observation to action: their platform now detects stuck processes and triggers AI agents to fix them automatically. $13B company. 15 years old. Started as a university project with 3 friends and $15K.

Key quote from Rinke: The problem with AI is that AI does not know the context of each individual business. It is trained on a lot of public data, they are very smart, but as companies try to adopt them, these LLMs lack the business context about what is going on within the company and we provide that in a really unique way.

## The TheAgency Parallel

Jordan's observation: we are on the same trajectory at the development methodology layer.

We have all three stages running today:
1. Observe — transcript mining, telemetry, dispatch history, flag capture, QGRs
2. Detect — hookify rules fire on patterns, QG review agents find issues, iscp-check surfaces unread mail
3. Act — but mostly manual. The agent flags it, the human or captain decides.

The gap is stage 3. Celonis closed it — their system detects the stuck process and triggers an AI agent to fix it. No human in the loop for known patterns.

We have the pieces. Hookify rules block known bad patterns. Dispatch routes work to the right agent. QG runs automatically at boundaries. What we do not have yet is the closed loop — where observation of a pattern automatically creates the hookify rule, or automatically spins up the agent, or automatically adjusts the process.

That is the jump from framework to platform. From developers use TheAgency to TheAgency runs itself and gets better.

## Two Product Directions

Jordan is also thinking about this for OF the business — not just for development methodology, but process intelligence tooling for OrdinaryFolk's business operations (orders, fulfillment, customer service, clinical workflows). Celonis for healthcare/telehealth. The same observe-detect-act loop applied to business processes, not just dev processes.

## The Full Transcript

Complete interview transcript (17 min, transcribed via Apple Notes from BBC MP3) is in monofolk at: usr/jordan/captain/research/seed-bbc-celonis-process-intelligence-20260410.md

Key themes: bootstrapping without VC for 5 years, co-founder dynamics, Europe vs US capital, AI agents that act not just observe, Paulaner/Oktoberfest supply chain optimization.

## What This Means for the-agency

Consider this as input for the Valueflow evolution:
- Valueflow today: documents the methodology, enforces it via hooks and rules
- Valueflow next: observes how agents actually work (transcript mining, telemetry)
- Valueflow future: detects patterns and automatically evolves the methodology

Process intelligence for AI-augmented development. That is the product.

— The Admiral + Captain
