---
type: pvr
project: valueflow
workstream: agency
date: 2026-04-06
status: MAR round 1 complete — revised, pending round 2
author: the-agency/jordan/captain
mar-round-1: claude/workstreams/agency/reviews/mar-valueflow-pvr-round1-20260406.md
seeds:
  - claude/workstreams/agency/seeds/seed-valueflow-20260406.md
  - claude/workstreams/agency/seeds/marfi-valueflow-20260406.md
  - claude/workstreams/iscp/seeds/seed-git-discipline-v2-20260405.md
  - claude/workstreams/agency/seeds/seed-next-version-pvr-20260406.md
transcripts:
  - usr/jordan/captain/transcripts/valueflow-design-session-20260406-0400.md
reviewers:
  research: methodology-critic, practitioner, adopter-advocate, lean-process-analyst
  agents: mdpal-app, iscp, mdpal-cli, monofolk/captain, devex (pending)
---

# Valueflow — Product Vision & Requirements

## Vision

**Valueflow** is TheAgency's AI-Augmented Development Lifecycle (AIADLC) — a methodology for multi-agent software development teams working under human direction. It defines the complete path from a gleam in someone's eye to value that customers are actively using.

Software development has mature methodologies — Waterfall, Agile, Lean, SAFe — but none designed for teams where AI agents are the primary builders. As multi-agent development becomes real, no defined methodology exists for how a thought becomes a requirement, a requirement becomes a design, a design becomes a plan, and a plan becomes shipped software. Valueflow fills this gap.

Rooted in Lean thinking: optimize every stage for its contribution to delivery. Every step must demonstrably reduce rework or increase delivery probability. Steps that do not are waste. A seed is potential. Only delivery creates value.

## The Problem

Today in TheAgency, agents can implement code, but each transition between stages is ad hoc. Context is lost between sessions. Quality is inconsistent. Reviews happen or don't. There is no mechanical enforcement that the process was followed. The principal spends time on rubber-stamp approvals instead of judgment calls that actually need them.

TheAgency has the infrastructure — ISCP for messaging, dispatches for coordination, worktrees for isolation, hooks for automation — but not the methodology that ties it together. We have pipes but no flow.

MARFI research confirms: no existing AI agent framework (CrewAI, AutoGen, MetaGPT, LangGraph) has formalized a development lifecycle. TheAgency is ahead of the field in four areas — parallel multi-agent review, three-bucket disposition, autonomy ladders, and stage-hash gating — but only if we ship it.

## The Three-Bucket Pattern

The signature of valueflow. Recurs at every transition. When an agent receives feedback on an artifact, it triages into three buckets:

| Bucket | What | Who decides |
|--------|------|-------------|
| 1. Disagree | Agent disagrees with the feedback — presents reasoning to principal | Agent decides, principal reviews |
| 2. Autonomous | Agent agrees and incorporates independently — reports to principal | Agent acts, principal informed |
| 3. Collaborative | Requires principal input or joint work | 1B1 discussion |

**Important:** Reviewers give raw feedback (findings, concerns, questions). The **author** triages into buckets, not the reviewer. Reviewers review; authors triage.

This pattern appears in: MAR disposition, flag triage, dispatch handling, plan review. It is unique to TheAgency — no other AI agent framework formalizes structured disposition of review feedback.

## The Flow

```
Gleam → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
                                       ↑              ↑           ↑        ↑           ↑
                                  MAR at every transition (three-bucket disposition)
```

**Seed.** A gleam — a thought, conversation, Granola transcript, observation, flag. Capture it. Route it to an existing workstream and agent, or decide with the agent that a new workstream is needed and spin one up.

**Research (MARFI — Multi-Agent Request for Information).** Before defining, gather input. Research agents explore competitors, prior art, implementation approaches in parallel. Principal reviews the research questions before agents spin up. MARFI is for cross-cutting research; domain-specific exploration is the agent's normal work and doesn't need captain mediation.

**Define (PVR).** Seed + research → discussion with principal → Product Vision & Requirements. The "what" and "why." MAR reviews it — viability, completeness, competitive mapping.

**Design (A&D).** Multi-agent input group contributes technical approach before the driving agent writes. Review dimensions: ease of implementation, maintainability, evolution, performance, security, testability. MAR reviews with design-focused profiles.

**Plan.** Multi-agent group may provide a plan seed for cross-cutting complex projects (MAP — Multi-Agent Plan input). For single-workstream plans, the driving agent drafts directly. Combined with PVR + A&D, enter plan mode. Master plan → MAR → phase plans. Phase planning is autonomous — no principal engagement unless flagged.

Agents should always prompt captain: "anyone I should speak with?" — cross-workstream input via captain routing ensures nothing is designed in isolation.

**Implement.** Agents execute phases and iterations within phases autonomously, surfacing for principal input as needed. Quality gate and QGR at every iteration boundary. Commits dispatch to captain automatically (queued in ISCP DB — captain processes when running).

**Ship.** Captain merges commits, syncs worktrees (batching — all commits processed before syncing), builds PRs at phase boundaries, runs pre-PR quality gate, pushes to origin.

**Value.** Customer is using it. Customer feedback, observations, and needs generate new seeds — closing the cycle. The Value → Seed feedback loop is formalized in V3.

## The Enforcement Ladder

Every capability in valueflow follows a progressive tightening path:

1. **Document** — CLAUDE-THEAGENCY.md + README-THEAGENCY.md. "This is the standard." Human-readable, no tooling required. An adopter at step 1 reads the docs and follows conventions manually.
2. **Skills** — working from the docs, no hard enforcement. Skills reference the docs via `@` imports.
3. **Hookify warn** — kittens warnings where tooling doesn't yet exist. Agents are nudged toward the right path.
4. **Tools + refined skills** — build and improve. Tighten the mechanics.
5. **Hookify block** — hard enforcement. Can't bypass.

Each layer addresses the bypass discovered in the previous layer. The tool doesn't change — its position in the pipeline changes. Gate on artifact existence (mechanical, auditable), not on artifact quality (human judgment).

Enforcement level is per-workstream, not global. Active workstreams at higher enforcement than dormant ones.

## Multi-Agent Groups

Three types of multi-agent coordination:

| Group | Purpose | When | Trigger |
|-------|---------|------|---------|
| **MARFI** (Multi-Agent Request for Information) | Research and input gathering | Before PVR, before A&D | Always for new work. Captain drafts questions, principal reviews before agents spin up. |
| **MAR** (Multi-Agent Review) | Review of artifacts with three-bucket disposition | After PVR, A&D, Plan, at every QG boundary | Always. Reviewers give raw findings; author triages. |
| **MAP** (Multi-Agent Plan input) | Planning input from multiple agents/workstreams | Before master plan for cross-cutting complex projects | When plan spans multiple workstreams or has high risk/complexity. Single-workstream plans: agent drafts, MAR reviews. |

Different MAR profiles per artifact type — a PVR review evaluates viability and completeness, a code review evaluates correctness and security, an A&D review evaluates design dimensions. Each has different reviewer agents and evaluation criteria.

## Captain

Captain is the coordination backbone. Two modes, same agent:

**Always-on loop** — continuous processing: fetch from origin, scan dispatches, process commits (batched — all commits before syncing worktrees), build PRs at phase boundaries, handle flags and escalations. Captain not running is a holiday — we aren't working.

**Interactive session** — principal sits down with captain to work together. Seed discussions, PVR reviews, MAR triage, strategic decisions. This is where principal judgment happens.

Dispatch-on-commit queues in ISCP DB. Captain processes when running — no assumption of synchronous availability, but captain is normally always running.

## Users

**Principals** — humans directing agent teams. Optimize their time for decisions that require human judgment. Not bothered for rubber-stamp approvals. Can check in remotely — low bandwidth, high judgment.

**Agents** — AI instances executing within the flow. Know what stage they're in, what gates they must pass, when to escalate. Captain coordinates, tech-leads deliver, specialists review and research.

**Framework adopters** — people installing TheAgency on their own repos. Progressive adoption via the enforcement ladder — start with documentation, tighten over time. Valueflow coexists with non-Agency contributors — Agency gates apply to Agency agents, standard code review for external contributors.

**Customers** — the measure of value. If the valueflow doesn't deliver something a customer is actively using, everything was waste.

## Requirements

### Functional

| ID | Requirement |
|----|-------------|
| FR1 | **Seed capture and routing** — `/seed` skill gathers materials, synthesizes, routes to workstream/agent or spins up new workstream |
| FR2 | **MARFI** — captain drafts research questions, principal reviews, agents execute in parallel, results synthesized into brief. Cross-cutting research only — domain-specific exploration doesn't need captain mediation. |
| FR3 | **MAR** — reviewers give raw findings; author triages into three buckets (disagree/autonomous/collaborative); principal approves dispositions. Different profiles per artifact type. Gate on artifact existence (stage-hash). MAR dispatch specifies type, format, and response mechanism. |
| FR4 | **`/define` and `/design`** — drive PVR and A&D via 1B1 with completeness checklists, progressive update |
| FR5 | **Plan mode integration** — master plan from PVR + A&D + plan seed. MAP for cross-cutting complex projects; single-workstream plans drafted by driving agent. Phase plans autonomous. MAR at plan level. |
| FR6 | **Quality gates at every boundary** — QG/QGR per iteration and phase. Block commits without QGR. Stage-hash signing. Gate scope matches change scope — pre-commit runs tests relevant to changed files, not the full suite. |
| FR7 | **Dispatch-on-commit** — agent commits, dispatch queued to captain in ISCP DB. Captain processes when running. Captain merges, syncs, builds PRs. |
| FR8 | **Captain loop** — always-on: fetch, dispatch, commits, PRs, escalations. Batch processing (all commits before syncing). Interactive mode for principal sessions. |
| FR9 | **CLAUDE-THEAGENCY.md decomposition** — composable chunks by concern (git discipline, quality gate, dispatch protocol, etc.). Skills `@` import relevant pieces. One source of truth, multiple composition points. Decomposition taxonomy determined in A&D. |
| FR10 | **Enforcement ladder** — document → skill → hookify warn → tools → hookify block. Progressive and additive. Per-workstream enforcement level. |
| FR11 | **Cross-workstream RFI** — agents request input from other workstreams via captain dispatch routing. Cross-repo RFI via collaboration repos. Cross-repo agent access deferred to V3. |
| FR12 | **Valueflow health metrics** — measure lead time (seed to shipped) and principal intervention frequency in V2. Per-stage cycle time and autonomous execution ratio as stretch. Data sourced from ISCP timestamps and git history. |
| FR13 | **Continual learning and improvement** — automated mechanisms to identify friction points, context costs, and token costs. Three input channels: (1) **transcript mining** — patterns, friction, decisions from session transcripts; (2) **flag mechanism** — real-time categorized quick-capture (`flag --friction`, `flag --idea`, `flag --bug`) from agents and principals as they work; (3) **telemetry** — `_log-helper` data, ISCP timestamps, dispatch patterns. Flag categories feed the learning pipeline: friction flags → improvement candidates, idea flags → seed candidates, bug flags → fix candidates. Surface improvement opportunities as seeds. Build or improve tooling in response. The methodology observes its own performance and tightens — the enforcement ladder, context economics, and token economics are continuously optimized, not set once. |

### Non-Functional

| ID | Requirement |
|----|-------------|
| NFR1 | **Platform support** — Claude Code CLI (primary), Claude Desktop code tab, remote connections (mobile, iPad, laptop). MDPal tray for principal notification outside the terminal stream — MDPal is an Agency application, not a third-party dependency. |
| NFR2 | **Progressive adoption** — enforcement ladder is the adoption path, not all-or-nothing. Coexists with non-Agency contributors. |
| NFR3 | **Autonomous by default** — human checkpoints at scope-definition boundaries only, not during execution. Explicit escalation hook point for agents to break out of autonomous loop when needed — mechanism defined in A&D. |
| NFR4 | **Context resilience** — survives session boundaries, compaction, restarts via multi-part handoffs (identity, state, active context, next action, working set), PostCompact hooks, ISCP notifications. Stage-aware resume: agent verifies open dispatches, current stage, artifact state before resuming. |
| NFR5 | **Context economics** — minimize context window consumption. CLAUDE-THEAGENCY.md decomposition into composable chunks — skills inject only what's needed, not everything. `@` imports are the mechanism. Measure and optimize context cost per operation. |
| NFR6 | **Token economics** — minimize API token cost. `effort:` levels on skills (high for QG/MAR, low for reads). Model selection per task (sonnet for MARFI research, opus for PVR/A&D). Budget as design constraint. |
| NFR7 | **Auditability** — every gate produces an artifact. Stage-hash proves gate ran on specific version. Audit trail in git. Gate on artifact existence, not quality — mechanical enforcement for compliance, human judgment for quality. |
| NFR8 | **Speed to value** — optimize for delivery not ceremony. The full valueflow (seed to implementation) completes in under 2 hours for standard projects. Every step justifies its existence. |

### Constraints

| ID | Constraint |
|----|-----------|
| C1 | **Claude Code platform** — build on its capabilities and limitations, we don't control the platform |
| C2 | **Local-first, ClaudeCorp-ready** — V2 single machine. Architecture supports ClaudeCorp (Mycroft): multiple Claude Code instances, headless agents (`--bare -p`), ISCP coordination. No assumptions about single terminal session. |
| C3 | **Git as source of truth** — all artifacts in git. SQLite for notifications not durable state. |
| C4 | **Rapid iteration** — progress over perfection. V2 → V3 → GTM. No blocking on perfect. |
| C5 | **Backward compatibility** — existing agents and workstreams don't break. Enforcement ladder tightens, not rewrites. |

## Success Criteria

### V2 (Building Now)

| ID | Criterion |
|----|-----------|
| SC1 | Agent executes phases and iterations autonomously, surfacing for input only when needed |
| SC2 | Principal prompted only when human judgment adds value — zero rubber-stamp approvals |
| SC3 | Every artifact has a gate — no PVR, A&D, plan, or code ships without MAR or QG (stage-hash enforced) |
| SC4 | Context survives compaction — agent picks up where it left off, no disorientation |
| SC5 | Captain loop runs continuously — dispatches and commits processed, syncs batched |
| SC6 | Low-cost remote check-ins — principal reviews, approves/rejects, gives direction, disconnects |
| SC7 | Lead time from seed to implementation start measurable — data from ISCP timestamps and git |
| SC8 | Principal intervention frequency measurable — track how often principal is pulled in during autonomous execution |

### V3 (After V2 Proven)

| ID | Criterion |
|----|-----------|
| SC9 | ClaudeCorp runs overnight — agents execute autonomously, captain processes commits and PRs, principal reviews in the morning |
| SC10 | Value → Seed feedback loop — customer feedback generates new seeds automatically |
| SC11 | Cross-repo agent access for MARFI — agents research across repo boundaries |

## Non-Goals

| ID | Non-Goal |
|----|----------|
| NG1 | **Not replacing human creativity** — valueflow structures the flow, does not generate ideas |
| NG2 | **Not a CI/CD system** — manages development lifecycle, not deployment/monitoring/production |
| NG3 | **Not cross-machine in V2** — single machine, local-first; cross-machine is V3 |
| NG4 | **Not prescriptive about technology** — methodology not stack, works with any language/framework |
| NG5 | **Not all-or-nothing** — partial adoption is a feature via the enforcement ladder |
| NG6 | **Not replacing existing team tools** — valueflow is the AI agent coordination layer, not a replacement for Jira, Linear, Slack, or human team collaboration tools |

## Open Questions

**OQ1: Minimum Viable Adoption** — What does "working" look like for a new adopter at each enforcement ladder step? What's the day-zero experience? Day-seven?

**OQ2: MAR agent profiles** — What model/effort level runs MAR agents? How are parallel reviewers coordinated and results merged?

**OQ3: MARFI coordination** — How are parallel research agents coordinated and their results synthesized into a brief?

**OQ4: PVR completeness gate** — What constitutes a "complete" PVR for gate purposes? Checklist, human sign-off, stage-hash, or some combination?

## Version Roadmap

- **V2** — Foundation. Documentation, skills, enforcement ladder. Working methodology on a single machine. Captain always-on. Health metrics measurable.
- **V3** — Automation. Headless captain loop (`--bare -p`), named subagents for MAR (`SendMessage`), fork-session for parallel review, stream-json orchestration, ClaudeCorp support, Value → Seed feedback loop, cross-repo agent access.
- **GTM** — Public release. Plugin packaging, security hardening (`disableSkillShellExecution`), framework adopter onboarding, minimum viable adoption guide.

## MAR Round 1 Summary

21 findings from 4 research reviewers + 5 agent reviews (mdpal-app, ISCP, mdpal-cli, monofolk/captain, DevEx pending). Full disposition at `claude/workstreams/agency/reviews/mar-valueflow-pvr-round1-20260406.md`.

Key revisions from MAR:
- Lean framing refined: "optimize every stage for its contribution to delivery"
- Three-bucket pattern: clarified that reviewers give raw feedback, authors triage
- MARFI scope: cross-cutting research only, domain-specific is agent's normal work
- MAP trigger: complex cross-cutting projects only, single-workstream plans drafted by agent
- MDPal tray restored in NFR1 — MDPal is an Agency application, not a third-party tool. Principal overruled agent feedback.
- Captain: always-on + interactive, not running = holiday
- Dispatch-on-commit: queues in ISCP DB, captain processes when running
- Non-Agency contributors: valueflow gates don't block external PRs
- Dormant workstreams: enforcement level is per-workstream
- Health metrics promoted to V2 requirement (FR12, SC7, SC8)
- Value → Seed feedback loop added as V3
- Pre-commit gate scope matches change scope (FR6)
- NFR3: explicit escalation hook point, mechanism deferred to A&D
- NFR4: multi-part handoffs, stage-aware resume
- NFR8: under 2 hours for standard projects
