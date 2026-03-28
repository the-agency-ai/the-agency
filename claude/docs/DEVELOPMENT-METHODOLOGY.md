## Development Methodology

This is how we develop. Not a suggestion — the process.

### The Flow

```
Seed -> Discussion -> PVR (evolving) -> A&D (evolving) -> Plan (phases x iterations)
```

1. **Seed** — the principal brings a starting point. Could be a document from elsewhere, a rough idea, a detailed spec. It launches the discussion.
2. **Discussion** — using the Discussion Protocol (1B1). Explore requirements, constraints, trade-offs. No jumping to implementation.
3. **Product Vision & Requirements (PVR)** — incrementally built during discussion. The _what_ and _why_. Evolves through implementation as we learn.
4. **Architecture & Design (A&D)** — incrementally built alongside the PVR. The _how_ and _why_. Technical decisions, patterns, system design. Evolves through implementation.
5. **Plan** — breaks implementation into Phases comprised of Iterations. Created after PVR and A&D have enough shape. Updated after every commit.

### Execution

- **Phases** are numbered with whole numbers: Phase 1, Phase 2, Phase 3.
- **Iterations** are Phase.Iteration: 1.1, 1.2, 2.1, 2.2. Read `1.1` as "Phase 1, Iteration 1". Read `2.3` as "Phase 2, Iteration 3".
- **No letters** — no 1a, 1b. Only numbers.
- **Every phase and iteration carries a slug** (e.g., "Phase 2: Provider Abstraction") because renumbering happens when phases or iterations are added.
- **Renumber freely.** If we insert Phase 3 between old Phase 2 and 3, renumber everything. The slug is the stable identifier.
- **Commit at iteration boundaries.** Auto-commit after clean QGR. No approval needed.
- **Commit at phase boundaries.** Squash, deep QG, Sprint Review, land on master.
- **Pre-phase review** before starting the next phase.

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
6. After approval, land on master:
   a. Verify clean: `git status` shows nothing to commit
   b. Merge master into branch: `git merge master`
   c. Push branch to local master: `git push . HEAD:master`
   d. Reset to master: `git reset --hard master`
   e. Verify: `git log --oneline -3` should show your commit on master
   f. Notify the captain session that new work has landed on master.
7. **Flag conditions** — stop and report to principal if:
   - `git push . HEAD:master` fails (non-fast-forward after merge)
   - Branch is dirty at merge time
   - Merge brings in work that breaks tests
   - Race condition with other agents updating master

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

| Artifact                      | Abbreviation | Content                           | Lifecycle                                   |
| ----------------------------- | ------------ | --------------------------------- | ------------------------------------------- |
| Product Vision & Requirements | PVR          | What and why                      | Evolves through discussion + implementation |
| Architecture & Design         | A&D          | How and why (technical decisions) | Evolves through implementation              |
| Plan                          | Plan         | Phases, iterations, QGRs          | Updated after every commit                  |
| Quality Gate Reports          | QGR          | Three tables + summary            | Appended to Plan                            |
| Reference                     | Ref          | Final documentation               | Produced at plan completion                 |

### File Organization

All project work lives in `usr/{principal}/{project}/`. Each project gets its own directory.

```
usr/{principal}/
  claude/              — Claude Code config (CLAUDE.md, commands, hookify, hooks, agents, refs)
  scripts/             — cross-cutting scripts
  {project}/           — one directory per project
    handoff.md                          — current session handoff
    {project}-seed-YYYYMMDD.md          — the starting context (optional)
    {project}-pvr-YYYYMMDD.md           — Product Vision & Requirements
    {project}-architecture-YYYYMMDD.md  — Architecture & Design
    {project}-plan-YYYYMMDD.md          — The Plan
    transcripts/                        — discussion records
    code-reviews/                       — captain review and dispatch files
    history/                            — archived artifacts
```

- **One plan per project.** Date stamp bumps only on a new day.
- **No nesting** — `usr/{principal}/folio/`, not `usr/{principal}/docs/projects/folio/`.
- **Code** stays in `tools/`, `scripts/`, `source/` — not in sandbox project dirs.

### Living Documents

Three documents evolve together:

1. **Product Vision & Requirements (PVR)** — what we need and why.
2. **Architecture & Design (A&D)** — the technical decisions, naming conventions, system structure. Includes design decisions (DD-N).
3. **Plan** — what we're doing, phase by phase. Includes quality gate reports as receipts.

The flow: **Requirements -> A&D + Plan (evolving together) -> Reference**

All three are living documents during active work. Update architecture decisions as you learn — don't wait until the end.
