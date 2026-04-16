# PVR MAR — The Agency 2.0

**Date:** 2026-04-05
**Target:** `usr/jordan/captain/captain-pvr-20260405.md`
**Agents:** 5 (Completeness, Consistency, Stakeholder, Feasibility, Gap Analysis)
**Model:** Sonnet

---

## Executive Summary

The PVR is a strong, faithful capture of 44 1B1 decisions. Coverage is effectively complete (43/44 items represented). The *what* is right. The gaps are in *how it operates over time*, *who can adopt it beyond Jordan*, and *what happens when things go wrong*.

**Top 5 findings across all agents:**

1. **Docker contradiction** — R6 mandates Docker for test execution (P0) but Non-Requirements excludes Docker as "infra-agnostic provider concern." Live contradiction.
2. **Principal bias** — Almost every requirement is validated against Jordan's machine. No success criterion covers a non-`jdm` principal. Multi-principal scenario completely unaddressed.
3. **No error recovery story** — PVR describes a framework that works when things go right. No rollback for partial init, no `agency-doctor`, no agency-update conflict resolution.
4. **Unsourced open questions re-open settled decisions** — OQ3 (Docker hard requirement?) and OQ5 (X API $200/mo?) re-open decisions the 1B1 already resolved.
5. **R13 (transcript dual-write) may be unimplementable** — Claude Code controls JSONL storage location. No hook intercepts writes. Needs design pass.

---

## Agent 1: Completeness Review

**Coverage: 43/44 items captured. Confidence: HIGH.**

### Issues

| Issue | Severity | Detail |
|-------|----------|--------|
| OQ5 re-opens X API tier | HIGH | 1B1 resolved on pay-per-use (<$10/mo). OQ5 introduces $200/$100 tiers — contradicts source. |
| OQ3 re-opens Docker decision | HIGH | 1B1 Item 7 decided Docker for all tests. OQ3 asks "Is Docker a hard requirement?" |
| R7 has unsourced specifics | MEDIUM | "Validate principal, usr/, tools, agency.yaml" — agent-added, not from 1B1. |
| Future test reporting service dropped | MEDIUM | Item 7 mentioned "Future: test result reporting service" — PVR drops it entirely. |
| I3 dispatch types sourced from session 19 | LOW | Not from the two 1B1s under review — needs attribution. |
| Priority tiers agent-assigned | LOW | P2/P3 assignments are agent judgment, not principal-directed. |
| R22 (PM agent) lost conditionality | LOW | Source: "update if needed." PVR: "diff and merge improvements." |

---

## Agent 2: Consistency Review

**Confidence: MEDIUM.**

### Contradictions

| Issue | Severity | Detail |
|-------|----------|--------|
| R6 vs Non-Requirements (Docker) | HIGH | R6 bakes Docker into framework as P0. Exclusion says Docker is a provider concern. |
| R5 auto-merge unqualified | MEDIUM | Auto-merge fails on protected branches. No fallback specified. |
| R16 ordering paradox | MEDIUM | Ships before P0 → blocks implementation. Ships after → P0 deliverables lack headers. |

### Dependency Graph Gaps (6-7 missing edges)

- R5 → R6 (PR skill runs QG which runs tests)
- R7 → R1 (SessionStart validates structures init creates)
- R9 → R4 (permissions mining uses the mining tool)
- R10 → I3 (dispatch auto-read → ISCP lifecycle)
- R12 → R8 (typed frontmatter must be compatible with multi-agent handoffs)
- R22 → R17 (PM agent update should incorporate MAR)

### Underspecified Requirements

- **R4** — "non-destructive ops" undefined, output format unspecified
- **R11** — "audit remaining" has no scope or completion criteria
- **R13** — "tooling handles it" defers the entire design
- **R17** — MAR acronym undefined in document

### Success Criteria Issues

- "Zero permission prompts" — could be achieved by over-approving
- "Enforcement Triangle complete" — provenance enforcement may be warn-mode (OQ4 unresolved)
- "PROVIDER-SPEC ≥2 consumers" — contingent on two unresolved open questions (OQ1, OQ7)

---

## Agent 3: Stakeholder Review

**Confidence: HIGH.**

### Missing User Types

| User | Why Missing Matters |
|------|-------------------|
| Team adopter (2-5 humans) | No multi-principal onboarding story |
| AI-assisted OSS contributor | Needs framework without existing `usr/` structure |
| Ephemeral worktree agent | No permissions, dispatch visibility, or teardown lifecycle |
| Starter migrant | Distinct from "new adopter" — has existing config to preserve |
| CI/CD pipeline runner | No `usr/`, no `agency.yaml`, no session hooks — headless mode absent |

### Principal Bias

- `usr/jordan/` is the only populated example
- R4 relies on Jordan's transcript corpus — new adopter has zero transcripts
- R26 embeds Jordan's personal TODO in a product requirement
- No success criterion covers a non-`jdm` principal running agency-init

### Multi-Principal Gaps

- Second principal joins: no defined workflow
- Cross-principal dispatch delivery: receiving side may not exist yet
- `settings.json` is repo-wide, not per-principal — no override layer

### External Integration Gaps

- `gh` CLI is a hard undeclared dependency
- Non-GitHub hosting (GitLab) not addressed or excluded
- Editor integrations (VS Code, Zed) — "supported" but no requirements for what support means

---

## Agent 4: Feasibility Review

**Confidence: MEDIUM.**

### Concrete Bugs Found

| Bug | Impact |
|-----|--------|
| `dispatch` tool uses `claude/usr/$PRINCIPAL` (wrong path) | Silently breaks dispatch list/check/read |
| R16 can't be done with markdown hookify alone | Needs PreToolUse script that parses Write payload |
| R5 captain-only enforcement is soft (LLM-based) | Agent can ignore hookify rule |

### Already Done (partially or fully)

| Requirement | Status |
|-------------|--------|
| R1 (agency-init) | Code exists, largely addressed, needs smoke test |
| R2 (agency-update) | Core rsync works, tier model not implemented |
| R21 (secret) | Skill + tools exist, missing hookify rule |
| R22 (PM agent) | Exists, needs diff against monofolk |

### Hidden Complexity

| Requirement | Why It's Harder Than It Looks |
|-------------|-------------------------------|
| R2 (agency-update tier) | Building real tier system on rsync — file removals, additions, and content updates per tier |
| R5 (captain-only /pr) | No formal "I am captain" session identity signal |
| R13 (transcript dual-write) | Claude Code controls JSONL location. May need filesystem-level solution (symlinks, inotify) |
| R16 (provenance enforcement) | Current hookify rules are markdown instructions, not parsers. Needs PreToolUse hook. |
| R20 (prototype lifecycle) | 8 verbs × N providers + worktree isolation + promote signal flow = mini-orchestration |

### Missing Preconditions

- R5 needs captain-identity signal
- R14 needs R15 first (document → delete dispatcher → delete service)
- R16 needs PreToolUse content inspection infrastructure
- R7 needs compatibility review of SessionStart non-zero exit behavior
- R10 needs dispatch tool path bug fixed first

### Highest Risk

1. **R20 (Prototype pattern)** — multi-week, unclear scope, two unresolved OQs
2. **R14+R15 (Kill live code)** — actively referenced by multiple tools, has in-flight plan
3. **R13 (Transcript dual-write)** — may be unimplementable in current architecture
4. **R1 (agency-init)** — never tested against bare repo in CI-like environment

---

## Agent 5: Gap Analysis

**Confidence: HIGH.**

### Operational Gaps

| Gap | Impact |
|-----|--------|
| No error recovery for partial agency-init | Repo left in broken state |
| No agency-doctor / self-diagnostics | Adopter can't tell if framework is broken |
| agency-update conflict resolution undefined | What happens when framework file AND project file both changed? |
| SessionStart hook failure mode undefined | Hard fail blocks every session on misconfigured machine |
| No day-2 ops story | DB corruption, flag queue growth, mid-phase crashes — no recovery |

### Migration Gaps

| Gap | Impact |
|-----|--------|
| No step-by-step monofolk migration runbook | P0 requirement with no implementation path |
| Starter migrant path is a stub | "Mine, notify, archive" — not a migration guide |
| No backward compatibility policy | Killing agency-service breaks anyone using it |
| JSONL → SQLite flag migration undefined | agency-update could hit state where tool expects SQLite but data is JSONL |

### Versioning Gaps

| Gap | Impact |
|-----|--------|
| No version number on the framework | agency-update can't know what to update from |
| No release cadence defined | Adopters can't plan |
| No version pinning | Can't opt out of breaking changes |
| Update discovery undefined | How does framework know a new version exists? |

### Observability Gaps

| Gap | Impact |
|-----|--------|
| No cross-agent status view | "What are all my agents doing?" — no answer |
| No agent activity history | Per-session only, no agent-over-time view |
| No QG trend tracking | Data exists in QGRs but no aggregate signal |
| No dispatch pipeline visibility | No escalation for unread dispatches |
| No automated permission prompt counter | Success criterion requires manual measurement |

### Security Gaps

| Gap | Impact |
|-----|--------|
| Agent permission scope undefined | No model for what agents CAN'T do |
| No untrusted input handling policy | Seeds, dropbox, external integrations |
| Secret rotation absent | No `/secret rotate` |
| `~/.agency/` directory security posture | File permissions, multi-principal machines |
| Vouch model has no enforcement path | Policy without enforcement = prose |

### Skeptic's Questions

1. "Docker for all tests — what if I don't want Docker?"
2. "You killed the daemon. How is SQLite not just a slower daemon?"
3. "Pre-approving operations: isn't that just hiding the prompts?"
4. "What's the actual launch date? What's the go/no-go criteria?"
5. "How does a contributor know their hookify rule follows the Triangle correctly?"

---

## Consolidated Discussion Items for 1B1

Based on all 5 reviews, these are the items that need principal resolution before the PVR is final:

| # | Item | Source Agent(s) |
|---|------|----------------|
| 1 | **Docker contradiction**: R6 (P0 Docker mandate) vs Non-Requirements (Docker is provider concern) | Consistency, Gap, Feasibility |
| 2 | **Remove OQ3 and OQ5**: they re-open settled 1B1 decisions | Completeness |
| 3 | **Multi-principal story**: second human joins repo — what happens? | Stakeholder |
| 4 | **CI/headless mode**: runner has no usr/, no agency.yaml, no hooks | Stakeholder, Gap |
| 5 | **Error recovery**: partial init, agency-update conflicts, SessionStart failures | Gap |
| 6 | **Framework versioning**: how does agency-update know what to update from? | Gap |
| 7 | **R13 feasibility**: transcript dual-write may be unimplementable | Feasibility |
| 8 | **R16 mechanism**: provenance enforcement needs PreToolUse script, not markdown hookify | Feasibility |
| 9 | **Dispatch tool path bug**: `claude/usr/` vs `usr/` — fix before R10 | Feasibility |
| 10 | **Priority tier confirmation**: P2/P3 assignments were agent-judged, not principal-directed | Completeness |
| 11 | **Missing dependency edges**: 6-7 edges missing from Section 9 graph | Consistency |
| 12 | **agency-doctor**: should a self-diagnostics tool be a requirement? | Gap |
| 13 | **Launch criteria**: what makes Agency 2.0 "released"? | Gap |

---

*5-agent PVR MAR. First experiment with non-code review. 2026-04-05.*
