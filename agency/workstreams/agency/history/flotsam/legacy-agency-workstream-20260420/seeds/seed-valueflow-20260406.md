---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "Valueflow — the path from gleam to customer value"
transcripts:
  - usr/jordan/captain/transcripts/valueflow-seed-to-delivery-20260406-0322.md
  - usr/jordan/captain/transcripts/flag-triage-workflow-20260406-0322.md
---

# Valueflow

## The Name

**Valueflow** — the path from a gleam in someone's eye to value that customers are actively using. Rooted in Lean thinking: until something is delivered and being used, it is waste. A seed is potential. Only delivery creates value.

A **seed** is as little as a gleam — a thought, a conversation, an idea captured. It's called a seed because from it, everything grows.

## The Flow

```
Gleam → Seed → Research → Define (PBR) → Design (A&D) → Plan → Implement → Ship → Value
         ↑                    ↑              ↑            ↑        ↑
         MAR at every transition (three-bucket disposition)
```

### 1. Seed

Something comes up. Could be a conversation (like a Granola transcript), a document, an observation, a flag. Capture it — that's the seed.

**Needs:** A tool/skill that generates seeds and routes them. Seeds get assigned to either:
- An existing agent on an existing workstream, OR
- A new workstream with a newly created agent (most common flow)

### 2. Multi-Agent Research

Before the PBR, spin up a research group. Competitors, implementation approaches, prior art. This gives the driving agent rich input before they start defining.

### 3. Define (PBR)

Seed + research input → discussion with principal → **Product Problem Vision Requirements** document. The PBR is the "what" and "why."

PBR goes through MAR (Multi-Agent Review) — but not a code review. Viability, competitive mapping, completeness. Different review profiles than code.

### 4. Design (A&D)

Before writing, spin up an **input group** — multi-agent contribution on technical approach. Like an RFI. Then the driving agent writes the A&D.

**Review dimensions:** ease of implementation, maintainability, evolution capability, performance, security, testability. These are the non-functional requirements.

A&D goes through MAR with design-focused reviewers.

### 5. Plan

Multi-agent group provides **plan seed** (input on phasing, approach). Combined with PBR + A&D, enter plan mode. Produces the master plan.

Master plan → MAR → revise. Then break into phases. Each phase gets its own plan via plan mode.

**Phase planning is autonomous** — no principal engagement unless something is flagged. Agents execute against the master plan and phase plans autonomously.

### 6. Implement

Execute iterations. At each iteration boundary: QG → QGR. Commit. Dispatch to captain.

At each phase boundary: phase-level QG → QGR → unlocks next phase.

**Quality gates block commits.** No QGR = no commit. Enforced mechanically.

### 7. Ship

End of phase → captain builds PR → pre-PR quality gate → push to origin → merge.

Captain batches: if multiple commits come in, process all before syncing to worktrees. Don't interrupt agents mid-work with partial syncs.

### 8. Value

Customer is using it. Everything before this was waste.

## The Three-Bucket Pattern

Recurs at every transition in the valueflow:

| Bucket | What | Who decides |
|--------|------|-------------|
| 1. Disagree / Resolved | Agent disagrees with feedback or item is already done | Agent decides, principal reviews |
| 2. Autonomous | Agent incorporates or handles independently | Agent acts, principal informed |
| 3. Collaborative | Requires principal input or joint work | 1B1 discussion |

This pattern appears in: MAR disposition, flag triage, dispatch handling, plan review.

## Captain's Loop

Captain runs on a cadence:
1. Fetch from origin master
2. Scan dispatches
3. Process commits (batch — all commits before syncing worktrees)
4. Build PRs at phase boundaries
5. Handle flags and escalations

## Platform Targets

1. Claude Code CLI (primary — terminal session)
2. Claude Desktop code tab
3. Remote connections (mobile, iPad, laptop connecting to home farm)
4. MDPal tray for human notification outside the stream

## Open Questions

- Artifact storage and naming conventions — how do we store all the PBRs, A&Ds, plans, QGRs?
- "Signing process" for quality gates — what does the signing mechanism look like?
- Multi-agent group profiles — what agents make up research groups, review groups, input groups?
- How does the three-bucket MAR integrate into the enforcement triangle?
