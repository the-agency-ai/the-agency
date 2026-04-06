---
type: pvr
project: valueflow
workstream: agency
date: 2026-04-06
status: draft — pending MAR
author: the-agency/jordan/captain
seeds:
  - claude/workstreams/agency/seeds/seed-valueflow-20260406.md
  - claude/workstreams/agency/seeds/marfi-valueflow-20260406.md
  - claude/workstreams/iscp/seeds/seed-git-discipline-v2-20260405.md
  - claude/workstreams/agency/seeds/seed-next-version-pvr-20260406.md
transcripts:
  - usr/jordan/captain/transcripts/valueflow-design-session-20260406-0400.md
---

# Valueflow — Product Vision & Requirements

## Vision

**Valueflow** is TheAgency's AI-Augmented Development Lifecycle (AIADLC) — a methodology for multi-agent software development teams working under human direction. It defines the complete path from a gleam in someone's eye to value that customers are actively using.

Software development has mature methodologies — Waterfall, Agile, Lean, SAFe — but none designed for teams where AI agents are the primary builders. As multi-agent development becomes real, no defined methodology exists for how a thought becomes a requirement, a requirement becomes a design, a design becomes a plan, and a plan becomes shipped software. Valueflow fills this gap.

Rooted in Lean thinking: everything before delivery is waste. A seed is potential. Only delivery creates value.

## The Problem

Today in TheAgency, agents can implement code, but each transition between stages is ad hoc. Context is lost between sessions. Quality is inconsistent. Reviews happen or don't. There is no mechanical enforcement that the process was followed. The principal spends time on rubber-stamp approvals instead of judgment calls that actually need them.

TheAgency has the infrastructure — ISCP for messaging, dispatches for coordination, worktrees for isolation, hooks for automation — but not the methodology that ties it together. We have pipes but no flow.

MARFI research confirms: no existing AI agent framework (CrewAI, AutoGen, MetaGPT, LangGraph) has formalized a development lifecycle. TheAgency is ahead of the field in four areas — parallel multi-agent review, three-bucket disposition, autonomy ladders, and stage-hash gating — but only if we ship it.

## The Flow

```
Gleam → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
                                       ↑              ↑           ↑        ↑
                                  MAR at every transition (three-bucket disposition)
```

**Seed.** Something comes up — a conversation, a Granola transcript, an observation, a flag. Capture it. Route it to an existing workstream and agent, or decide with the agent that a new workstream is needed.

**Research (MARFI).** Before defining, gather input. Multi-Agent Request for Information — research agents explore competitors, prior art, implementation approaches. Principal reviews the research questions before agents spin up.

**Define (PVR).** Seed + research → discussion with principal → Product Vision & Requirements. The "what" and "why." MAR reviews it — viability, completeness, competitive mapping. Three-bucket disposition: disagree, autonomous, collaborative.

**Design (A&D).** Multi-agent input group contributes technical approach before the driving agent writes. Review dimensions: ease of implementation, maintainability, evolution, performance, security, testability. MAR reviews with design-focused profiles.

**Plan.** Multi-agent group produces a plan seed. Combined with PVR + A&D, enter plan mode. Master plan → MAR → phase plans. Phase planning is autonomous — no principal engagement unless flagged. Agents may request input from agents in other workstreams via captain: "anyone I should speak with?"

**Implement.** Agents execute phases and iterations within phases autonomously, surfacing for principal input as needed. Quality gate and QGR at every iteration boundary. Commits dispatch to captain automatically.

**Ship.** Captain merges commits, syncs worktrees (batching — all commits processed before syncing), builds PRs at phase boundaries, runs pre-PR quality gate, pushes to origin.

**Value.** Customer is using it. Everything before this was waste.

## The Three-Bucket Pattern

The signature of valueflow. Recurs at every transition:

| Bucket | What | Who decides |
|--------|------|-------------|
| 1. Disagree / Resolved | Agent disagrees with feedback or item is already done | Agent decides, principal reviews |
| 2. Autonomous | Agent incorporates or handles independently | Agent acts, principal informed |
| 3. Collaborative | Requires principal input or joint work | 1B1 discussion |

This pattern appears in: MAR disposition, flag triage, dispatch handling, plan review. It is unique to TheAgency — no other framework formalizes it.

## The Enforcement Ladder

Every capability in valueflow follows a progressive tightening path:

1. **Document** — CLAUDE-THEAGENCY.md + README-THEAGENCY.md. "This is the standard." Dispatch to all agents.
2. **Skills** — working from the docs, no hard enforcement. Skills reference the docs via `@` imports.
3. **Hookify warn** — kittens warnings where tooling doesn't yet exist.
4. **Tools + refined skills** — build and improve. Tighten the mechanics.
5. **Hookify block** — hard enforcement. Can't bypass.

Each layer addresses the bypass discovered in the previous layer. The tool doesn't change — its position in the pipeline changes. Gate on artifact existence (mechanical, auditable), not on artifact quality (human judgment).

Strip kittens warnings when sufficient tooling and enforcement exist. Iterate.

## Multi-Agent Groups

Three types of multi-agent coordination:

| Group | Purpose | When |
|-------|---------|------|
| **MARFI** (Multi-Agent RFI) | Research and input gathering | Before PVR, before A&D, before Plan |
| **MAR** (Multi-Agent Review) | Three-bucket review of artifacts | After PVR, A&D, Plan, at every QG boundary |
| **MAP** (Multi-Agent Plan) | Planning input | Before master plan, before phase plans |

Different MAR profiles per artifact type — a PVR review is not a code review is not an A&D review. Each has different dimensions, different reviewer agents.

## Users

**Principals** — humans directing agent teams. Optimize their time for decisions that require human judgment. Not bothered for rubber-stamp approvals. Can check in remotely from phone or iPad — low bandwidth, high judgment.

**Agents** — AI instances executing within the flow. Know what stage they're in, what gates they must pass, when to escalate. Captain coordinates, tech-leads deliver, specialists review and research.

**Framework adopters** — people installing TheAgency on their own repos. Progressive adoption via the enforcement ladder — start with documentation, tighten over time.

**Customers** — the measure of value. If the valueflow doesn't deliver something a customer is actively using, everything was waste.

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| FR1 | **Seed capture and routing** — `/seed` skill gathers materials, synthesizes, routes to workstream/agent or spins up new workstream |
| FR2 | **MARFI** — captain drafts research questions, principal reviews, agents execute in parallel, results synthesized into brief |
| FR3 | **MAR** — three-bucket disposition, principal approves, different profiles per artifact type, gate on artifact existence (stage-hash) |
| FR4 | **`/define` and `/design`** — drive PVR and A&D via 1B1 with completeness checklists, progressive update |
| FR5 | **Plan mode integration** — master plan from PVR + A&D + plan seed, phase plans autonomous, MAR at plan level |
| FR6 | **Quality gates at every boundary** — QG/QGR per iteration and phase, block commits without QGR, stage-hash signing |
| FR7 | **Dispatch-on-commit** — agent commits, captain notified automatically, captain merges, syncs, builds PRs |
| FR8 | **Captain loop** — cadence-based: fetch, dispatch, commits, PRs, escalations, batch processing |
| FR9 | **CLAUDE-THEAGENCY.md decomposition** — composable chunks, skills `@` import relevant pieces, one source of truth |
| FR10 | **Enforcement ladder** — document → skill → hookify warn → tools → hookify block, progressive and additive |
| FR11 | **Cross-workstream RFI** — agents request input from other workstreams via captain routing |

### Non-Functional

| ID | Requirement |
|----|-------------|
| NFR1 | **Platform support** — Claude Code CLI (primary), Claude Desktop code tab, remote connections (mobile, iPad, laptop), MDPal tray for notification |
| NFR2 | **Progressive adoption** — enforcement ladder is the adoption path, not all-or-nothing |
| NFR3 | **Autonomous by default** — human checkpoints at scope-definition boundaries only, not during execution |
| NFR4 | **Context resilience** — survives session boundaries, compaction, restarts via handoffs, PostCompact hooks, ISCP |
| NFR5 | **Context economics** — minimize context window consumption, composable `@` imports, inject only what's needed |
| NFR6 | **Token economics** — `effort:` levels on skills, model selection per task, budget as design constraint |
| NFR7 | **Auditability** — every gate produces an artifact, stage-hash proves gate ran, audit trail in git |
| NFR8 | **Speed to value** — optimize for delivery not ceremony, every step justifies its existence |

### Constraints

| ID | Constraint |
|----|-----------|
| C1 | **Claude Code platform** — build on its capabilities and limitations, we don't control the platform |
| C2 | **Local-first, ClaudeCorp-ready** — V2 single machine, architecture supports ClaudeCorp (Mycroft): multiple Claude Code instances, headless agents, ISCP coordination |
| C3 | **Git as source of truth** — all artifacts in git, SQLite for notifications not durable state |
| C4 | **Rapid iteration** — progress over perfection, V2 → V3 → GTM, no blocking on perfect |
| C5 | **Backward compatibility** — existing agents and workstreams don't break, enforcement ladder tightens not rewrites |

## Success Criteria

### V2 (Building Now)

| ID | Criterion |
|----|-----------|
| SC1 | Agent executes phases and iterations autonomously, surfacing for input only when needed |
| SC2 | Principal prompted only when human judgment adds value — zero rubber-stamp approvals |
| SC3 | Every artifact has a gate — no PVR, A&D, plan, or code ships without MAR or QG (stage-hash enforced) |
| SC4 | Context survives compaction — agent picks up where it left off, no disorientation |
| SC5 | New framework adopter adopts valueflow progressively — working within a week |
| SC6 | Captain loop runs on cadence within a session — dispatches and commits processed without prompting |
| SC7 | Low-cost remote check-ins — principal reviews from phone/iPad, approves/rejects, gives direction, disconnects |

### V3 (After V2 Proven)

| ID | Criterion |
|----|-----------|
| SC8 | ClaudeCorp runs overnight — agents execute autonomously, captain processes commits and PRs, principal reviews in the morning |

## Non-Goals

| ID | Non-Goal |
|----|----------|
| NG1 | **Not replacing human creativity** — valueflow structures the flow, does not generate ideas |
| NG2 | **Not a CI/CD system** — manages development lifecycle, not deployment/monitoring/production |
| NG3 | **Not cross-machine in V2** — single machine, local-first; cross-machine is V3 |
| NG4 | **Not prescriptive about technology** — methodology not stack, works with any language/framework |
| NG5 | **Not all-or-nothing** — partial adoption is a feature via the enforcement ladder |

## Open Questions

**OQ1: Valueflow health metrics** — How do we measure whether the valueflow is working? Candidates analogous to DORA: lead time from seed to shipped, gate pass rate, compaction survival rate, principal intervention frequency, autonomous execution ratio. What do we measure, and what targets define "healthy"?

## Version Roadmap

- **V2** — Foundation. Documentation, skills, enforcement ladder. Working methodology on a single machine.
- **V3** — Automation. Headless captain loop (`--bare -p`), named subagents for MAR, fork-session for parallel review, stream-json orchestration, ClaudeCorp support.
- **GTM** — Public release. Plugin packaging, security hardening (`disableSkillShellExecution`), framework adopter onboarding.
