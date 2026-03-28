# Agency Development Instructions

These instructions apply to all agents working in this repository. They encode the AIADLC methodology — opinionated conventions that are hard to change by design.

## The Work Pattern

Discuss -> Plan Mode (explore + design) -> Review Plan -> Revise -> Review -> Finalize -> Implement. This is how we do things. "Plan Mode" is Claude Code's planning feature — read-only exploration and design before writing code.

## Quality Gate (QG)

Quality gates (QGs) run at every commit boundary. The PM agent (`project-manager`) owns the full protocol — see `claude/docs/QUALITY-GATE.md` for the complete steps and report format. Use `/iteration-complete` at iteration boundaries (scoped QG, auto-commit), `/phase-complete` at phase boundaries (deep QG, full codebase, approval required), `/plan-complete` at project completion. Run `/pre-phase-review` before starting each new phase.

## Development Methodology

### The Flow

```
Seed -> Discussion -> PVR [Product Vision & Requirements] (evolving) -> A&D [Architecture & Design] (evolving) -> Plan (phases x iterations)
```

1. **Seed** — a starting point from elsewhere (document, idea, spec). Launches the discussion.
2. **Discussion** — using the 1B1 (one-by-one) protocol. Explore requirements, constraints, trade-offs. No jumping to implementation.
3. **Product Vision & Requirements (PVR)** — the what and why. Evolves through implementation.
4. **Architecture & Design (A&D)** — the how and why. Technical decisions, patterns, system design.
5. **Plan** — phases comprised of iterations. Updated after every commit.

### Execution

- **Phases** are whole numbers: Phase 1, Phase 2, Phase 3.
- **Iterations** are Phase.Iteration: 1.1, 1.2, 2.1. No letters — only numbers.
- **Every phase and iteration carries a slug** (e.g., "Phase 2: Provider Abstraction"). Renumber freely — the slug is the stable identifier.
- Commit at iteration boundaries (`/iteration-complete`), phase boundaries (`/phase-complete`).
- Run `/pre-phase-review` before starting the next phase.

### Artifacts

| Artifact | Abbrev | Content | Lifecycle |
|----------|--------|---------|-----------|
| Product Vision & Requirements | PVR | What and why | Evolves through discussion + implementation |
| Architecture & Design | A&D | How and why (technical decisions) | Evolves through implementation |
| Plan | Plan | Phases, iterations, QGRs | Updated after every commit |
| Quality Gate Reports | QGR | Tables + summary | Appended to Plan |
| Reference | Ref | Final documentation | Produced at plan completion |

### Living Documents

PVR, A&D, and Plan evolve together during active work. The flow: **Requirements -> A&D + Plan (evolving together through iteration) -> Reference.** Update architecture decisions as you learn — don't wait until the end.

## Discussion Protocol (1B1)

Follow the 1B1 (one-by-one) protocol. When the user presents multiple items:

- **Break the list into discrete threads.** Address each item one at a time, not all at once.
- **Resolve each item before moving to the next.** Don't mix concerns across items.
- **Number the items explicitly** so the user can reference them by number.
- **Capture decisions as they're made** — don't wait until the end to summarize.

The inner loop per item: Present -> Get Feedback -> Confirm Understanding (reflective listening) -> Revise -> Iterate -> Resolve -> Confirm Resolution -> Next Item.

## Bash Tool Usage

Run each shell command as a **single, simple command** — no `&&`, `||`, `;`, pipes, subshells, or `$(...)` substitutions. Use separate Bash tool calls (parallel when independent, sequential when dependent). Use dedicated tools: Grep not grep, Glob not find, Read not cat, Write not echo, Edit not sed.

## Testing & Quality

**We fix things. We don't work around them. There are no small bugs — just fix it.**

- No unactionable noise — every warning triggers action or gets fixed at the source.
- Fix what you find — don't defer nits. The cost now is low.
- No silent failures — fail loudly or handle explicitly.
- Verify, don't assume — read the docs, check the data, debug with evidence.
- Enforce conventions mechanically — hooks and rules, not prose.
- No stale artifacts — dead code, unused config, orphaned files — delete or update them.

## Git & Remote Discipline

- **Remote master is read-only.** All changes reach remote through PRs. The captain creates PRs.
- **Never push to any remote without explicit permission.** Pushing is always deliberate.
- **Post-merge sync is automatic.** `/sync-all` detects and handles divergence.
- **Lead commit messages with Phase-Iteration slug.** Format: `Phase 1.3: feat: summary`.
- **Fix, don't ask.** When you find bugs or quality problems, fix them. Findings are the work order.
- **Read, don't guess.** Read actual documentation before guessing at APIs, flags, or schemas.

## Code Review

The captain manages code review dispatch via `/captain-review`. Worktree agents handle dispatched findings via `/iteration-complete`. Three review tools serve different purposes: `/code-review` (captain, 7-agent), `/review-pr` (ad-hoc), `/phase-complete` (deep QG with fix cycle). If you receive a dispatch, evaluate findings, fix valid issues with red-green proof, dispute with reasoning.

## Session Handoff

Handoff files live at `usr/{principal}/{project}/handoff.md`. Mostly mechanically generated (git state + plan state + session state), agent adds context and color. Written at boundary commands, PreCompact, and SessionEnd. Hooks handle injection on session start.

## File Organization

Each principal (human or team member) has their own directory under `usr/`. All your project work lives in `usr/<your-username>/{project}/`.

```
usr/<your-username>/
  claude/              — Claude Code config (CLAUDE.md, commands, hookify, hooks)
  scripts/             — cross-cutting scripts
  {project}/           — one directory per project
    handoff.md         — current session handoff
    {project}-pvr-YYYYMMDD.md
    {project}-architecture-YYYYMMDD.md
    {project}-plan-YYYYMMDD.md
    transcripts/       — discussion records
    code-reviews/      — captain review and dispatch files
    history/           — archived artifacts
```

## Sandbox Principle

**Everything sandboxed. Zero impact to the team. Completely opt-in.**

- All personal work lives in `usr/<your-username>/`
- Nothing forces changes on other team members
- Symlinks activate sandbox items — local, never committed
