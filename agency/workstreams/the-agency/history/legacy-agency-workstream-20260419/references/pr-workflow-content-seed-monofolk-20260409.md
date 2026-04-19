---
type: reference
source: monofolk/jordan/captain
captured: 2026-04-09
captured_by: the-agency/jordan/captain
workstream: agency
purpose: content seed for articles, books, workshops — AIADLC PR workflow for multi-agent development
---

# PR Workflow Design for Multi-Agent Development

Captured from monofolk/jordan/captain (dispatch 2026-04-09T11:41). Companion piece to our own PR workflow writeup dispatch (`dispatch-pr-packing-workflow--my-understanding--f-20260409.md`) which arrived simultaneously from our side and reached the same pattern independently.

## Context

monofolk runs 15 agents across 15 worktrees, all landing work on local master. Captain packages work into PRs for origin. The question: how should PRs be structured when the work is produced by AI agents, not humans?

## Key Decisions

### 1. No Squash — Preserve Every Commit

Standard PR practice (squash-and-merge) optimizes for human reviewers who want a clean, scannable history. But in AIADLC with agent-produced work, squashing destroys value:

**Why squash hurts agents:**

- Agent commit history IS the audit trail. Each commit marks an iteration boundary, a QG pass, a fix cycle. The phase/iteration slugs in commit messages (`Phase 1.2: feat: auth service`) are the agent's memory across sessions.
- Squashing turns "Phase 1.1: scaffold, Phase 1.2: auth, Phase 1.3: tests, fix: reviewer-code finding #3" into one opaque blob. The next agent that reads the history loses the ability to understand what happened and why.
- Provenance headers in code reference "Written: 2026-04-04 during captain session 18" — the commit history is what makes those traceable.

**Why squash hurts debugging:**

- `git bisect` is the only sane way to find regressions in a codebase with 15 agents producing hundreds of commits.
- With individual commits, bisect pinpoints which specific iteration introduced a problem.
- With squash, you know "something in this 45-commit blob broke it" — useless.
- For a team where both humans AND agents contribute, bisect across both is essential.

**The insight:** Squash optimizes for human readability of history. Preserving commits optimizes for agent continuity and mechanical debugging. In AIADLC, the latter matters more. Humans can still read PR descriptions for the summary — they don't need squashed history for that.

### 2. Day-Release Naming Convention

Branch and PR naming: `jordan-{agent}-D{day}-R{release}`

- **Day** counts from the principal's first PR to origin. Only increments on days a PR is made. No PR, no increment.
- **Release** increments per principal (not per agent) within a day. This tracks the human's review bandwidth, not the agent's output.
- Example: `jordan-captain-D6-R1`, `jordan-devex-D6-R2` — Jordan reviewed two PRs on Day 6.

**Why per-principal R, not per-agent?** The R number answers "how many things did the principal review today?" If each agent had its own R counter, `jordan-captain-D6-R1` and `jordan-devex-D6-R1` both say "first release" — confusing. Did the principal review one thing or two? Per-principal R gives a global sequence across all agents in one day.

**Multi-principal extension:** Peter uses `peter-{agent}-D{day}-R{release}` with his own day counter. Day 1 is Peter's first PR. This scales to any number of principals without collision.

**Important correction vs captain's earlier assumption:** D is not a workday-from-start counter. It is a PR-shipped-day counter. If a principal skipped shipping on a day, D does not advance.

### 3. 1:1 Workstream-to-PR Mapping

Each workstream gets exactly one PR. Not one giant PR for everything, not micro-PRs per iteration. The workstream IS the unit of review.

- Captain/framework work on master is one PR
- Each worktree agent's work is another PR
- Up to 15 PRs for a full fleet push

### 4. Captain Builds PRs, Not Agents

Agents work on their worktrees. They don't build PRs, don't push to origin, don't create GitHub artifacts. The captain:

1. Ensures local master is in sync with origin
2. Packages each workstream's commits into a PR branch (merge, not squash)
3. Runs full QG + MAR on each PR branch
4. Fixes issues found (test-first: write the test, then fix the bug)
5. Dispatches to the workstream agent explaining what was fixed and how they could have avoided it
6. Reviews with the principal
7. Pushes and creates the PR (with principal approval)

**The dispatch-back pattern:** When captain finds and fixes an issue during PR review, the fix goes into the PR but the LEARNING goes back to the agent via dispatch. "Here's what I found, here's the QGR, here's how you could have caught it." This creates a feedback loop — agents improve over time because they see their own mistakes reflected back in the context they understand (their workstream, their code, their patterns).

### 5. Framework / Captain PR Goes First

Captain work (workstream directories, agent registrations, tools, hookify rules, settings) is the foundation. It must merge to origin before workstream PRs, because workstream code depends on framework infrastructure. This mirrors the dependency graph: framework enables agents, agents produce work, captain packages work.

### 6. The PR Description

Not just "what changed" but:

- What the workstream is and what it does
- Pointers to PVR, A&D, Plan documents in the repo
- What phases/iterations are included
- Test coverage and QG results
- Known limitations or deferred items
- All individual commits preserved (no squash) — the description is the human-readable summary, the commits are the machine-readable history

## Workshop / Curriculum Material

This is a complete worked example of:

1. How AIADLC handles the "last mile" — getting agent work into production via PRs
2. Why standard git practices (squash, rebase) need rethinking for AI-augmented development
3. How naming conventions encode organizational structure (principal, agent, day, release)
4. How quality feedback flows back to agents (dispatch-on-fix pattern)
5. The captain pattern — coordination without code production
6. Why merge-not-rebase matters in multi-agent environments

## Cross-references

- Our own PR workflow writeup: `dispatches/the-agency-to-monofolk/dispatch-pr-packing-workflow--my-understanding--f-20260409.md`
- merge-not-rebase reference: `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md`
- telemetry-driven tool discovery seed: `claude/workstreams/agency/seeds/seed-telemetry-driven-tool-discovery-20260409.md`
- Gary Tan durable agents reference: `claude/workstreams/agency/references/gary-tan-durable-agents-20260409.md`

## Article / book positioning

This material pairs naturally with the telemetry-driven tool discovery insight and the Gary Tan durable agents reference. Together they form the backbone of three articles or chapters:

1. **"What AI development gets wrong about git"** — why squash, rebase, and single-commit PRs don't survive contact with multi-agent work. Uses the bisect argument, the agent-continuity argument, and the provenance-header argument.
2. **"The captain pattern: coordination without code production"** — the meta-role that emerges when you have a fleet of agents shipping work. Uses the PR-packing, QG-review, dispatch-back loop as the worked example.
3. **"The framework that builds itself"** — telemetry-driven tool discovery + Gary Tan's durable agents + the PR workflow as the three pillars of a framework that evolves through its own friction data.
