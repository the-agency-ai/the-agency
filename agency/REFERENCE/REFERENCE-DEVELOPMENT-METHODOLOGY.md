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

Agent sandboxes live in `usr/{principal}/{agent}/`. Shared workstream content lives in `agency/workstreams/{workstream}/`.

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

---

## Branch Naming — D-counter and Rename Methodology

### D-counter (principal-PR-days)

Branch names that reference a "D" counter (e.g., `release/D45-R1`, `release/D45-R3`) use **principal-PR-days**, not workdays and not calendar days.

**Definition:** `D = count of distinct dates on which the principal has opened a PR to this repo`, counted from the principal's first PR onward. "D45" = the 45th day on which Jordan opened a PR to `the-agency-ai/the-agency`.

**Why this definition:**
- Calendar days punish weekends / vacations / multi-repo work.
- Workdays require timesheet-level bookkeeping and don't reflect actual contribution.
- Principal-PR-days are self-counting (GitHub already knows) and reflect *engagement* — the signal we actually care about.

**How to compute (approximate):**
```bash
gh pr list --state all --author <gh-username> --repo the-agency-ai/the-agency \
  --json createdAt --limit 1000 | jq '[.[].createdAt[0:10]] | unique | length'
```

Use the unique-date count as D for branches created today. Do **not** rename historical branches to "correct" a prior miscount — historical names are fixed. Going forward, branches use the PR-day count.

**Future tool (flagged):** `agency/tools/day-count` that emits the current D for a given principal + repo. Not yet built; compute manually via the `gh` + `jq` one-liner above until the tool lands.

### The Great Rename — v1/v2/v3 Retirement Rule

A **Great Rename** is a structural rename that touches the entire framework (e.g., `claude/` → `agency/`). During a Rename, every tool that matches the search pattern is re-located or re-classified. This is the natural moment to apply the v1/v2/v3 retirement rule:

**Rule:** When the NEXT version of a tool / pattern / convention is already being built, the CURRENT version is dead. Don't migrate v1 during a structural Rename — retire it. Aggressive deprecation is the right posture.

**Three patterns used during the 2026-04-21 monofolk Phase 1 Rename (see #398):**

| Pattern | What | Example | Decision |
|---|---|---|---|
| **A — Retire duplicate aliases** | Multiple files with identical content | `hello`, `hi`, `welcomeback` (three copies of session-start prompt) | Kill all three. Cleanup is easier during Rename than after. |
| **B — Retire dead v1 tools** | Tool tracked for replacement, v2/v3 being built | `myclaude` (Agency-1.0 launcher; v2 launcher in progress) | "Kill it. It's dead. V1 and we are on v2 and v3 is being built." |
| **C — Reclassify on workflow-alignment** | Initially mis-classified by captain | `nit-add`, `findings-consolidate` (proposed framework-dev, actually customer runtime during QG) | Reclassify via 1B1 review. |

**Classification cascade for Rename events:**

1. **Classify against upstream authoritative placement** — for every tool that also exists upstream, copy upstream's classification. Mechanical.
2. **Captain-propose classification for unique tools** — for tools that exist downstream but not upstream, propose `customer` (appears in adopter workflows), `framework-dev` (QG/review/provisioning), or `captain-personal` (principal sandbox).
3. **Principal 1B1 ratification** — principal reviews captain's proposals. Exercises Patterns A/B/C. The critical step.

**When a Rename is in flight, roll unrelated cleanup into it.** You are already touching every file; the marginal cost of retiring aliases + dead v1 tools is near zero, and the cleanup-debt saved is real.

---

## Naming Convention — Noun-Verb for Skills, Tools, Commands

Framework convention: **noun-verb**, not verb-noun.

| Noun-verb (correct) | Verb-noun (wrong) | Why noun-verb wins |
|---|---|---|
| `git-safe` | `safe-git` | Groups all `git-*` tools under one autocomplete prefix |
| `agent-create` | `create-agent` | `/agent` tab-completes to find every agent-related skill |
| `session-end` | `end-session` | `/session` surfaces every session-lifecycle skill |
| `dispatch-create` | `create-dispatch` | All dispatch ops under one prefix |
| `worktree-sync` | `sync-worktree` | Discoverability — `/worktree` tab-completes |

### Rationale

**Discoverability.** When an agent types `/session`, autocomplete surfaces every session-related skill. When a skill is named `end-session`, it only appears under `/end` — which is a useless prefix that clusters with `/end-game`, `/end-call`, etc. Verb-first naming fragments discovery.

**Grouping.** Every `git-*` tool relates to git. Every `session-*` skill relates to the session lifecycle. Nouns are the stable organizing axis; verbs are interchangeable actions on a noun.

**Mental model.** Agents think "I want to do X with Y" — the noun (Y) comes first in the search, the verb (X) last. `git-safe`, `git-push`, `git-captain` — pick the git tool, then the action.

### Known violators (as of 2026-04-22)

Framework (**rename candidates**):
- `update-config` — Claude Code bundled skill (`~/.claude/skills/update-config/`). Framework inherits; we can override locally to `config-update`. Flagged for captain 1B1 — requires a local override shim + a decision on whether to fork the upstream skill.
- `.claude/commands/*` — seven commands (see #290 cleanup); structurally parallel to skills. Decision needed on whether commands are being retired or migrated.

Framework (**reviewed, acceptable**):
- `run-in` — "in" is a preposition, not a verb-prefix; `run` is the noun (the command being run) rather than the verb.
- `post-merge`, `pre-phase-review`, `review-pr` — `post-merge` and `pre-phase-review` are temporal scopes (pre/post are adverbs); `review-pr` is a legacy skill slated for renaming to `pr-review` when the pr-* family stabilizes (see #357 follow-up).
- `sync-all` — legacy captain-sync; captain-sync-all is the v2 replacement. Retirement tracked under v2 rename (#398 pattern B).

### Enforcement path (proposed, not yet landed)

1. **`skill-create` tool check** — refuse to scaffold if proposed name matches `^(update|create|delete|install|remove|build|deploy|run|start|stop|add|get|set)-`. Mechanical block at creation time.
2. **Hookify warn rule** — `hookify.skill-naming-noun-verb-warn.md` — inspect `skill_name` param on Skill tool invocation; warn on verb-prefix match. Blocks silent adoption of new violators.
3. **Audit cadence** — run the violator check at each Rename event (v2 → v3 etc.). Retire or rename in batch.

See #357 for the current state of this enforcement work.
