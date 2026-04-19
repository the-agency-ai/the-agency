# What Problem: The CLAUDE-THEAGENCY.md bootloader is too large for efficient
# context injection. The development methodology section needs to be a standalone
# reference doc for targeted injection by skills and hooks.
#
# How & Why: Extracted from CLAUDE-THEAGENCY.md "Development Methodology" section
# (lines 294-365), updated from the old 5-step flow to the canonical 9-step
# Valueflow, and enriched with Multi-Agent Coordination Types, Three-Bucket
# Disposition, and Plan Mode Bias sections that were missing from the original doc.
#
# Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring)

## Development Methodology

This is how we develop. Not a suggestion — the process.

### The Flow (Valueflow)

```
Idea → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
```

1. **Idea** — a thought, observation, conversation. That gleam in someone's eye. Pre-seed.
2. **Seed** — captured starting point (document, transcript, idea, flag). Launches the discussion.
3. **Research (MARFI)** — Multi-Agent Request for Information. Captain drafts research questions, principal reviews, agents execute in parallel. Cross-cutting research only.
4. **Define (PVR)** — Product Vision & Requirements. The _what_ and _why_. Use `/define`. MAR reviews it.
5. **Design (A&D)** — Architecture & Design. The _how_ and _why_. Use `/design`. MAR reviews it.
6. **Plan** — Phases x Iterations. May have MAP (Multi-Agent Plan input) for cross-cutting work. MAR reviews it.
7. **Implement** — Agents execute autonomously. QG at every iteration boundary. Updated after every commit.
8. **Ship** — Captain merges, builds PRs, pushes. Pre-PR QG.
9. **Value** — Customer using it. Feedback generates new seeds.

Three living documents (PVR, A&D, Plan) evolve together. The flow: **Requirements → A&D + Plan (evolving through iteration) → Reference** (produced at plan completion).

### Multi-Agent Coordination Types

| Type | Purpose | When |
|------|---------|------|
| **MARFI** (Multi-Agent Request for Information) | Research input — cross-cutting questions answerable with web search + docs | Before PVR/A&D, or mid-flow when a research question arises |
| **MAR** (Multi-Agent Review) | Review of artifacts at every transition with three-bucket disposition | After every artifact (PVR, A&D, Plan, code at QG boundaries) |
| **MAP** (Multi-Agent Plan input) | Planning input from multiple agents/workstreams | Cross-cutting projects spanning multiple workstreams |

### Three-Bucket Disposition

When an agent receives feedback (from MAR, QG, or any review), it triages findings into three buckets:

| Bucket | What | Who decides |
|--------|------|-------------|
| **Disagree** | Finding rejected with reasoning | Agent decides, principal reviews |
| **Autonomous** | Agent agrees and incorporates independently | Agent acts, principal informed |
| **Collaborative** | Requires principal input | 1B1 discussion |

**Important:** Reviewers give raw findings. The **author** triages into buckets, not the reviewer. Reviewers review; authors triage.

### Plan Mode Bias

**Use plan mode.** For any non-trivial task, enter plan mode first — explore the codebase, understand existing patterns, design your approach, get principal alignment, then implement. The cost of planning is low; the cost of rework is high.

- **Discuss → Plan → Review Plan → Revise → Implement.** This is the work pattern.
- Plan mode is read-only exploration and design. No code changes until the plan is approved.
- If the principal says "plan" or "plan mode," enter plan mode. Don't write a markdown file instead.
- Complex tasks, multi-file changes, architectural decisions, and unclear requirements all warrant plan mode.
- Simple, directed fixes (typo, one-line change, clear instructions) can skip plan mode.

### Execution

- **Phases** are whole numbers: Phase 1, Phase 2, Phase 3. **Iterations** are Phase.Iteration: 1.1, 1.2, 2.1. **No letters** — only numbers.
- **Every phase and iteration carries a slug** (e.g., "Phase 2: Provider Abstraction"). The slug is the stable identifier — renumber freely.
- **Commit at boundaries** — `/iteration-complete` (auto), `/phase-complete` (approval), `/plan-complete` (final). See the QG Protocol section.
- **Pre-phase review** — run `/pre-phase-review` before starting the next phase. Multi-agent review of PVR, A&D, Plan. Principal approval required to proceed.

### Quality Gates

- **Iteration QG** — scoped to the work in that iteration. Standard parallel review (2+ code, 2+ test agents + own review). Commit automatically after clean QGR. No approval needed.
- **Phase QG** — deep review of the **entire project codebase**, not just changes. More agents, more coverage areas, deeper inspection. Explicitly considers design alignment with A&D. **Approval required** to commit.
- **Quality Phases** — dedicated phases that are all about inspection, test development, and issue remediation. Still get a QG and QGR.
- **QGR (Quality Gate Report)** — appended to the Plan after every QG. The three tables + summary are the receipts.

### At Phase Completion (Sprint Review)

1. Squash iteration commits into a single phase commit
2. Deep QG scoped to full project codebase
3. Commit message documents all work done with pointers to project documents (PVR, A&D, Plan)
4. QGR generated and appended to Plan automatically
5. Present QGR and proposed commit inline — **principal must approve**
6. After approval, land via PR (Day 40+ — branch protection requires PR):
   a. Run `/release` skill (or manual: `git-safe-commit` → `git-push` → `pr-create`)
   b. `/release` handles: commit + push branch + create PR + bump version
   c. CI runs (smoke test). Branch protection requires status check + approval.
   d. Principal merges PR via GitHub
   e. Captain runs `/post-merge` to sync, create GitHub release tag
7. **Flag conditions** — stop and report to principal if:
   - `pr-create` blocks (missing QGR receipt, no version bump, on main)
   - `/release` blocks at version bump (manifest.json not updated)
   - CI fails on the PR
   - Branch protection rejects merge (no approval, CI failed)

### Pre-Phase Review

Before starting any new phase, conduct a structured review of all living artifacts:

1. **Multi-agent review of PVR, A&D, and Plan** — always happens.
2. **Consolidate and highlight findings** — always present to the principal, even if everything looks clean.
3. **If issues require decisions** — spin up sub-agents to debate options. Present recommendation.
4. **If no issues** — "PVR, A&D, and Plan reviewed. No changes needed. Proceeding to Phase N."
5. **Update PVR, A&D, and Plan** as needed based on decisions made.
6. **Get clearance** from the principal to proceed to the next phase.

### At Plan Completion

1. Final deep QG across the full scope
2. Finalize the Plan — all phases done, all QGRs captured
3. Finalize the A&D — reflects reality, not aspirations
4. Produce the **Reference** document — the final "this is how it works" documentation
5. Master already contains the squashed phase commits — no additional squash needed.
6. **PRs are created by the captain on master** — not by worktree agents.

### Artifacts

| Artifact | Abbrev | Content | Lifecycle |
|----------|--------|---------|-----------|
| Product Vision & Requirements | PVR | What and why | Evolves through discussion + implementation |
| Architecture & Design | A&D | How and why (technical decisions) | Evolves through implementation |
| Plan | Plan | Phases, iterations, QGRs | Updated after every commit |
| Quality Gate Reports | QGR | Three tables + summary | Standalone receipt + appended to Plan |
| Reference | Ref | Final documentation | Produced at plan completion |

### File Organization

Agent sandboxes live in `usr/{principal}/{agent}/`. Shared workstream content lives in `claude/workstreams/{workstream}/`.

```
usr/{principal}/{agent}/          — agent sandbox (slim)
  tmp/                            — scratch space (gitignored)
  tools/                          — agent scripts and ad hoc automation
  history/                        — archived handoffs and artifacts
    flotsam/                      — discarded drafts and experiments

agency/workstreams/{workstream}/  — shared workstream content
  qgr/                            — quality gate reports and review dispatches
  rgr/                            — release gate reports
  drafts/                         — work-in-progress documents
  research/                       — MARFI research output
  transcripts/                    — discussion records
  history/                        — archived workstream artifacts
```

- **Agent sandboxes are slim** — only tmp/, tools/, history/, history/flotsam/.
- **Shared content lives in workstreams** — QGRs, research, transcripts, drafts.
- **Code** stays in `tools/`, `scripts/`, `source/` — not in sandbox dirs.

### Valueflow Stream Model

Work moves through three streams, each with its own gate:

| Stream | What | Gates | Receipt |
|--------|------|-------|---------|
| **Work stream** | Agent commits — iteration and phase work | `/iteration-complete` (auto), `/phase-complete` (approval) | QGR (Quality Gate Report) via `receipt-sign` |
| **Delivery stream** | PRs and releases — shipping to origin | `/release`, `pr-create` | QGR required by `/git-safe-commit` before push |
| **Value stream** | Builds and deployments — production value | `/deploy` | Deployment receipt |

Each gate produces a **receipt**: the QGR for code gates, methodology artifact receipts for non-code gates. `/git-safe-commit` verifies a receipt exists (stage-hash match) before allowing a commit. `pr-create` verifies receipt before push. Gates are mechanical — they check for receipt existence, not receipt quality (human judgment stays where it belongs: principal approval at phase boundaries).

---

### Living Documents

Three documents evolve together:

1. **Product Vision & Requirements (PVR)** — what we need and why.
2. **Architecture & Design (A&D)** — the technical decisions, naming conventions, system structure. Includes design decisions (DD-N).
3. **Plan** — what we're doing, phase by phase. Includes quality gate reports as receipts.

The flow: **Requirements -> A&D + Plan (evolving together) -> Reference**

All three are living documents during active work. Update architecture decisions as you learn — don't wait until the end.
