---
type: ad
project: valueflow
workstream: agency
date: 2026-04-06
status: revised — MAR rounds 1+2 (research) incorporated, agent round 2 pending
author: the-agency/jordan/captain
pvr: claude/workstreams/agency/valueflow-pvr-20260406.md
mar-round-1: claude/workstreams/agency/reviews/mar-valueflow-ad-round1-20260406.md
mar-round-2-research: 4 subagents (methodology-critic, practitioner, adopter-advocate, lean-analyst)
---

# Valueflow — Architecture & Design

## Overview

This document designs the implementation of valueflow — TheAgency's AIADLC. It covers: the flow stages, multi-agent groups, enforcement ladder, captain architecture, quality gates, context resilience, dispatch payload architecture, CLAUDE-THEAGENCY.md decomposition, continual learning, error recovery, and the V2/V3 boundary.

The design draws from: the PVR (13 FRs, 8 NFRs, 5 constraints), MAR round 1 (4 research reviewers + 5 agent reviewers, 50 findings + 12 Q&A), MARFI research (Lean/SAFe/Shape Up/DORA, AI multi-agent patterns, enforcement patterns, Claude Code features), and the Day 30 session transcript.

**Revision note:** This is the post-MAR-round-1 revision. All 28 autonomous incorporations and 8 collaborative resolutions (with principal) applied. Embedded questions resolved. See MAR disposition: `claude/workstreams/agency/reviews/mar-valueflow-ad-round1-20260406.md`.

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
| Seed | Gleam — a thought, observation, transcript, flag; as little as a gleam in someone's eye | Seed document | None — capture is frictionless | Principal-driven |
| Define | Seed + MARFI brief (if research conducted) | PVR | MAR + principal sign-off | Collaborative |
| Design | PVR + MARFI (technical approach) | A&D | MAR + principal sign-off | Collaborative |
| Plan | PVR + A&D + MAP input (if cross-cutting) | Master plan + phase plans | MAR (autonomous for phase plans unless flagged) | Autonomous (phases) |
| Implement | Phase plan | Code + QGRs + commits | QG per iteration, QG per phase | Autonomous |
| Ship | Commits + QGRs | PRs merged to origin | Pre-PR QG | Captain-managed |
| Value | Shipped product | Customer feedback → new seeds | Customer adoption | V3 — feedback loop not in V2 scope |

**MARFI is a sub-protocol, not a stage.** It can trigger at any stage — not just at the beginning. Mid-flow research is valid: during A&D when a technical question arises, during planning when a dependency is discovered. The driving agent decides when research input is needed.

### Artifact Types

Every artifact in valueflow has a type, a canonical location, and a naming convention.

| Artifact | Type slug | Location | Naming |
|----------|-----------|----------|--------|
| Seed | `seed` | `claude/workstreams/{ws}/seeds/` | `seed-{topic}-{YYYYMMDD}.md` |
| MARFI brief | `marfi` | `claude/workstreams/{ws}/seeds/` | `marfi-{project}-{YYYYMMDD}.md` |
| PVR | `pvr` | `claude/workstreams/{ws}/` | `{project}[-{subproject}]-pvr-{YYYYMMDD}.md` |
| A&D | `ad` | `claude/workstreams/{ws}/` | `{project}[-{subproject}]-ad-{YYYYMMDD}.md` |
| Plan | `plan` | `claude/workstreams/{ws}/` | `{project}[-{subproject}]-plan-{YYYYMMDD}.md` |
| QGR | `qgr` | `claude/workstreams/{ws}/reviews/` | `qgr-{boundary}-{phase.iter}-{stage-hash}-{YYYYMMDD-HHMM}.md` |
| MAR report | `mar` | `claude/workstreams/{ws}/reviews/` | `mar-{artifact}-round{N}-{YYYYMMDD}.md` |
| Transcript | `transcript` | `usr/{principal}/{project}/transcripts/` | `{topic}-{YYYYMMDD-HHMM}.md` |
| Handoff | `handoff` | `usr/{principal}/{project}/` | `{agent}-handoff.md` |
| Dispatch payload | `dispatch` | Git (author's branch/worktree) + symlink in `~/.agency/{repo}/dispatches/` | `{type}-{slug}-{YYYYMMDD-HHMM}.md` |

Sub-project qualifiers are optional in naming (e.g., `dashboards-mcc-pvr-20260402.md`).

### Transition Protocol

Each stage transition follows:

1. Author declares artifact complete
2. Gate runs (MAR or QG depending on artifact type)
3. Gate produces artifact (MAR report or QGR) — paired to the artifact version
4. Author triages feedback (three-bucket)
5. Revisions if needed → re-gate (new MAR disposition paired to revised artifact)
6. Principal sign-off (at scope-definition boundaries: PVR, A&D, master plan)
7. Transition to next stage

**Autonomous stages skip step 6.** Phase plans, iterations, and implementation transitions don't require principal sign-off unless the agent escalates. The agent triages MAR feedback, acts on all three buckets independently, and sends an informational dispatch to the principal: "here's what came in, here's what I did." Principal sees it on next check-in. Only scope-definition stages (PVR, A&D, master plan) get the full present-and-discuss flow.

---

## 2. Three-Bucket Disposition Protocol

### Mechanism

When an agent receives feedback (from MAR, QG, or any review):

1. **Collect** — receive raw findings from all reviewers
2. **Triage** — author categorizes each finding:
   - **Disagree** — finding rejected with reasoning. Reject when: the finding is based on incorrect premises, conflicts with a principal decision, is superseded by other work, or proposes a change that would violate a constraint. Always state the reasoning.
   - **Autonomous** — finding accepted, author incorporates independently
   - **Collaborative** — finding requires principal input
3. **Present** — for scope-definition artifacts, author presents full triage to principal:
   - Disagree items: table with finding + reasoning
   - Autonomous items: table with finding + action taken
   - Collaborative items: 1B1 discussion
   - Principal reviews all three buckets — can move items between buckets
   For autonomous stages: author triages and acts, sends informational dispatch to principal
4. **Revise** artifact based on final dispositions
5. **Record** — triage documented in MAR report for audit trail, paired to artifact version

**Important:** Reviewers give raw feedback (findings, concerns, questions). The **author** triages into buckets, not the reviewer. This must be stated explicitly in every MAR dispatch — agents default to self-sorting if not told otherwise.

### Dispatch Formats

**Review input** (from reviewers): free-form markdown. Raw findings, no structure required.

**Triage response** (from author): structured tables with YAML frontmatter for metrics:

```yaml
type: review-response
subject: "MAR triage: {artifact} — {N} disagree, {N} autonomous, {N} collaborative"
findings_count: N
disagree: N
autonomous: N
collaborative: N
```

Body contains three tables (disagree, autonomous, collaborative) with finding ID, source reviewer, finding text, and disposition reasoning. This enables FR12 health metrics (automated tracking of finding resolution rates) without requiring full schema validation.

---

## 3. Multi-Agent Groups

### Overview

| Group | Purpose | When | V2 Mechanism |
|-------|---------|------|-------------|
| **MARFI** | Research input — cross-cutting questions answerable with web search + docs | Before any artifact authoring, or mid-flow when research question arises | Subagents (ephemeral, sonnet) |
| **MAR** | Review of artifacts — many eyes, all bugs are shallow | After every artifact, always, never skipped | Subagents (research) + dispatches (agents) |
| **MAP** | Planning input from multiple workstreams | Cross-cutting complex projects only | Captain dispatches RFI to relevant agents |

### MARFI (Multi-Agent Request for Information)

**Purpose:** Research input before authoring an artifact.

**When:** Before PVR (always for new work), before A&D (always), before Plan (cross-cutting projects), and mid-flow when a research question arises. NOT for domain-specific exploration — that's the agent's normal work.

**Decision rule:** MARFI is for questions answerable with web search + reading docs (cross-cutting research). Domain research — questions requiring understanding the project's constraints and design decisions — is the agent's normal work and doesn't need captain mediation.

**Protocol:**
1. Driving agent drafts research questions
2. Principal reviews and adds questions (MARFI process gate)
3. Captain spins up N research agents (sonnet model, `effort: medium`)
4. Agents execute in parallel (background, `run_in_background: true`)
5. **Agents write output to `claude/workstreams/{ws}/seeds/marfi-{agent}-{date}.md` for durability** — if the session crashes mid-MARFI, research is preserved
6. Results returned to driving agent
7. Driving agent synthesizes into MARFI brief

**Agent composition:** V2: generic subagents, ephemeral, no persistent identity. V3: dispatched agents for cross-machine research (ClaudeCorp).

### MAR (Multi-Agent Review)

**Purpose:** Review of artifacts at every transition with three-bucket disposition.

**When:** After every artifact (PVR, A&D, Plan, QGR at phase boundary). Always. MAR is never skipped — it is the equivalent of pair programming. Many eyes, all bugs are shallow (Linus's Law). With AI agents, the cost of review is seconds, not hours. There is no reason not to review everything. Captain scales the reviewer group to match artifact significance — a trivial revision gets 1-2 subagents (seconds), a major artifact gets the full research + agent review.

**Protocol:**
1. Author declares artifact ready for review
2. Captain dispatches review request to **relevant** reviewers (not broadcast — captain selects based on artifact scope)
3. **Review dispatch includes reviewer focus:** "Review from perspective of: {focus area}" — tells the reviewer what angle to evaluate from
4. Review instructions (in every MAR dispatch): "Give raw findings — concerns, gaps, questions, what works. Do NOT sort into buckets. The author triages — not you."
5. Reviewers respond via dispatch (review-response type)
6. **Timeouts:** Subagent reviewers (within-session): complete in seconds to minutes — if a subagent errors, proceed without it. Dispatched agent reviewers (cross-session): 24-hour timeout, auto-proceed with available reviews. Flag missing reviewers. Do not block indefinitely on dormant agents.
7. Author collects all findings, triages into three buckets
8. For scope-definition artifacts: present full triage to principal. For autonomous stages: triage and act, inform principal via dispatch.
9. Revise, re-review if needed. MAR disposition is versioned — paired to the artifact version it reviewed.

**Reviewer selection:** Per artifact type. "N relevant agents" — captain selects agents whose workstream is affected, not all agents.

| Artifact | Research reviewer profiles | Agent reviewers |
|----------|---------------------------|-----------------|
| PVR | Methodology critic, practitioner, adopter advocate, Lean analyst | Agents whose workstreams are affected |
| A&D | Security, performance, maintainability, testability | Agents who will implement or consume |
| Plan | Feasibility, risk, dependency, scope | Agents whose workstreams are affected |
| Code (QG) | Existing 7-agent QG protocol | N/A (subagents only) |

**V2:** Research reviewers are subagents (sonnet, `effort: high`). Agent reviewers receive dispatches.

**V3 target architecture:** Named subagents with `SendMessage` for within-session MAR. `--fork-session` for parallel reviewer branches from same checkpoint.

### MAP (Multi-Agent Plan Input)

**Purpose:** Planning input from multiple agents/workstreams for complex cross-cutting projects.

**When:** Cross-cutting projects spanning multiple workstreams. Single-workstream plans skip MAP — the driving agent drafts the plan, MAR reviews it.

**Protocol:**
1. Captain identifies relevant agents across workstreams: "anyone I should speak with?"
2. Captain dispatches RFI: "This plan will affect your workstream — what should we consider?"
3. Agents respond with constraints, dependencies, concerns
4. Driving agent incorporates into plan seed
5. Plan seed + PVR + A&D → plan mode

---

## 4. Enforcement Ladder Architecture

### Ordering

1. **Document** — CLAUDE-THEAGENCY.md + README-THEAGENCY.md. Human-readable, no tooling. Step 1 for adopters: read the docs, follow conventions manually.
2. **Skill** — wraps the documented process in an invocable skill. References docs via `@` import.
3. **Tool** — builds the mechanical capability. Pre-approved in settings.json.
4. **Hookify warn** — warns when the tool is bypassed. Points to the skill. "You should use X — here's how."
5. **Hookify block** — blocks the bypass. Tool is the only path. Can't proceed without it.

**Tools before warn.** You build the tool first, then warn about bypassing it. Warning before the tool exists tells agents "don't do X" without giving them the alternative.

**Each layer addresses the bypass discovered in the previous layer.** Gate on artifact existence (mechanical, auditable), not on artifact quality (human judgment).

### Enforcement Registry

Each capability declares its current ladder position in `claude/config/enforcement.yaml`:

```yaml
capabilities:
  git-safe-commit:
    level: 5  # block
    tool: claude/tools/git-safe-commit
    skill: .claude/skills/git-safe-commit/SKILL.md
    hookify-warn: claude/hookify/hookify.warn-whw-header.md
    hookify-block: claude/hookify/hookify.block-git-safe-commit.md
    doc: claude/docs/VALUEFLOW.md#commit-workflow
  
  mar:
    level: 1  # document only
    doc: claude/docs/VALUEFLOW.md#mar
    # skill, tool, hookify TBD
```

**The audit tool is a load-bearing dependency.** The registry only has value if it's validated against reality. DevEx builds the audit tool alongside the registry — no registry without an auditor. The audit tool checks: at level N, do all artifacts for levels 1-N actually exist?

### Per-Workstream Enforcement

Each workstream can be at a different ladder level for each capability. Active workstreams at higher enforcement, dormant workstreams at lower.

```yaml
workstreams:
  iscp:
    git-safe-commit: 5  # block — fully enforced
    mar: 2         # skill — working from docs
  devex:
    git-safe-commit: 3  # tool — tool exists, no hookify yet
    mar: 1         # document only
```

**Enforcement level transitions are principal decisions.** The audit tool informs, agents recommend, captain presents — but the principal decides when to tighten. DRI is the principal. No automatic transitions.

### Dispatch Authority

Dispatch type creation is gated by agent role at enforcement ladder level 3 (tool enforcement) from day one:

| Dispatch type | Who can create |
|---------------|---------------|
| directive | captain only |
| review | captain only |
| seed | any agent |
| review-response | artifact author (in reply to review) |
| commit | automated (git-safe-commit tool) |
| main-updated | captain only (sync-all) |
| escalation | any agent |
| dispatch | any agent (general communication) |

Enforced via: dispatch tool checks `agent-identity --agent` against the type's allowed creators.

---

## 5. Captain Architecture

### Always-On

Captain is always-on by design. First up, last down. If any agent is running, captain is running. Not running is a holiday — we aren't working.

**V2 mechanism:** Interactive sessions. Captain runs in a terminal session whenever work is happening. Between sessions, dispatches queue in ISCP DB — no work is lost. No automation runs outside an active session.

**V3 mechanism:** Headless daemon (`--bare -p`). Captain runs continuously, processes dispatches as they arrive. ClaudeCorp-ready.

**The behavior is the same — the mechanism changes.**

### Two Modes

**Always-on loop** (V2: `/loop 5m dispatch check`):
```
every 5 minutes:
  dispatch check → process unread
  commit dispatches → merge, sync worktrees (batched)
  phase-complete dispatches → build PR, pre-PR QG, push
  escalations → triage before all other work
  flags → capture or triage
```

**Interactive session:** Principal sits down, captain switches to conversational mode. Seeds, PVR discussions, MAR triage, strategic decisions.

### Captain Catch-Up Protocol

On restart (after "holiday" or crash):
1. Process all queued dispatches (ISCP DB, ordered by created_at)
2. Sync all worktrees with main
3. Rebuild any stale PR branches
4. Report queue depth and any aged dispatches (>N hours old) — surfaces the "no response" problem
5. Resume normal loop

### Commit Processing

Dispatch-on-commit is **additive** to `/phase-complete`. Defense in depth — multiple layers, each catches what the one before missed.

**Iteration commits (dispatch-on-commit) — coordination path:**
1. Agent commits via `/iteration-complete`
2. `git-safe-commit` tool auto-dispatches to captain (commit type)
3. Commit dispatch carries structured YAML: `commit_hash`, `stage_hash`, `branch`, `phase`, `iteration`, `files_changed`
4. Captain verifies QGR receipt (stage-hash match from dispatch — no need to read worktree)
5. Merge commit to main (fast-forward if clean, flag if conflict)
6. Batch: don't sync worktrees until all pending commits processed
7. Sync all worktrees after batch complete

**Phase commits (`/phase-complete`) — quality + shipping path (separate mechanism):**
1. Agent completes phase via `/phase-complete`
2. Deep QG (T3) — full test suite, MAR on phase artifacts
3. Squash merge to main
4. Build PR branch, pre-PR QG (T4), push to origin

These are two different mechanisms at two different boundaries serving different purposes. Dispatch-on-commit is coordination (captain knows, merges, syncs). Phase-complete is quality and shipping (deep gate, PR, origin). Both verify stage-hash, but for different reasons at different scopes.

---

## 6. Quality Gate Architecture

### Gate Tiers

Gates are tiered by commit boundary type:

| Tier | Boundary | Checks | Time budget |
|------|----------|--------|-------------|
| T1 | Iteration commit | Stage-hash match + build/compile + format + relevant fast tests | **<60s** |
| T2 | Phase commit | T1 + full relevant unit tests (changed-file scoping) | <120s |
| T3 | Phase complete | Full test suite (Docker) + MAR on phase artifacts | <5min |
| T4 | Pre-PR | Full diff QG vs origin/main | <5min |

**T1 = stage-hash + compile + format + fast tests, 60 second budget.** This is iteration complete — the agent finished a unit of work. 60s is generous for scoped tests. If tests exceed the budget, test scoping needs improvement, not skipping. Format runs on save AND at T1 (belt and suspenders — both cheap).

**T1 baseline is universal:** `stage-hash match + build/compile` works for every language. Format and lint are optional per language toolchain (Swift has no standard linter, JS has eslint). Relevant unit tests included if they fit the time budget.

### Changed-File Test Scoping

**Convention-based as default:** `claude/tools/flag` → `tests/tools/flag.bats` (path mirroring). Zero-config, covers 90% of cases.

**Package-level fallback:** For non-mirrored layouts (Swift, Rust, Go packages): "anything in `apps/mdpal/Sources/` changed → run tests in `apps/mdpal/`." This handles projects where test paths don't mirror source paths.

**Manifest as override:** For edge cases where convention and package-level don't map, a tool can declare its test file in metadata.

### Stage-Hash Delta Tolerance

If the delta between QGR hash and current staged hash is **exclusively markdown files** (all changed files are `.md`) → allow with warning. Any non-markdown file in the delta → re-run QG. If the commit contains both a markdown change and a code change, re-run. Simpler and less ambiguous than "non-code files changed" (is `package.json` code? Yes — re-run).

### Test Hermiticity

All tests run in isolation. No test may modify:
- `.git/config` (live repo config)
- Live databases (`~/.agency/*/iscp.db`)
- Working directory outside allocated temp space

Enforced via:
- `ISCP_DB_PATH` override (existing, ISCP efa00d6)
- `GIT_CONFIG_GLOBAL=/dev/null` + `GIT_CONFIG_SYSTEM=/dev/null` (existing)
- Teardown guard: hash `.git/config` before/after, fail if changed (existing)
- Docker runner for full-suite (existing, needs extension to all test files)
- **T3 Docker fallback:** if Docker is not running, T3 falls back to in-process test execution with full isolation helpers. Warn that Docker is preferred. Do not block or skip — degraded is better than absent.

---

## 7. Context Resilience Architecture

### Three Handoff Classes

1. **Session handoff** — between sessions. Current state, next action, working set. Written on SessionEnd, PreCompact, at boundary commands.
2. **Agent bootstrap handoff** — triggered when captain creates a new agent on a workstream (via `/workstream-create` or `/worktree-create`). V2: `WorktreeCreate` hook (Claude Code feature, detailed in PVR MARFI) auto-triggers bootstrap. Everything the agent needs to start working: identity, role, seeds, first action.
3. **Agent project bootstrap handoff** — captain assigns a project to an existing agent. A "sit rep": everything they need to succeed. Links to transcripts, documents, and relevant context.

### Multi-Part Handoff Structure

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
```

Multi-part is the **ceiling**, not the floor. Simple bootstraps work with a single file. Complex agents use full structure.

### PostCompact Hook

**CLAUDE.md survives compaction** — it's system-level context that Claude Code preserves. PostCompact only needs to inject **session-specific context** that was compressed.

PostCompact hook re-injects the handoff as a system message:

```json
{
  "event": "PostCompact",
  "command": "cat usr/{principal}/{project}/{agent}-handoff.md"
}
```

**Injection scope:** Handoff only. CLAUDE.md is already present. Keep handoffs tight, CLAUDE.md light. The decomposition of CLAUDE-THEAGENCY.md into composable chunks (§9) saves context budget for handoff injection and actual work. Every token saved in CLAUDE.md is a token available for conversation.

### Intra-Session Handoffs

Handoffs are not just for session boundaries — they're **insurance checkpoints** within a session. Written at boundary commands, at `/sync-all`, at discussion milestones. If compaction or crash occurs, the most recent checkpoint provides recovery. The better the handoff, the less context loss matters.

### Stage-Aware Resume

On session start or post-compaction, agent verifies:
1. Read handoff → know identity, stage, next action
2. `dispatch check` → process unread items
3. Verify current stage artifacts exist and are consistent
4. Resume from Next Action

### Transcript Injection

Pull last N transcripts of relevant work into new sessions. Enables more frequent compaction without losing context. Session transcripts stored in git; index stored outside git (avoid conflicts). Agent-written summaries now; Anthropic API could automate later.

---

## 8. Dispatch Payload Architecture

### Symlink Design (Principal Decision)

Dispatch payloads stay in git (C3 — source of truth, auditable). Branch-transparent access via symlinks in `~/.agency/{repo}/dispatches/`:

```
~/.agency/the-agency/
  iscp.db                    — notification DB (existing)
  dispatches/                — symlinks to git artifacts (NEW)
    dispatch-001.md → /Users/jdm/code/the-agency/claude/workstreams/agency/valueflow-pvr-20260406.md
    dispatch-002.md → /Users/jdm/code/the-agency/.claude/worktrees/devex/usr/jordan/devex/some-artifact.md
```

**How it works:**
- Artifacts stay in git on their branch/worktree (C3 holds)
- `~/.agency/{repo}/dispatches/` contains symlinks to the filesystem path
- OS resolves symlinks — no git commands needed to read
- Works for main checkout AND worktrees (both are real directories on disk)
- Dangling symlinks = worktree deleted or artifact moved. Detectable: `readlink -e` returns error. Dispatch read warns with actionable message.

**Dispatch tool changes:**
1. On `dispatch create`: write payload to correct git location, create symlink in `~/.agency/{repo}/dispatches/`
2. On `dispatch read`: follow symlink. If dangling, warn and fall back to legacy 4-strategy resolution
3. DB `payload_path` stores the symlink name

**Local vs cross-repo distinction:** Local dispatches use DB + symlinks. Cross-repo dispatches are git-only via collaboration repos (different mechanism, same addressing).

**Implementation status:** ISCP implemented in commit 1e610fd (dispatch #74). 173 tests passing. Merge pending.

### DB Schema Versioning

Version column in ISCP DB, checked on every init. Migration tool handles version transitions. Prevents version skew when agents share the DB.

### Dispatch Retention

Archive resolved dispatches after 30 days. Clean up symlinks when payloads are archived. Prevents unbounded DB and filesystem growth.

### Dispatch Create

`dispatch create` requires `--body` (content) or `--template` (explicit opt-in). No content = no dispatch = fail loud. Template mode is opt-in, not default. Implemented in ISCP commit 85d874d.

---

## 9. CLAUDE-THEAGENCY.md Decomposition

### Three-Level Hierarchy

1. **CLAUDE-THEAGENCY.md** — methodology (imports composable docs)
2. **CLAUDE-{WORKSTREAM}.md** — workstream scope, conventions, boundaries
3. **CLAUDE-{APP/SERVICE}.md** — application/service-specific instructions (V3: autonomous generation)

### Taxonomy: By Concern

Decompose CLAUDE-THEAGENCY.md into focused documents, each `@`-importable:

| Document | Content | Imported by |
|----------|---------|------------|
| `claude/docs/VALUEFLOW.md` | The flow, stages, transitions, three-bucket, enforcement ladder | All agents (via CLAUDE-THEAGENCY.md) |
| `claude/docs/MAR.md` | MAR protocol, reviewer profiles, triage format | MAR skills, review skills |
| `claude/docs/QUALITY-GATE.md` | QG protocol, tiers, stage-hash, QGR format | Already exists — update |
| `claude/docs/GIT-DISCIPLINE.md` | Commit workflow, captain merge, PR lifecycle | git-safe-commit skill, captain |
| `claude/docs/ISCP-PROTOCOL.md` | Dispatch, flag, addressing, hook integration | ISCP skills, all agents |
| `claude/docs/ENFORCEMENT-LADDER.md` | The 5-stage ladder, registry, per-workstream levels | Enforcement skills, DevEx |
| `claude/docs/CONTEXT-RESILIENCE.md` | Handoffs, PostCompact, stage-aware resume, transcripts | All agents |
| `claude/docs/CONTINUAL-LEARNING.md` | Transcript mining, flag categories, telemetry, improvement loop | Captain, DevEx |

CLAUDE-THEAGENCY.md becomes a thin wrapper that `@` imports all of the above. Skills import only what they need.

**Minimum viable adoption (start here):** Flow stages (§1) + three-bucket protocol (§2) + MAR at level 1 (docs only, manual review) + session handoffs. No tooling required. Read the docs, follow the conventions manually. This is enforcement ladder step 1 — everything else builds from here.

### Context Budget

Budget per **skill injection** (4000 tokens total), not per document. A doc can be 3000 tokens if the skill adds only 1000 tokens of its own instructions. The goal: no skill exceeds 4000 tokens of methodology + instructions.

**Context budget linter is a V2 deliverable** — ships alongside the decomposition. Measures `@` import chain token counts. Warns when a skill exceeds budget. DevEx builds this. **Risk:** if the linter slips, the decomposition loses its enforcement mechanism. Linter and decomposition must ship together or neither ships.

### Fragment Registry (V3)

Machine-readable manifest tracking all CLAUDE.md fragments: locations, import chains, token counts. Enables autonomous fragment generation and import chain validation. V3 — requires tooling maturity.

---

## 10. Continual Learning Architecture

### Three Input Channels

**1. Flag mechanism** — categorized quick-capture at the moment of observation:
- `flag --friction "description"` → friction pipeline (improvement candidates)
- `flag --idea "description"` → seed pipeline (new work candidates)
- `flag --bug "description"` → fix pipeline (immediate action)

Categories at capture, not at triage. `--friction` costs one word and routes instantly. Deferring categorization to triage leaves an undifferentiated pile. Capture IS routing.

Flags are triaged via `/flag-triage` skill (three-bucket: resolved, autonomous, collaborative).

**2. Transcript mining** — automated pattern extraction:
- Session transcripts at `usr/{principal}/{project}/transcripts/`
- Granola transcripts (summary + raw) at same location
- Mining tool extracts: decisions, friction points, recurring patterns, tool usage
- **Token budget per mining run** — limit scope, prioritize recent sessions (last N days)
- Output: seeds for improvement

**3. Telemetry** — `_log-helper` data + ISCP timestamps:
- Tool invocation counts and durations
- Dispatch lead times (created → read → resolved)
- Flag accumulation rates by category
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

### Day Counting

Measure working days per repo and per workstream. Day N = Nth day with commits. "Day 12 of valueflow for mdpal" = 12 days of active work. Compare to calendar days for velocity signal. Proposed as Agency model convention.

---

## 11. Error Recovery

### Failure Modes and Responses

| Failure | Response |
|---------|----------|
| QG fails repeatedly | **Time-based circuit breaker:** if no progress in N hours (configurable per workstream, default 5 iterations worth of time), agent self-reports: stuck vs making distinct progress. If stuck, escalate to principal. Principal can override with reasoning (audited). |
| MAR produces irreconcilable disagreements | Author presents all positions to principal. Principal decides. Decision recorded in MAR report. |
| Agent stuck in implementation loop | Captain monitors commit frequency. If no commit in expected timeframe, dispatch escalation to agent + flag to principal. |
| Dispatch sent to non-existent agent | Dispatch tool fails loud with actionable error. Try to resolve — agent may not be registered yet but worktree may exist. DB record created with status "undeliverable." Captain notified. |
| Context lost after compaction | PostCompact hook re-injects handoff. Agent runs stage-aware resume. If handoff is stale/missing, agent flags and waits for principal. |
| Phase not converging | Principal can invoke circuit breaker: kill the phase, pivot, or re-scope. Audited decision. No autonomous kill — principal judgment required. |
| Cross-workstream RFI no response | 24-hour timeout. Proceed with available input. Flag missing responders for information. |
| Captain down (crash or session end) | Dispatches queue in ISCP DB. On restart: catch-up protocol (§5). No work lost. |

### Escalation Protocol

Agents escalate via `flag --escalation "description"` or `dispatch create --type escalation`. Captain triages escalations before all other work. Principal is notified via MDPal tray or direct terminal message.

---

## 12. V2/V3 Boundary

### V2 Delivers

- Flow stages documented in CLAUDE-THEAGENCY.md (decomposed by concern)
- Three-bucket protocol documented and enforced via MAR skill
- MARFI as subagents (within-session), output persisted to seeds/ for durability
- MAR via dispatches (cross-session) + subagents (within-session), 24h timeout
- Enforcement ladder with registry + audit tool
- Captain always-on (session-based), `/loop 5m dispatch check`
- Quality gate tiers (T1-T4) with changed-file scoping, T1 at 60s budget
- Multi-part handoffs + PostCompact hook (handoff only, CLAUDE.md survives)
- Three handoff classes (session, agent bootstrap, project bootstrap)
- Flag categories (`--friction`, `--idea`, `--bug`)
- Health metrics from ISCP timestamps (lead time, principal intervention frequency)
- Dispatch authority enforcement at ladder level 3
- Dispatch payload symlinks (implemented, merge pending)
- `dispatch create` requires `--body` (implemented)
- `effort:` levels on all skills
- `WorktreeCreate` hook for auto-registration
- Conditional `if:` on hooks for efficiency
- `PermissionDenied` hook for safe-command retry
- Context budget linter (ships with decomposition)
- Day counting convention

### V3 Extends

- Named subagents + `SendMessage` for MAR
- `--fork-session` for parallel review branches
- `--bare -p` headless captain loop (ClaudeCorp)
- `--json-schema` output validation
- `stream-json` orchestration
- `--session-id` deterministic sessions
- Cross-repo agent access for MARFI
- Value → Seed feedback loop
- CLAUDE.md fragment registry + autonomous generation
- Event-driven captain (vs fixed-interval polling)
- Transcript injection via Anthropic API

---

## Resolved Questions (from MAR Round 1)

All embedded questions resolved:

| Question | Resolution | Source |
|----------|-----------|--------|
| MAR triage schema | Free-form V2 with YAML frontmatter. Structured schema V3. | ISCP |
| MARFI: dispatches or subagents | Subagents V2, dispatches V3. Write to seeds/ for durability. | ISCP |
| Commit dispatch carry stage-hash | Yes. Structured YAML frontmatter. | ISCP |
| Dispatch payload architecture | Symlinks to git artifacts. Implemented. | Principal decision + ISCP |
| Changed-file test mapping | Convention-based default, package-level fallback, manifest override. | monofolk + mdpal-cli |
| Stage-hash semantic diff | Single markdown file → allow with warning. Any other change → re-run. | ISCP |
| Context budget linter | V2 deliverable. DevEx builds. Warn at 4000 tokens per skill. | monofolk |
| Enforcement registry | YAML manifest + audit tool. No registry without auditor. | monofolk |
| Captain loop cadence | Fixed interval V2 (`/loop 5m dispatch check`). Event-driven V3. | monofolk + mdpal-cli |
| Compaction strategy | Claude Code controls timing (~80% used). We control recovery via handoffs + PostCompact. | Principal |
| PostCompact injection scope | Handoff only. CLAUDE.md survives compaction. | Principal |
| Enforcement transitions | Principal decides. DRI is the principal. | Principal |
| Effort levels | Anthropic's abstraction over token budget. We set the dial per skill. | Principal |
