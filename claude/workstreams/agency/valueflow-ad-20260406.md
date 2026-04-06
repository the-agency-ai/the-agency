---
type: ad
project: valueflow
workstream: agency
date: 2026-04-06
status: draft — pending MAR
author: the-agency/jordan/captain
pvr: claude/workstreams/agency/valueflow-pvr-20260406.md
---

# Valueflow — Architecture & Design

## Overview

This document designs the implementation of valueflow — TheAgency's AIADLC. It covers: the flow stages, multi-agent groups, enforcement ladder, captain loop, quality gates, context resilience, continual learning, and the CLAUDE-THEAGENCY.md decomposition.

The design draws from: the PVR (13 FRs, 8 NFRs, 5 constraints), MAR rounds 1-2 (9 reviewers), MARFI research (Lean/SAFe/Shape Up/DORA, AI multi-agent patterns, enforcement patterns, Claude Code features), and the session 20 transcript.

---

## 1. Flow Stage Architecture

### Stage Model

Each stage in the valueflow is a first-class concept with defined inputs, outputs, gates, and transitions.

```
Stage {
  name: string           — "seed", "define", "design", "plan", "implement", "ship", "value"
  inputs: Artifact[]     — what enters the stage
  outputs: Artifact[]    — what the stage produces
  gate: Gate             — what must pass before transition
  actors: Agent[]        — who does the work
  autonomy: Level        — "principal-driven" | "collaborative" | "autonomous"
}
```

| Stage | Inputs | Outputs | Gate | Autonomy |
|-------|--------|---------|------|----------|
| Seed | Gleam (observation, transcript, flag) | Seed document | None — capture is frictionless | Principal-driven |
| Research (MARFI) | Seed + research questions (principal-reviewed) | MARFI brief | Principal reviews questions before agents spin up | Collaborative |
| Define | Seed + MARFI brief | PVR | MAR + principal sign-off | Collaborative |
| Design | PVR + MARFI (technical approach) | A&D | MAR + principal sign-off | Collaborative |
| Plan | PVR + A&D + MAP input (if cross-cutting) | Master plan + phase plans | MAR (autonomous for phase plans unless flagged) | Autonomous (phases) |
| Implement | Phase plan | Code + QGRs + commits | QG per iteration, QG per phase | Autonomous |
| Ship | Commits + QGRs | PRs merged to origin | Pre-PR QG | Captain-managed |
| Value | Shipped product | Customer feedback → new seeds (V3) | Customer adoption | — |

### Artifact Types

Every artifact in valueflow has a type, a canonical location, and a naming convention.

| Artifact | Type slug | Location | Naming |
|----------|-----------|----------|--------|
| Seed | `seed` | `claude/workstreams/{ws}/seeds/` | `seed-{topic}-{YYYYMMDD}.md` |
| MARFI brief | `marfi` | `claude/workstreams/{ws}/seeds/` | `marfi-{project}-{YYYYMMDD}.md` |
| PVR | `pvr` | `claude/workstreams/{ws}/` | `{project}-pvr-{YYYYMMDD}.md` |
| A&D | `ad` | `claude/workstreams/{ws}/` | `{project}-ad-{YYYYMMDD}.md` |
| Plan | `plan` | `claude/workstreams/{ws}/` | `{project}-plan-{YYYYMMDD}.md` |
| QGR | `qgr` | `claude/workstreams/{ws}/reviews/` | `qgr-{boundary}-{phase.iter}-{stage-hash}-{YYYYMMDD-HHMM}.md` |
| MAR report | `mar` | `claude/workstreams/{ws}/reviews/` | `mar-{artifact}-round{N}-{YYYYMMDD}.md` |
| Transcript | `transcript` | `usr/{principal}/{project}/transcripts/` | `{topic}-{YYYYMMDD-HHMM}.md` |
| Handoff | `handoff` | `usr/{principal}/{project}/` | `{agent}-handoff.md` |
| Dispatch payload | `dispatch` | TBD (see Section 8) | `{type}-{slug}-{YYYYMMDD-HHMM}.md` |

### Transition Protocol

Each stage transition follows:

1. Author declares artifact complete
2. Gate runs (MAR or QG depending on artifact type)
3. Gate produces artifact (MAR report or QGR)
4. Author triages feedback (three-bucket)
5. Revisions if needed → re-gate
6. Principal sign-off (at scope-definition boundaries: PVR, A&D, master plan)
7. Transition to next stage

**Autonomous stages skip step 6** — phase plans, iterations, and implementation transitions don't require principal sign-off unless the agent escalates.

---

## 2. Three-Bucket Disposition Protocol

### Mechanism

When an agent receives feedback (from MAR, QG, or any review):

1. **Collect** — receive raw findings from all reviewers
2. **Triage** — author categorizes each finding:
   - **Disagree** — finding rejected with reasoning
   - **Autonomous** — finding accepted, author incorporates independently
   - **Collaborative** — finding requires principal input
3. **Present** — author presents triage to principal:
   - Disagree items: table with finding + reasoning
   - Autonomous items: table with finding + action taken
   - Collaborative items: 1B1 discussion
4. **Principal reviews** all three buckets — can move items between buckets
5. **Revise** artifact based on final dispositions
6. **Record** — triage documented in MAR report for audit trail

### Dispatch Format for MAR Results

```yaml
type: review-response
subject: "MAR triage: {artifact} — {N} disagree, {N} autonomous, {N} collaborative"
```

Body contains three tables (disagree, autonomous, collaborative) with finding ID, source reviewer, finding text, and disposition reasoning.

**Question for ISCP:** Should MAR triage be a structured dispatch type with schema validation, or free-form markdown? Structured enables automated tracking of finding resolution rates (FR12 health metrics). Free-form is simpler to implement.

---

## 3. Multi-Agent Groups

### MARFI (Multi-Agent Request for Information)

**Purpose:** Research input before authoring an artifact.

**When:** Before PVR (always for new work), before A&D (always), before Plan (cross-cutting projects). NOT for domain-specific exploration — that's the agent's normal work.

**Protocol:**
1. Driving agent drafts research questions
2. Principal reviews and adds questions
3. Captain spins up N research agents (sonnet model, `effort: medium`)
4. Agents execute in parallel (background, `run_in_background: true`)
5. Results returned to driving agent
6. Driving agent synthesizes into MARFI brief

**Agent composition:** Research agents are generic — they receive a focused question and research it. No persistent identity. Spawned per-MARFI, destroyed after.

**Question for ISCP:** Should MARFI agents be dispatched (cross-session, durable) or subagents (within-session, ephemeral)? For V2, subagents are simpler. For V3 with ClaudeCorp, dispatches enable cross-machine research.

### MAR (Multi-Agent Review)

**Purpose:** Three-bucket review of artifacts at every transition.

**When:** After every artifact (PVR, A&D, Plan, QGR at phase boundary). Always.

**Protocol:**
1. Author declares artifact ready for review
2. Captain dispatches review request to selected reviewers
3. Review instructions: "Give raw findings — concerns, gaps, questions, what works. Do NOT sort into buckets."
4. Reviewers respond via dispatch (review-response type)
5. Author collects all findings, triages into three buckets
6. Author presents triage to principal (for scope-definition artifacts) or processes autonomously (for phase plans, iterations)
7. Revise, re-review if needed

**Reviewer selection:** Per artifact type:

| Artifact | Reviewer profiles | Count |
|----------|-------------------|-------|
| PVR | Methodology critic, practitioner, adopter advocate, Lean analyst + all active agents | 4 research + N agents |
| A&D | Security, performance, maintainability, testability + relevant agents | 4 research + N agents |
| Plan | Feasibility, risk, dependency, scope + relevant agents | 4 research + N agents |
| Code (QG) | Existing 7-agent QG protocol (security, logic, perf, style, edge-case, integration, documentation) | 7 |

**V2:** Research reviewers are subagents (sonnet, `effort: high`). Agent reviewers receive dispatches.

**V3 target architecture:** Named subagents with `SendMessage` for within-session MAR. `--fork-session` for parallel reviewer branches from same checkpoint.

**Question for DevEx:** Should MAR review dispatches carry a deadline? What happens if a reviewer doesn't respond within N hours? Auto-proceed with available reviews, or block?

### MAP (Multi-Agent Plan Input)

**Purpose:** Planning input from multiple agents/workstreams for complex projects.

**When:** Cross-cutting projects spanning multiple workstreams. Single-workstream plans skip MAP.

**Protocol:**
1. Captain identifies relevant agents across workstreams
2. Captain dispatches RFI: "This plan will affect your workstream — what should we consider?"
3. Agents respond with constraints, dependencies, concerns
4. Driving agent incorporates into plan seed
5. Plan seed + PVR + A&D → plan mode

---

## 4. Enforcement Ladder Architecture

### Revised Ordering

Based on ISCP MAR round 2 feedback, the ladder ordering is refined:

1. **Document** — CLAUDE-THEAGENCY.md + README-THEAGENCY.md. Human-readable, no tooling. Step 1 for adopters.
2. **Skill** — wraps the documented process in an invocable skill. References docs via `@` import.
3. **Tool** — builds the mechanical capability. Pre-approved in settings.json.
4. **Hookify warn** — warns when the tool is bypassed. Points to the skill.
5. **Hookify block** — blocks the bypass. Tool is the only path.

The change from the PVR: **tools before warn.** You build the tool first, then warn about bypassing it. Warning before the tool exists tells agents "don't do X" without giving them the alternative.

### Enforcement Registry

Each capability declares its current ladder position:

```yaml
# claude/config/enforcement.yaml
capabilities:
  git-commit:
    level: 5  # block
    tool: claude/tools/git-commit
    skill: .claude/skills/git-commit/SKILL.md
    hookify-warn: claude/hookify/hookify.warn-whw-header.md
    hookify-block: claude/hookify/hookify.block-git-commit.md
    doc: claude/docs/VALUEFLOW.md#commit-workflow
  
  mar:
    level: 1  # document only
    doc: claude/docs/VALUEFLOW.md#mar
    # skill, tool, hookify TBD
```

**Question for DevEx:** Can you build an audit tool that reads this registry and validates that each declared level actually has the corresponding artifacts? E.g., level 3 (tool) requires: doc exists, skill exists, tool exists and is executable.

### Per-Workstream Enforcement

Each workstream can be at a different ladder level for each capability. Active workstreams at higher enforcement, dormant workstreams at lower.

```yaml
# Per workstream in enforcement.yaml
workstreams:
  iscp:
    git-commit: 5  # block — fully enforced
    mar: 2         # skill — working from docs
  devex:
    git-commit: 3  # tool — tool exists, no hookify yet
    mar: 1         # document only
```

---

## 5. Captain Architecture

### Two Modes

**Always-on loop:**
```
while true:
  fetch origin
  dispatch list --status unread → process each
  commit dispatches → merge, sync worktrees (batched)
  phase-complete dispatches → build PR, pre-PR QG, push
  escalations → flag for principal
  flags → triage or capture
  sleep(cadence)
```

**Interactive session:** Principal sits down, captain switches to conversational mode. Seeds, PVR discussions, MAR triage, strategic decisions.

### Captain Catch-Up Protocol

On restart (after "holiday" or crash):
1. Process all queued dispatches (ISCP DB, ordered by created_at)
2. Sync all worktrees with main
3. Rebuild any stale PR branches
4. Report queue depth and any aged dispatches (>N hours old)
5. Resume normal loop

### Commit Processing

1. Receive `commit` dispatch from agent
2. Verify QGR receipt exists for the commit (stage-hash match)
3. Merge commit to main (fast-forward if clean, flag if conflict)
4. Batch: don't sync worktrees until all pending commits processed
5. Sync all worktrees after batch complete
6. At phase boundary: build PR branch, run pre-PR QG, push to origin

**Question for ISCP:** Should commit dispatches carry the stage-hash so captain can verify without reading the worktree? This would enable verification before merge.

---

## 6. Quality Gate Architecture

### Gate Tiers

Based on MAR feedback, gates are tiered by commit boundary type:

| Tier | Boundary | Checks | Time budget |
|------|----------|--------|-------------|
| T1 | Iteration commit | Format + lint on changed files + stage-hash match | <10s |
| T2 | Phase commit | T1 + relevant unit tests (changed-file scoping) | <60s |
| T3 | Phase complete | Full test suite (Docker) + MAR on phase artifacts | <5min |
| T4 | Pre-PR | Full diff QG vs origin/main | <5min |

### Changed-File Test Scoping

**Question for DevEx:** What's the right mechanism for mapping changed files to relevant tests?

Options:
1. **Convention-based:** `claude/tools/flag` → `tests/tools/flag.bats` (path mirroring)
2. **Manifest:** each tool declares its test file in metadata
3. **Tag-based:** tests tagged with the files/modules they cover

Recommend option 1 (convention) with option 2 (manifest) as fallback for non-obvious mappings.

### Stage-Hash Delta Tolerance

ISCP raised: what if you amend a typo after running QG? The hash changes. Full re-run for a comment?

Design: if the delta between QGR hash and current staged hash is below a threshold, allow with warning. Threshold: only non-code files changed (markdown, comments, whitespace). Any code change = re-run.

**Question for DevEx:** Can you implement a "semantic diff" that distinguishes code changes from non-code changes in the stage-hash comparison?

### Test Hermiticity (NFR9 from DevEx MAR)

All tests run in isolation. No test may modify:
- `.git/config`
- Live databases (`~/.agency/*/iscp.db`)
- Working directory outside temp space

Enforced via:
- `ISCP_DB_PATH` override (existing)
- `GIT_CONFIG_GLOBAL=/dev/null` (existing)
- Teardown guard: hash `.git/config` before/after, fail if changed (existing)
- Docker runner for full-suite (existing, needs extension to all 32 files)

---

## 7. Context Resilience Architecture

### Multi-Part Handoff

Handoff files structured in sections for selective re-injection:

```markdown
---
type: handoff
agent: the-agency/jordan/devex
stage: implement
phase: 1
iteration: 3
date: 2026-04-06T06:00
---

## Identity
Agent: the-agency/jordan/devex
Workstream: devex
Role: test infrastructure, commit workflow, permissions

## Current State
Phase 1, Iteration 3: pre-commit rewrite
Last commit: abc1234 — smart test scoping for changed files

## Active Context
- Key decision: convention-based test scoping (path mirroring)
- Blocker: none
- Open MAR: dispatch #55 (valueflow PVR round 2)

## Next Action
Implement timeout with graceful degradation in commit-precheck

## Working Set
- claude/tools/commit-precheck (rewriting)
- tests/tools/commit-precheck.bats (new)
- claude/config/test-manifest.yaml (new, if manifest approach)
```

### PostCompact Hook

On compaction, re-inject the handoff as a system message:

```javascript
// .claude/hooks/post-compact.js
{
  "event": "PostCompact",
  "command": "cat usr/{principal}/{project}/{agent}-handoff.md",
  "output": "systemMessage"
}
```

Minimal injection: Identity + Current State + Next Action. Full injection if context budget allows.

### Stage-Aware Resume

On session start or post-compaction, agent verifies:
1. Read handoff → know identity, stage, next action
2. `dispatch list` → process unread items
3. Verify current stage artifacts exist and are consistent
4. Resume from Next Action

---

## 8. Dispatch Payload Architecture

### Current Problem

Dispatch payloads in git cause three classes of bugs:
1. Branch transparency — payloads on one branch invisible to others
2. Template confusion — `dispatch create` writes templates agents don't edit
3. Path derivation — payload path derived from branch name, breaks on PR branches

### Proposed Design: Payloads Alongside DB

Move dispatch payloads from git to `~/.agency/{repo}/dispatches/`:

```
~/.agency/the-agency/
  iscp.db                    — notification DB (existing)
  dispatches/                — payload files (NEW)
    dispatch-001.md
    dispatch-002.md
    ...
```

**Advantages:**
- Branch-transparent by default (no git branch issues)
- No template confusion (tool writes content directly)
- No path derivation bugs (ID-based naming, not branch-based)
- Mutable (can be updated, unlike git-immutable payloads)
- Consistent with DB — both are operational state, not source artifacts

**Disadvantages:**
- Not in git — no version history, no audit trail in commits
- Not visible in PRs
- Backup responsibility shifts to filesystem

**Mitigation:** Important dispatches (directives, reviews, seeds) get committed to git as well — the dispatch tool writes to both locations. The `~/.agency/` copy is the primary read path; the git copy is the audit trail.

**Question for ISCP:** Is this the right direction? Can you design the migration path — both the schema change (payload_path points to `~/.agency/` instead of git) and the backward compatibility (read from both locations during transition)?

### Dispatch Authority

Based on ISCP MAR feedback, dispatch type creation is gated by agent role:

| Dispatch type | Who can create |
|---------------|---------------|
| directive | captain only |
| review | captain only |
| seed | any agent |
| review-response | artifact author (in reply to review) |
| commit | automated (git-commit tool) |
| main-updated | captain only (sync-all) |
| escalation | any agent |
| dispatch | any agent (general communication) |

Enforced via: dispatch tool checks `agent-identity --agent` against the type's allowed creators. Hookify block on unauthorized dispatch types.

---

## 9. CLAUDE-THEAGENCY.md Decomposition

### Taxonomy: By Concern

Decompose into focused documents, each `@`-importable:

| Document | Content | Imported by |
|----------|---------|------------|
| `claude/docs/VALUEFLOW.md` | The flow, stages, transitions, three-bucket, enforcement ladder | All agents (via CLAUDE-THEAGENCY.md) |
| `claude/docs/MAR.md` | MAR protocol, reviewer profiles, triage format | MAR skills, review skills |
| `claude/docs/QUALITY-GATE.md` | QG protocol, tiers, stage-hash, QGR format | Already exists — update |
| `claude/docs/GIT-DISCIPLINE.md` | Commit workflow, captain merge, PR lifecycle | git-commit skill, captain |
| `claude/docs/ISCP-PROTOCOL.md` | Dispatch, flag, addressing, hook integration | ISCP skills, all agents |
| `claude/docs/ENFORCEMENT-LADDER.md` | The 5-stage ladder, registry, per-workstream levels | Enforcement skills, DevEx |
| `claude/docs/CONTEXT-RESILIENCE.md` | Handoffs, PostCompact, stage-aware resume | All agents |
| `claude/docs/CONTINUAL-LEARNING.md` | Transcript mining, flag categories, telemetry, improvement loop | Captain, DevEx |

CLAUDE-THEAGENCY.md becomes a thin wrapper that `@` imports all of the above. Skills import only what they need.

### Context Budget

Each document stays under 2000 tokens. If it exceeds that, split further. The goal: a skill never injects more than 4000 tokens of methodology docs (the skill's own instructions + the relevant `@` import).

**Question for DevEx:** Can you build a context budget linter that measures the token count of each `@` import chain and warns when a skill exceeds the budget?

---

## 10. Continual Learning Architecture

### Three Input Channels

**1. Flag mechanism** — categorized quick-capture:
- `flag --friction "description"` → friction pipeline
- `flag --idea "description"` → seed pipeline  
- `flag --bug "description"` → fix pipeline

Flags are triaged via `/flag-triage` skill (three-bucket: resolved, autonomous, collaborative).

**2. Transcript mining** — automated pattern extraction:
- Session transcripts at `usr/{principal}/{project}/transcripts/`
- Granola transcripts (summary + raw) at same location
- Mining tool extracts: decisions, friction points, recurring patterns, tool usage
- Output: seeds for improvement

**3. Telemetry** — `_log-helper` data + ISCP timestamps:
- Tool invocation counts and durations
- Dispatch lead times (created → read → resolved)
- Flag accumulation rates
- Permission prompt frequency (target: zero for safe ops)
- Context window consumption per skill

### Improvement Loop

```
Observe (flags, transcripts, telemetry)
  → Identify (patterns, friction, waste)
    → Seed (create seed for improvement)
      → Valueflow (the improvement goes through the full flow)
        → Ship (improved tooling deployed)
          → Observe (measure improvement)
```

The methodology improves itself through itself.

---

## 11. Error Recovery

### Failure Modes and Responses

| Failure | Response |
|---------|----------|
| QG fails repeatedly on same code | Agent flags for principal escalation after 3 attempts. Circuit breaker: principal can override with reasoning (audited). |
| MAR produces irreconcilable disagreements | Author presents all positions to principal. Principal decides. Decision recorded in MAR report. |
| Agent stuck in implementation loop | Captain monitors commit frequency. If no commit in N iterations, dispatch escalation to agent + flag to principal. |
| Dispatch sent to non-existent agent | Dispatch tool fails loud with actionable error. DB record created with status "undeliverable." Captain notified. |
| Context lost after compaction | PostCompact hook re-injects handoff. Agent runs stage-aware resume. If handoff is stale/missing, agent flags and waits. |
| Phase not converging | Principal can invoke circuit breaker: kill the phase, pivot, or re-scope. Audited decision. No autonomous kill — principal judgment required. |

### Escalation Protocol

Agents escalate via `flag --escalation "description"` or `dispatch create --type escalation`. Captain triages escalations before all other work. Principal is notified via MDPal tray (V2) or direct terminal message.

---

## 12. V2/V3 Boundary

### V2 Delivers

- Flow stages documented in CLAUDE-THEAGENCY.md (decomposed)
- Three-bucket protocol documented and enforced via MAR skill
- MARFI as subagents (within-session)
- MAR via dispatches (cross-session) + subagents (within-session)
- Enforcement ladder with registry
- Captain always-on loop (within session, `/loop` based)
- Quality gate tiers (T1-T4) with changed-file scoping
- Multi-part handoffs + PostCompact hook
- Flag categories (--friction, --idea, --bug)
- Health metrics from ISCP timestamps
- Dispatch authority enforcement
- `effort:` levels on all skills
- `WorktreeCreate` hook for auto-registration
- Conditional `if:` on hooks for efficiency
- `PermissionDenied` hook for safe-command retry

### V3 Extends

- Named subagents + `SendMessage` for MAR
- `--fork-session` for parallel review branches
- `--bare -p` headless captain loop (ClaudeCorp)
- `--json-schema` output validation
- `stream-json` orchestration
- `--session-id` deterministic sessions
- Cross-repo agent access for MARFI
- Value → Seed feedback loop
- Dispatch payloads outside git (if design validated)

---

## Open A&D Questions

These are carried forward for resolution during implementation planning:

1. **MAR dispatch structure** — schema-validated or free-form? (Question for ISCP)
2. **Changed-file test mapping** — convention, manifest, or tags? (Question for DevEx)
3. **Stage-hash semantic diff** — code vs non-code delta tolerance (Question for DevEx)
4. **Context budget linter** — measure `@` import chain token counts (Question for DevEx)
5. **Dispatch payload migration** — payloads alongside DB feasibility (Question for ISCP)
6. **Enforcement registry format** — YAML manifest, validated by audit tool (Question for DevEx)
7. **Captain loop cadence** — fixed interval or event-driven? (Implementation decision)
8. **Compaction strategy** — when to trigger, what PreCompact captures (Implementation decision)
