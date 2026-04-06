---
type: plan
project: valueflow
workstream: agency
date: 2026-04-07
status: MAR round 1 research complete — 4 disagree, 21 autonomous, 13 collaborative (all resolved). Agent reviews pending (#95 ISCP, #96 DevEx, #97 mdpal-cli). Awaiting principal approval.
author: the-agency/jordan/captain
pvr: claude/workstreams/agency/valueflow-pvr-20260406.md
ad: claude/workstreams/agency/valueflow-ad-20260406.md
---

# Valueflow V2 — Implementation Plan

## Overview

This is the **master plan** for Valueflow V2 — TheAgency's AI-Augmented Development Lifecycle. It coordinates work across multiple workstreams and agents. Each workstream owns its own implementation plan for its assigned phases; this plan defines the what, the who, and the sequencing.

The PVR defines 13 functional requirements, 8 non-functional requirements, and 5 constraints. The A&D designs 12 architectural areas. This plan maps those into deliverable phases owned by specific workstreams.

**Timeline target:** V2 foundation complete within 2 weeks of active work (NFR8: speed to value).

**Principle:** Each workstream writes its own implementation plan for its assigned work. This master plan defines scope boundaries, sequencing, dependencies, and acceptance criteria. Captain coordinates; agents deliver.

**Bootstrap protocol:** Week 1 Day 1 is seed dispatch + agent orientation. Real parallel work starts Day 2. Captain front-loads Phase 1 before dispatching seeds to ISCP/DevEx (see Phase 1 internal milestones). Expected commit cadence: at least one iteration-complete per agent per 2 working days. Captain checks worktree status daily via `git log`. Flag if no activity in 2 days.

---

## Workstream Assignments

### Existing Workstreams

| Workstream | Agent | Worktree | Role in V2 |
|------------|-------|----------|------------|
| **agency** | captain | master | Master plan, coordination, CLAUDE-THEAGENCY.md decomposition, valueflow docs, enforcement registry |
| **iscp** | iscp | `.claude/worktrees/iscp/` | Dispatch authority, dispatch-on-commit, symlink merge, flag categories, DB schema versioning, health metrics |
| **devex** | devex | `.claude/worktrees/devex/` | QG tiers, changed-file test scoping, context budget linter, enforcement audit tool, commit-precheck evolution |
| **mdpal** | mdpal-cli, mdpal-app | `.claude/worktrees/mdpal-cli/`, `.claude/worktrees/mdpal-app/` | Continue current work. Consuming workstream — validates valueflow as a user. Not a V2 deliverable workstream. |
| **mock-and-mark** | mock-and-mark | (no worktree yet) | Not started. Not a V2 deliverable workstream. |

### New Workstream Needed: None

No new workstreams are needed. The existing workstreams cover all V2 deliverables:

- **agency** (captain) owns the methodology artifacts — docs, decomposition, enforcement registry, MAR/MARFI skills
- **iscp** owns the messaging infrastructure — dispatch enhancements, flag categories, health metrics data layer
- **devex** owns the developer experience — QG tiers, test scoping, linting, audit tooling

The three workstreams form a clean separation: **methodology** (agency) → **messaging** (iscp) → **tooling** (devex). No gaps, no overlaps.

### New Agents Needed: None

All existing agents can absorb V2 work:
- Captain already coordinates MAR/MARFI — formalizing it into skills is natural
- ISCP agent already owns dispatch tooling — dispatch-on-commit and flag categories are extensions
- DevEx agent already owns commit-precheck — QG tiers and test scoping are extensions
- mdpal-cli and mdpal-app are consumers, not producers, of V2 — they validate it by using it

---

## Phases

### Phase 1: Documentation Foundation (agency — captain)

**Slug:** "CLAUDE-THEAGENCY.md Decomposition"

**What:** Decompose the monolithic CLAUDE-THEAGENCY.md into composable, concern-focused documents. This is the prerequisite for everything else — all other phases reference these docs.

**Owner:** agency workstream (captain on master)

**Delivers:**
- `claude/docs/VALUEFLOW.md` — flow stages, transitions, three-bucket, artifact types, day counting convention, escalation protocol (NFR3: when/how agents escalate)
- `claude/docs/MAR.md` — MAR protocol, reviewer profiles, triage format, dispatch templates
- `claude/docs/ENFORCEMENT-LADDER.md` — 5-stage ladder, registry format, per-workstream levels
- `claude/docs/CONTEXT-RESILIENCE.md` — handoff classes, PostCompact, stage-aware resume
- `claude/docs/CONTINUAL-LEARNING.md` — flag categories, transcript mining, telemetry, improvement loop
- Update `claude/docs/QUALITY-GATE.md` — add tier definitions (T1-T4)
- Update `claude/docs/GIT-DISCIPLINE.md` — add dispatch-on-commit protocol
- Update `claude/docs/ISCP-PROTOCOL.md` — consolidate from existing reference
- Thin CLAUDE-THEAGENCY.md wrapper that `@` imports the above
- Scoped `@` imports in all existing skills (each skill imports only what it needs)

**Internal milestones (publish incrementally to unblock downstream):**
1. Update `QUALITY-GATE.md` with tier definitions (T1-T4) → unblocks DevEx 3.1
2. Update `ISCP-PROTOCOL.md` → unblocks ISCP 2.2+
3. `MAR.md` + `VALUEFLOW.md` → unblocks Phase 4
4. Remaining docs + thin wrapper + skill `@` import audit → Phase 1 complete

**Acceptance criteria:**
- CLAUDE-THEAGENCY.md is ≤1500 tokens (thin wrapper)
- Each decomposed doc is ≤3000 tokens
- No skill injection exceeds 4000 tokens total (methodology + instructions)
- All existing skills updated with scoped `@` imports
- All information preserved — nothing lost in decomposition
- All existing agent sessions can cold-start with the decomposed CLAUDE-THEAGENCY.md (backward compatibility — C5)
- Old `@claude/CLAUDE-THEAGENCY.md` import still works (it's the entry point, just thinner)
- Phase 1 final commit gated on DevEx 3.4 (context budget linter) being merged to master first

**Dependencies:** None — this is the foundation. Co-ship gate: Phase 1 final commit waits for Phase 3.4.

**Sequencing:** Captain can do this on master. No worktree needed. Time-box: 4 working days (extended from 3 to account for skill audit scope). Commit incrementally — do not write all 8 docs in one session (context budget risk).

---

### Phase 2: ISCP Enhancements (iscp — iscp agent)

**Slug:** "Dispatch Authority + Flag Categories + Health Metrics"

**What:** Three ISCP extensions that underpin the valueflow messaging layer.

**Owner:** iscp workstream (iscp agent in worktree)

**Delivers:**

*Iteration 2.1: Dispatch Symlink Merge*
- Verify actual branch state (captain pre-checks `git diff main...iscp` before dispatching seed — symlink commit may already be on main)
- If already merged: verify and document; if not: merge, resolve any conflicts from 30 days of main divergence
- Verify all 173 tests pass
- Update dispatch tool documentation

*Iteration 2.2: Dispatch Authority Enforcement*
- `dispatch create` validates agent role against type's allowed creators (A&D §4)
- Captain-only: `directive`, `review`, `main-updated`
- Any agent: `seed`, `escalation`, `dispatch`
- Author-only: `review-response` (in reply to review)
- Automated: `commit` (from git-commit tool only)
- `agent-identity --agent` integration for role check

*Iteration 2.3: Flag Categories*
- `flag --friction "description"` → friction pipeline
- `flag --idea "description"` → idea pipeline
- `flag --bug "description"` → fix pipeline
- Category stored in DB, queryable via `flag list --category friction`
- Backward compatible — untagged flags still work

*Iteration 2.4: Dispatch-on-Commit*
- `git-commit` tool auto-creates commit dispatch to captain
- Structured YAML frontmatter: `commit_hash`, `stage_hash`, `branch`, `phase`, `iteration`, `files_changed`
- Captain receives and can verify QGR receipt via stage-hash match

*Iteration 2.5: Health Metrics Data Layer*
- `iscp-metrics` query tool with structured output:
  - Per-dispatch: `dispatch_id`, `created_at`, `read_at`, `resolved_at`, `lead_time_hours`
  - Per-category flag rates: `category`, `count`, `period`, `rate_per_day`
  - Output format: markdown table (human-readable) + structured YAML (machine-parseable)
- Test case: given N dispatches with known timestamps, verify correct lead time calculation
- DB schema version bump with migration

**Acceptance criteria:**
- Dispatch authority: unauthorized `dispatch create` fails with actionable error
- Flag categories: `flag list --category friction` returns only friction flags
- Dispatch-on-commit: every `/iteration-complete` auto-dispatches to captain
- Health metrics: `iscp-metrics` tool produces lead time and flag rate data
- All existing ISCP tests pass + new tests for each iteration

**Dependencies:**
- Phase 1 milestone 2 (ISCP-PROTOCOL.md update) — soft dependency, can start in parallel using current docs but should validate against updated protocol once available
- Symlink merge (2.1) is prerequisite for 2.2-2.5

**Sequencing:** Can start immediately. 2.1 first (unblock the rest), then 2.2-2.5 can be parallelized or sequential at agent's discretion.

---

### Phase 3: Quality Gate Evolution (devex — devex agent)

**Slug:** "QG Tiers + Test Scoping + Enforcement Audit"

**What:** Evolve the quality gate from one-size-fits-all to tiered gates with intelligent test scoping.

**Owner:** devex workstream (devex agent in worktree)

**Delivers:**

*Iteration 3.1: QG Tier Definitions*
- T1 (iteration): stage-hash + compile + format + fast tests, 60s budget
- T2 (phase commit): T1 + full relevant unit tests, 120s budget
- T3 (phase complete): full test suite, 5min budget
- T4 (pre-PR): full diff QG vs origin/main, 5min budget
- `commit-precheck` evolves to tier-aware (currently it's implicitly T1)

*Iteration 3.2: Changed-File Test Scoping*
- Convention-based default: `claude/tools/flag` → `tests/tools/flag.bats`
- Package-level fallback: `apps/mdpal/Sources/*` → `apps/mdpal/` test dir
- Manifest override for edge cases
- Integration with commit-precheck for T1/T2 scoping

*Iteration 3.3a: Enforcement Registry Schema + Audit Tool (no Phase 1 dependency)*
- `claude/config/enforcement.yaml` — registry schema and tooling
- Audit tool: validates that at level N, all artifacts for levels 1-N exist
- `enforcement audit` command — reports gaps and inconsistencies

*Iteration 3.3b: Enforcement Registry Population (hard dependency on Phase 1)*
- Populate registry with all capabilities and their ladder levels
- Per-workstream enforcement levels populated from Phase 1 docs
- Audit tool validated against populated registry

*Iteration 3.4: Context Budget Linter*
- Measures `@` import chain token counts per skill
- Warns when any skill exceeds 4000 tokens (methodology + instructions)
- Runs as part of commit-precheck for `.claude/` and `claude/` file changes
- Ships alongside Phase 1 decomposition (co-dependency — see below)

**Acceptance criteria:**
- T1 gate completes in <60s for a typical iteration commit
- Changed-file scoping correctly maps source → test for existing tools
- `enforcement audit` reports accurate ladder positions for all capabilities
- Context budget linter catches a skill that exceeds 4000 tokens

**Pre-requisite:** Captain writes a DevEx V2 scope brief before dispatching seed — not a full PVR cycle, but enough to charter 3.3-3.4 scope.

**Dependencies:**
- Phase 1 milestone 1 (QUALITY-GATE.md tier update) — unblocks 3.1, soft dependency
- Phase 1 full — hard dependency for 3.3b (registry population)
- Phase 1 decomposition MUST ship before or with 3.4 (context budget linter validates the decomposition)
- No dependency on Phase 2

*Iteration 3.5 (stretch): Conditional `if:` on hooks (NFR — platform-dependent)*
- Implement conditional hook firing when Claude Code platform support exists
- Skip if not available in V2 timeframe (C1 — we don't control the platform)

*Iteration 3.6 (stretch): `PermissionDenied` hook (NFR — platform-dependent)*
- Auto-retry or suggest correct permission when safe command is denied
- Skip if not available in V2 timeframe (C1)

**Co-ship protocol:** Phase 1 milestones M1-M3 flow freely — captain commits them independently. Only M4 (final wrapper + validation) is gated. Protocol: (1) DevEx lands 3.4 to master via `/phase-complete`, (2) captain runs linter against decomposed docs, (3) if linter passes: captain commits M4, (4) if linter fails: captain fixes budget violations, re-runs, commits. No timeout — M4 waits for 3.4.

**Sequencing:** Can start immediately. 3.1-3.2 are independent of Phase 1. 3.3a (schema/tool) independent. 3.3b (population) needs Phase 1. 3.4 co-ships with Phase 1.

---

### Phase 4: MAR & MARFI Skills (agency — captain)

**Slug:** "Multi-Agent Review + Research Skills"

**What:** Formalize MAR and MARFI into invocable skills with proper tooling.

**Owner:** agency workstream (captain on master)

**Delivers:**

*Iteration 4.1: `/mar` Skill*
- Skill wraps the MAR protocol from Phase 1 docs
- Captain selects reviewers based on artifact type and scope
- Dispatch templates for review requests with reviewer focus instructions
- Review instructions always include: "Give raw findings — do NOT sort into buckets"
- Three-bucket triage format with YAML frontmatter (A&D §2)
- 24h timeout for dispatched agent reviewers
- Hookify warn for committing PVR/A&D/Plan without MAR report (files matching `*-pvr-*.md`, `*-ad-*.md`, `*-plan-*.md`) — enforcement ladder level 4 for artifact gates
- Escalation hookify warn: fires when agent has N iterations without escalating — "Are you stuck? Use `flag --escalation`"

*Iteration 4.2: `/map` Skill (FR5 + FR11)*
- Formalizes cross-workstream RFI dispatch pattern (Multi-Agent Plan input)
- Captain dispatches RFIs to relevant agents: "This plan affects your workstream — what should we consider?"
- Reuses MAR dispatch infrastructure — MAP is MAR for plan input
- Covers FR11 intra-repo cross-workstream RFI routing via captain
- Skill definition + dispatch template + documentation in VALUEFLOW.md

*Iteration 4.3: `/marfi` Skill*
- Skill wraps the MARFI protocol
- Captain drafts research questions, principal reviews
- Subagents (sonnet, `effort: medium`, `run_in_background: true`)
- Output persisted to `seeds/marfi-{agent}-{date}.md` for durability
- Synthesis into MARFI brief

*Iteration 4.4: `/seed` Skill*
- Capture and route seeds to workstream/agent
- Synthesize seed materials (documents, transcripts, observations)
- Option to spin up new workstream if no existing one fits
- Hookify warn for raw seed file creation (use the skill)

*Iteration 4.5: Effort Levels on All Skills (FR4 coverage)*
- Audit all existing skills, add `effort:` level metadata
- High: QG, MAR, code-review, phase-complete
- Medium: define, design, plan, iteration-complete
- Low: flag, dispatch, seed, handoff, sync
- Verify `/define` and `/design` (FR4) have scoped `@` imports (from Phase 1) and effort metadata — FR4 satisfied by existing skills + these updates

**Acceptance criteria:**
- `/mar` produces a correctly formatted MAR report with three-bucket triage
- `/marfi` spins up parallel research agents and persists output to seeds/
- `/seed` captures and routes a seed to the correct workstream
- All skills have `effort:` metadata

**Dependencies:**
- Phase 1 docs (MAR.md, VALUEFLOW.md) — hard dependency for 4.1-4.3
- Phase 2 dispatch authority (for correct dispatch type enforcement in MAR) — soft dependency

**Sequencing:** Starts after Phase 1 completes. 4.1-4.3 sequential (each builds on the previous). 4.4 can run anytime.

---

### Phase 5: Context Resilience (agency — captain + devex — devex agent)

**Slug:** "Handoff Classes + PostCompact + Stage-Aware Resume"

**What:** Formalize the three handoff classes and improve context survival.

**Owner:** Split — agency (handoff design, docs) + devex (hook implementation)

**Delivers:**

*Iteration 5.0: Handoff Schema Contract (captain) — prerequisite for 5.1-5.4*
- Captain publishes multi-part handoff schema (from A&D §7) as a committed template
- Defines required sections: Identity, Current State, Active Context, Next Action, Working Set
- DevEx implements PostCompact and WorktreeCreate hooks against this schema
- This is the interface contract that makes the Phase 5 split safe

*Iteration 5.1: Three Handoff Classes (captain)*
- Session handoff — current (already works, formalize the structure)
- Agent bootstrap handoff — template for `/workstream-create` and `/worktree-create`
- Project bootstrap handoff — sit-rep template for assigning projects to existing agents
- Handoff tool updated to support all three classes

*Iteration 5.2: PostCompact Hook Enhancement (devex)*
- PostCompact hook re-injects handoff as system message
- Verify CLAUDE.md survives compaction (it should — document the guarantee)
- Multi-part handoff structure (identity, state, context, next action, working set)

*Iteration 5.3: Stage-Aware Resume Protocol (captain)*
- On session start: read handoff → dispatch check → verify artifacts → resume
- Formalize in CONTEXT-RESILIENCE.md
- Update all agent CLAUDE.md files with resume protocol

*Iteration 5.4: WorktreeCreate Hook (devex)*
- Hook fires when a new worktree is created
- Auto-triggers agent bootstrap handoff
- Auto-registers agent in `.claude/agents/`

**Acceptance criteria:**
- Agent bootstrap from `/worktree-create` produces a complete handoff
- PostCompact re-injection preserves enough context for the agent to resume
- Stage-aware resume correctly detects and processes queued dispatches

**Dependencies:**
- Phase 1 docs (CONTEXT-RESILIENCE.md) — hard dependency
- Phase 2 dispatch check (for stage-aware resume) — soft dependency

**Sequencing:** 5.0 first (schema contract). Then 5.1 and 5.2 can parallelize (captain + devex, both building against schema). 5.3-5.4 after 5.1. All start after Phase 1.

---

### Phase 6: Captain Loop + Ship Flow (agency — captain)

**Slug:** "Always-On Captain + Batch Processing"

**What:** Formalize the captain's always-on loop and batch commit processing.

**Owner:** agency workstream (captain on master)

**Delivers:**

*Iteration 6.1: Catch-Up Protocol*
- On restart: process all queued dispatches ordered by created_at
- Sync all worktrees
- Rebuild stale PR branches
- Report queue depth and aged dispatches
- Formalize as part of captain startup sequence
- Note: code can be written before 2.4, but integration testing requires dispatch-on-commit to be live

*Iteration 6.4: Health Metrics Summary (captain)*
- Captain summary report skill that runs `iscp-metrics` and formats for principal
- Covers SC7 (lead time) and SC8 (principal intervention frequency)
- Even CLI markdown output suffices — consuming interface for the Phase 2.5 data layer

*Iteration 6.2: Batch Commit Processing*
- Process all pending commit dispatches before syncing worktrees
- Captain merges each, flags conflicts
- Sync all worktrees after batch complete
- Integrates with dispatch-on-commit (Phase 2.4)

*Iteration 6.3: Ship Flow Enhancement*
- `/ship` skill: QG → commit → push → PR in one flow
- Phase boundary detection: build PR at phase boundaries, not iteration boundaries
- Release notes dispatch to collaboration repos on push (flag #4)

**Acceptance criteria:**
- Captain restart processes queued dispatches in order
- Batch processing merges N commits before syncing M worktrees (not interleaved)
- `/ship` completes the full QG → PR flow

**Dependencies:**
- Phase 2.4 (dispatch-on-commit) — hard dependency for 6.2 integration testing
- Phase 2.5 (health metrics data layer) — hard dependency for 6.4
- Phase 5.0 (handoff schema) — soft dependency for 6.1 sync step (informal model works, formal is better)
- Phase 4 (MAR skills) — soft dependency for ship flow QG integration

**Integration verification (captain owns):**
- After 2.4 + 6.2 land: test actual dispatch-on-commit → batch-process cycle end-to-end
- After 3.4 + Phase 1 land: run linter against decomposed docs, verify zero violations

**Sequencing:** 6.1 can start earlier (code, not integration test). 6.2 after Phase 2.4. 6.3 after Phase 4. 6.4 after Phase 2.5.

---

## Dependency Graph

```
Phase 1 (docs — incremental milestones)─────────────────────────────┐
  │ M1: QUALITY-GATE.md ──→ DevEx 3.1                               │
  │ M2: ISCP-PROTOCOL.md ──→ ISCP 2.2+                              │
  │ M3: MAR.md + VALUEFLOW.md ──→ Phase 4                           │
  │ M4: remaining + wrapper ──→ Phase 1 complete                     │
  │                                                                   │
  ├──→ Phase 4 (MAR/MARFI skills) ──→ Phase 6.3 (ship flow)         │
  │                                                                   │
  ├──→ Phase 5.0 (schema) → 5.1+5.2 (parallel) → 5.3+5.4           │
  │                                                                   │
  └──→ Phase 3.3b (registry population)                              │
       Phase 3.4 (linter) ←── co-ship gate: 3.4 lands THEN P1 ─────┘

Phase 2 (ISCP)───────────────────────────────────────────────────────
  │ 2.1 (symlink verify/merge) → 2.2-2.5 (parallel)
  │
  ├──→ 2.4 (dispatch-on-commit) ──→ Phase 6.2 (batch processing)
  └──→ 2.5 (health metrics) ──→ Phase 6.4 (metrics summary)

Phase 3 (devex)──────────────────────────────────────────────────────
  3.1-3.2 (QG tiers, test scoping) — start immediately (P1 M1 unblocks)
  3.3a (registry schema/tool) — no dependency
  3.3b (registry population) — hard dep on Phase 1 M4
  3.4 (context linter) — lands on master BEFORE Phase 1 final commit

Phase 5 (context resilience)─────────────────────────────────────────
  5.0 (handoff schema contract) — captain publishes first
  5.1 (handoff classes) + 5.2 (PostCompact) — parallel, both against schema
  5.3-5.4 — after 5.1
```

## Parallelism Opportunities

Three workstreams can run in parallel from day one:

| Time | agency (captain) | iscp (iscp agent) | devex (devex agent) |
|------|-------------------|-------------------|---------------------|
| Day 1 | Dispatch seeds + DevEx scope brief | Orientation + 2.1 verify | Orientation + start 3.1 |
| Days 2-5 | Phase 1 (incremental milestones) | Phase 2.1-2.3 | Phase 3.1-3.2 |
| Days 5-7 | Phase 1 M4 (gated on 3.4) → Phase 4 | Phase 2.4-2.5 | Phase 3.3a, 3.4 (land to master) |
| Days 7-9 | Phase 4 (MAR/MARFI) + 5.0 schema | — | Phase 3.3b + 5.2, 5.4 |
| Days 9-11 | Phase 5.1, 5.3 + Phase 6 | — | — |

**Note:** Phase 1 final commit explicitly gated on DevEx 3.4 landing first. ISCP/DevEx can start Day 1 but validate against Phase 1 milestones as they publish.

**Maximum parallelism:** 3 agents working simultaneously Days 2-7.

---

## Workstream Implementation Plans

Each workstream writes its own implementation plan with iteration-level detail:

| Workstream | Plan location | Owner | Scope |
|------------|--------------|-------|-------|
| agency | This document (captain coordinates) | captain | Phase 1, 4, 5.1/5.3, 6 |
| iscp | `claude/workstreams/iscp/iscp-valueflow-plan-20260407.md` | iscp agent | Phase 2 |
| devex | `claude/workstreams/devex/devex-valueflow-plan-20260407.md` | devex agent | Phase 3, 5.2/5.4 |

Captain dispatches seeds to each workstream with their scope, dependencies, and acceptance criteria from this master plan.

---

## What mdpal-cli, mdpal-app, and mock-and-mark Do

These are **consuming workstreams**, not V2 deliverable workstreams. They validate valueflow by using it:

- **mdpal-cli/mdpal-app:** Continue current Phase 1 work. As V2 tooling ships, they adopt it (enforcement ladder tightens). Their experience validates the methodology.
- **mock-and-mark:** Not started. When it starts, it goes through the full valueflow from seed — the first workstream to use V2 from day one. This is the acid test.

They do NOT need to pause for V2. V2 ships incrementally — each phase improves the tools they're already using.

**Cross-workstream dependency:** NFR1 (principal notification outside the terminal) depends on mdpal-app tray feature. Tracked in mdpal-app's plan, not this master plan. Captain tracks the dependency.

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Phase 1 decomposition takes too long | Blocks Phase 4 and parts of 3, 5 | Captain prioritizes Phase 1 as #1. Time-box to 4 working days. Incremental milestones unblock downstream early. |
| Context budget linter slips | Decomposition loses enforcement | Co-ship: DevEx lands 3.4 to master first, captain holds Phase 1 final gate. No timeout. |
| ISCP symlink merge has conflicts | Blocks Phase 2.2-2.5 | Captain pre-checks `git diff main...iscp` before dispatching seed. Documents actual delta. ISCP agent resolves conflicts first. |
| DevEx agent scope undefined | Phase 3.3-3.4 delivered without charter | Captain writes DevEx V2 scope brief before dispatching seed. Not a full PVR cycle — enough to charter 3.3/3.4 scope. |
| Three parallel agents = high coordination cost | Captain overwhelmed | Front-load Phase 1 before dispatch. Expected commit cadence: 1 iteration per 2 days. Flag if no activity in 2 days. |
| Phase 1 context exhaustion | Session compaction mid-decomposition | Commit incrementally (don't write all 8 docs in one session). Each milestone is a commit boundary. |
| Backward compatibility (C5) | Existing agents break on decomposed CLAUDE-THEAGENCY.md | Phase 1 acceptance: all existing agent cold-starts tested. Old `@` import path preserved. |
| In-flight consumer workstreams disrupted | mdpal-cli/mdpal-app break during V2 construction | Phase 1 decomposition is backward-compatible — thin wrapper at same path. Consuming workstreams don't need to change. |
| Phase 5 interface mismatch | PostCompact hook (devex) and handoff format (captain) don't agree | Phase 5.0 publishes handoff schema contract before parallel work begins. Both sides build against schema. |
| Integration gaps between workstreams | Assembled system doesn't work end-to-end | Captain owns explicit integration verification at key merge points (2.4+6.2, 3.4+Phase 1). |

---

## Success Criteria (from PVR)

This plan is complete when:

- [ ] SC1: Agent executes phases autonomously, surfacing only when needed — *measured via SC8 (principal intervention frequency from health metrics)*
- [ ] SC2: Zero rubber-stamp approvals — principal prompted only for judgment calls — *measured via SC8 + qualitative assessment*
- [ ] SC3: Every artifact has a gate (stage-hash enforced) — *measured by enforcement audit tool (Phase 3.3)*
- [ ] SC4: Context survives compaction (PostCompact + stage-aware resume) — *tested via Phase 5.2*
- [ ] SC5: Captain loop runs continuously with batch processing — *measured by captain loop uptime + dispatch processing latency*
- [ ] SC6: Low-cost remote check-ins work — *emergent from Phases 2 + 6 (captain loop + dispatch handling + health metrics summary); no dedicated iteration — validated by principal experience*
- [ ] SC7: Lead time measurable from ISCP timestamps — *delivered by Phase 2.5 + Phase 6.4*
- [ ] SC8: Principal intervention frequency measurable — *delivered by Phase 2.5 + Phase 6.4*

---

## MAR Round 1 — Research Reviewers

**Date:** 2026-04-07
**Reviewers:** 4 research subagents (feasibility, risk, dependency, scope) + 3 agent dispatches (ISCP #95, DevEx #96, mdpal-cli #97)
**Findings:** 38 total from research reviewers

### Disposition Summary

| Bucket | Count | Description |
|--------|-------|-------------|
| Disagree | 4 | NFR8 self-evident, /ship traced to FR7+FR8, consuming workstream agreement, clarification (not finding) |
| Autonomous | 21 | All incorporated into plan |
| Collaborative | 13 | All resolved via 1B1 with principal |

### Collaborative Resolutions (1B1 2026-04-07)

| # | Item | Resolution |
|---|------|------------|
| C1 | FR4 `/define` + `/design` | Covered by existing skills + Phase 1 `@` imports + Phase 4.5 effort metadata |
| C2 | FR5 MAP absent | New `/map` iteration added as Phase 4.2 |
| C3 | FR11 cross-workstream RFI | Covered by `/map` (C2) — same mechanism |
| C4 | FR13 transcript mining | **Deferred to late V2/V2.1.** Ship with flag categories + health metrics first. Lower priority, hardest to build well. |
| C5 | NFR1 MDPal tray | Cross-workstream dependency on mdpal-app, not a master plan deliverable |
| C6 | NFR3 escalation hook point | Escalation protocol in Phase 1 VALUEFLOW.md + hookify warn in Phase 4.1 |
| C7 | SC3 non-code artifact gate | Hookify warn for PVR/A&D/Plan commits without MAR, Phase 4.1, enforcement level 4 |
| C8 | SC6 remote check-ins | Emergent from Phases 2 + 6, note in SC, no iteration |
| C9 | `if:` hooks, `PermissionDenied` hook | DevEx stretch iterations 3.5 + 3.6, platform-dependent, skip if unavailable |
| C10 | Captain bottleneck | Front-load Phase 1 with protected focus. Incremental milestones unblock agents Day 2-3. |
| C11 | Flag #4 release notes | Promote to PVR FR14. Phase 6.3 traced to it. |
| C12 | Co-ship protocol | M1-M3 flow freely. M4 gated on 3.4. DevEx lands first, captain validates, no timeout. |
| C13 | Phase 1 internal sequencing | M1→M2→M3→M4 order confirmed. Each a commit boundary. |

### Agent Reviews (pending — dispatched)

- ISCP (#95): Review Phase 2 scope and sequencing
- DevEx (#96): Review Phase 3 scope and Phase 5 split
- mdpal-cli (#97): Review consuming workstream impact

---

## Next Action

1. ~~1B1 the 13 collaborative items with principal~~ ✅ All resolved
2. Promote flag #4 to PVR FR14 (release notes on push)
3. Incorporate agent review feedback when dispatches return (#95, #96, #97)
4. Principal approves plan
5. Captain writes DevEx V2 scope brief
6. Captain pre-checks `git diff main...iscp` for symlink merge state
7. Captain dispatches seeds to ISCP and DevEx with their assigned phases
8. Captain begins Phase 1 M1 (QUALITY-GATE.md tier update)
