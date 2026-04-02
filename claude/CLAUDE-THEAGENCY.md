# AIADLC Project Instructions (TheAgency)

These instructions establish TheAgency methodology for this project and apply to all agents and principals working in this repository. For background on TheAgency, see `claude/README-THEAGENCY.md`.

This file is imported via `@claude/CLAUDE-THEAGENCY.md` from the project's root `CLAUDE.md`. See `claude/README-THEAGENCY.md` for setup details.

## TheAgency Repo Structure

TheAgency lives under `claude/` — a single namespace alongside your project's directories. Everything Agency-related is here.

```
claude/
  CLAUDE-THEAGENCY.md    — this file (Agency methodology, imported by root CLAUDE.md)
  README-THEAGENCY.md    — orientation for humans
  README-GETTINGSTARTED.md — onboarding guide
  config/
    agency.yaml          — project-specific Agency config
    manifest.json        — tracks installed files and versions
    settings-template.json — canonical permissions/hooks template
  agents/                — agent CLASS definitions
    {class}/agent.md     — role, responsibilities, model, tools
  docs/                  — reference docs (injected on demand by hooks)
    QUALITY-GATE.md      — QGR format, protocol, commit message spec
    FEEDBACK-FORMAT.md   — bug report / feature request template
    CODE-REVIEW-LIFECYCLE.md — dispatch handling protocol
    DEVELOPMENT-METHODOLOGY.md — full Seed→Reference lifecycle
  hooks/                 — session hooks (ref-injector, tool-telemetry, session-handoff)
  hookify/               — shipped behavioral rules
  tools/                 — all tools (bash, python, rust, compiled)
    lib/                 — tool libraries (_log-helper, _path-resolve, etc.)
    handoff              — context bootstrap (read/write/archive)
    stage-hash           — deterministic staging area hash
    git-commit           — QG-aware commit wrapper
    settings-merge       — merge settings template into current settings
  templates/             — scaffolding templates
  usr/                   — agent INSTANCES (per-principal sandboxes)
    {principal}/
      {project}/         — one directory per project
        handoff.md       — current session state
        {project}-pvr-*.md — Product Vision & Requirements
        {project}-architecture-*.md — Architecture & Design
        {project}-plan-*.md — The Plan
        code-reviews/    — captain review and dispatch files
        dispatches/      — incoming dispatches
        transcripts/     — discussion transcripts
        history/         — archived handoffs and artifacts
  workstreams/           — bodies of work
    ops/                 — default workstream
  src/                   — --dev only (source code, tests)
.claude/                 — Claude Code discovery location
  commands/              — active skills (symlinks from claude/usr/ + shared)
  skills/                — skill definitions
  settings.json          — Claude Code settings (scaffold — never overwritten by updates)
  hookify.*.local.md     — active hookify rules (symlinks)
```

Your project's own directories (`apps/`, `packages/`, `docs/`, `scripts/`, etc.) are documented in the project-specific section of this CLAUDE.md.

- **One plan per project.** Date stamp bumps only on a new day. Same file all day.
- **No nesting** — `claude/usr/{{principal}}/folio/`, not `claude/usr/{{principal}}/docs/projects/folio/`.
- **Code** stays in project directories (`apps/`, `src/`, etc.) — not in sandbox project dirs.

## Quality Gate (QG) Protocol

Quality gates run at every commit boundary — iteration, phase, plan completion, and pre-PR. The gate applies to any artifact type (code, commands, config, docs). The project-manager agent runs the full protocol; the `/quality-gate` skill orchestrates the 8-stage process (parallel multi-agent review, consolidate, bug-exposing tests, fix, coverage tests, confirm clean). The QGR format and protocol detail are in `claude/docs/QUALITY-GATE.md` — injected automatically when QG skills run.

**The rules:**

- Failing row in the QGR MUST be 0. No exceptions. Pre-existing failures are your problem too.
- Red-green cycle for every bug-exposing test. No valid test = no valid fix.
- Never skip review agents — even for "small" or "trivial" changes. The audit always finds something.
- Fix every finding. Every valid finding gets fixed — no "Won't Fix," no "Deferred," no severity-based skip. Severity orders the fix sequence, never the fix decision. Reject invalid findings with reasoning.
- Always use `/git-commit` — never raw `git commit`. It verifies a QGR receipt exists for the staged changes.

**Boundary skills** (invoke these, never commit manually):

| Boundary | Skill | QG Scope | Approval |
|----------|-------|----------|----------|
| Iteration end | `/iteration-complete` | Changes since last commit | Auto-commit |
| Phase end | `/phase-complete` | Full codebase (deep QG) | Principal required |
| Plan end | `/plan-complete` | Full codebase | Principal required |
| Pre-PR | `/pr-prep` | Full diff vs origin/master | — |
| Pre-phase | `/pre-phase-review` | PVR + A&D + Plan review | Principal required |

**QGR receipt files:** Each gate produces a standalone receipt at `claude/usr/{{principal}}/{project}/qgr-{boundary}-{phase-iter}-{stage-hash}-YYYYMMDD-HHMM.md`. The stage hash is a deterministic hash of the staged changes (computed by `claude/tools/stage-hash`). `/git-commit` checks for a matching receipt before committing — no receipt means no QG was run.

**After every commit:** Update the plan file with iteration/phase status, QG findings, and append the full QGR. The plan is the living record. The QGR receipt file is committed alongside the work as the permanent audit trail.

## Development Methodology

This is how we develop. Not a suggestion — the process.

### The Flow

```
Seed → Discussion → PVR (evolving) → A&D (evolving) → Plan (phases × iterations)
```

1. **Seed** — a starting point from elsewhere (document, idea, spec). Launches the discussion.
2. **Discussion** — using the Discussion Protocol (`/discuss`). Explore requirements, constraints, trade-offs. No jumping to implementation.
3. **Product Vision & Requirements (PVR)** — the _what_ and _why_. Built during discussion, evolves through implementation. Use `/define` to drive toward completeness.
4. **Architecture & Design (A&D)** — the _how_ and _why_. Technical decisions, patterns, system design. Use `/design` to drive toward completeness. Evolves through implementation.
5. **Plan** — Phases comprised of Iterations. Created after PVR and A&D have enough shape. Updated after every commit.

Three living documents (PVR, A&D, Plan) evolve together. The flow: **Requirements → A&D + Plan (evolving through iteration) → Reference** (produced at plan completion).

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

### Artifacts

| Artifact | Abbrev | Content | Lifecycle |
|----------|--------|---------|-----------|
| Product Vision & Requirements | PVR | What and why | Evolves through discussion + implementation |
| Architecture & Design | A&D | How and why (technical decisions) | Evolves through implementation |
| Plan | Plan | Phases, iterations, QGRs | Updated after every commit |
| Quality Gate Reports | QGR | Three tables + summary | Standalone receipt + appended to Plan |
| Reference | Ref | Final documentation | Produced at plan completion |

### File Organization

Project artifacts live in `claude/usr/{{principal}}/{project}/` — see the Repo Structure section above for the full directory tree and naming conventions.

## Worktrees & Master

Agents work either on **master** (the main checkout) or on a **worktree** (an isolated branch). Know which you are and follow the rules for each.

### Master (Captain)

The captain session runs on master. It coordinates — syncs worktrees, builds PR branches, dispatches reviews, pushes to origin. The captain does not implement features.

- `/sync-all` — merges worktree work into master, syncs all worktrees. Purely local, never pushes.
- `/sync` — the only command that pushes. Explicit confirmation required.
- `/captain-review` — reviews PR branches locally, dispatches findings.
- Direct commits to master are only for coordination artifacts (handoffs, dispatches, review files).

### Worktrees (Feature Agents)

Worktree agents implement features on isolated branches. They build, test, and land on master via boundary commands.

- Work on your branch. Commit at iteration boundaries via `/iteration-complete`.
- Land on master at phase boundaries via `/phase-complete` (squash, deep QG, approval, push to local master).
- Merge master regularly (`git merge master`) to pick up dispatches, CLAUDE.md updates, and other agents' work.
- Never push to origin directly — the captain manages PR branches and pushes.

### When to Create a Worktree

- **New prototype or feature** — always a worktree. Use `/workstream-create` or `/prototype-create`.
- **Bug fix or small change** — can work on master if it's a quick fix that doesn't need isolation.
- **Dispatch handling** — worktree agent picks up the dispatch after merging master.

## Session Handoff

Handoff files are a first-class Agency primitive for context bootstrapping. They live at `claude/usr/{{principal}}/{project}/handoff.md`, are version controlled, and auto-rotate (each write archives the previous to `history/` with timestamp via `claude/tools/handoff`).

Handoffs are not just session continuity — they bootstrap context for any purpose: agent-to-agent transfer, cold start, project setup, compaction survival, or spinning up a new agent into a desired state. The tool handles infrastructure; the agent writes the content.

**Always use the handoff tool.** Run `bash $CLAUDE_PROJECT_DIR/claude/tools/handoff write --trigger <reason>` to write handoffs. The tool archives the previous handoff to `history/` with a timestamp, resolves the correct path for your project, and ensures consistent formatting. Never write handoff files manually — always use the tool. The `SessionEnd` and `PreCompact` hooks call it automatically, but agents must also call it explicitly at boundary commands and discussion milestones.

**When to write:** At boundary commands (`/iteration-complete`, `/phase-complete`, `/plan-complete`, `/pre-phase-review`), automatically on `PreCompact` and `SessionEnd` hooks, after `/sync-all` (lightweight), and at discussion milestones (PVR draft, key A&D decision, plan revision).

**What to include:** Current phase/iteration status, what was just done, what's next, key decisions or context for a fresh session, open items or blockers.

## Discussion Protocol (1B1)

All multi-item discussions use the 1B1 (one-by-one) protocol via `/discuss`. One item at a time. Resolve before moving on. No exceptions.

- **Break the list into discrete threads.** Address each item one at a time, not all at once.
- **Resolve each item before moving to the next.** Don't mix concerns across items.
- **Number the items explicitly** so the user can reference them by number.
- **Capture decisions as they're made** — don't wait until the end to summarize.

The full 8-step resolution cycle (Present → Feedback → Confirm Understanding → Revise → Iterate → Resolve → Confirm Resolution → Next) is in the `/discuss` skill. `/discuss` auto-starts a `/transcript` for record-keeping.

## Feedback & Bug Reports (Claude Code)

When drafting feedback or bug reports **for Anthropic / Claude Code** (via `/feedback` or GitHub issues), always include the identity block (`{{principal_name}}`, `{{principal_github}}`, `{{principal_email}}`), show diagnostic evidence (not theories), and reference related issues. The full format is in `claude/docs/FEEDBACK-FORMAT.md` — injected automatically when feedback skills run.

**Draft it, then wait for approval.** Never send feedback without the principal reviewing it first.

## Testing & Quality Discipline

**We fix things. We don't work around them. There are no small bugs — just fix it.**

- **Fix what you find** — don't defer nits. Dead code, stale config, broken patterns — fix in the same pass.
- **No silent failures** — fail loudly or handle explicitly. If you suppress an error, comment why.
- **No unactionable noise** — every warning must trigger action or get fixed at the source.
- **Verify, don't assume** — read the docs, check the data, debug with evidence. Don't cargo-cult patterns.
- **Enforce conventions mechanically** — hooks and rules, not prose. Prose gets forgotten.

### The Enforcement Triangle

Every capability follows the same three-part pattern:

| Layer | What | Why |
|-------|------|-----|
| **Tool** (bash, `claude/tools/`) | Does the work. Pre-approved in `settings.json`. | Permissions. No prompts for approved operations. |
| **Skill** (markdown, `.claude/commands/` or `.claude/skills/`) | Tells the agent when and how to use the tool. | Discovery. Agents find it via `/` autocomplete. |
| **Hookify rule** (`claude/hookify/`) | Blocks the raw alternative. Points to the skill. | Compliance. Can't bypass. |

When building a new capability: build the tool, wrap it in a skill, block the raw alternative with a hookify rule. All three. Not one, not two. The tool handles permissions, the skill handles discovery, the hookify rule handles compliance. *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

- **No stale artifacts** — unused config, orphaned files, outdated docs — delete or update. Version control remembers.

**When something fails:**

- **The blocker IS the work.** Do not skip, disable, or work around failing tests, hooks, or checks.
- **Never propose `--no-verify`, `eslint-disable`, `@ts-ignore`, or "fix later."** Find and fix the underlying issue.
- **Fix flakes.** Diagnose non-determinism (timing, state leakage) and eliminate it.
- **Fix infrastructure.** Don't code around missing tools or broken paths — configure them correctly.
- **Re-read after lint/format.** Linters rewrite files. Your in-memory copy is stale after lint-staged runs.
- **Always read before write.** Never Edit or Write a file you haven't Read in this conversation.
- **Consult before acting on failures.** Diagnose first, propose a fix second, act only with approval.

## Bash Tool Usage

Run each shell command as a **single, simple command** — no `&&`, `||`, `;`, pipes, subshells, or `$(…)` substitutions. These bypass the allowed-tools list, triggering extra permission prompts. Use separate Bash tool calls (parallel when independent, sequential when dependent). Use dedicated tools: Grep not `grep`, Glob not `find`, Read not `cat`, Write not `echo`, `/git-commit` not `git commit`.

**Before writing bash, check if a tool already exists.** Tools in `claude/tools/` have built-in logging, telemetry, and structured output — they're more token-efficient and observable than inline bash. See `claude/README-THEAGENCY.md` for the full alternatives table and the tool ecosystem.

## Web Content Retrieval

Escalation ladder when fetching web content:

1. **WebFetch** — try first. Fast, no browser needed. Fails on JS-heavy sites.
2. **Playwright MCP snapshot** — JS-heavy sites. Structured accessibility tree, token-efficient.
3. **Playwright MCP screenshot** — when visual context is needed.
4. **Playwright MCP run_code** — extract specific content from large pages.

Extract what you need — don't dump whole pages into context. Summarize, don't paste raw HTML.

## Git & Remote Discipline

**Universal rules (all agents):**

- **Remote master is read-only.** All changes reach origin through PRs. Never push to origin/master.
- **Never push without explicit permission.** Pushing is always deliberate. Mechanically enforced by hookify rules (block master push, warn on any push).
- **Never `reset --hard` without confirming work is preserved.** A diverged branch may have new commits. Check first.
- **`/rebase` and `/sync-all` are purely local.** `/sync` is the only command that pushes.
- **Lead commit messages with Phase-Iteration slug.** Format: `Phase 1.3: feat: concise summary`. The slug is first, before the prefix.

**By role:**

| Action | Feature agent (worktree) | Captain (master) | PM (subagent) |
|--------|-------------------------|-----------------|---------------|
| Write application code | Yes | Never | Never |
| Commit | Via `/iteration-complete`, `/phase-complete` | Coordination artifacts only | Never directly |
| Push to origin | Never | Via `/sync`, with approval | Never |
| Create PRs | Never | Yes, via `gh pr create` | Never |
| Run QG | Invokes `/quality-gate` | Invokes `/code-review` | Runs the protocol |
| Merge master | `git merge master` to pick up updates | Owns master | N/A |
| Land on master | Via `/phase-complete` | Receives landed work | N/A |

## Local Setup / Sandbox

**Everything sandboxed. Zero impact to the team. Completely opt-in.**

Personal config lives in `claude/usr/{{principal}}/` — commands, hookify rules, hooks, settings. Activated by symlinking into `.claude/` — symlinks are gitignored, so activation is local.

- `/sandbox-activate` — symlink a sandbox item to the discovery location
- `/sandbox-try` — try another engineer's experiment
- `/sandbox-adopt` — graduate to shared team-wide tooling

### Hookify Rule Scoping

| Location | Scope | Git Status |
|----------|-------|------------|
| `claude/hookify/` | Framework (shipped rules) | Committed |
| `claude/usr/{{principal}}/claude/hookify/` | Sandbox (per-engineer) | Committed |
| `.claude/hookify.foo.local.md` | Active (symlinked from above) | Committed or gitignored |

### Hookify Rule Convention

All hookify rule messages — block, warn, or inform — must end with the enforcement trademark:

> *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

This is not optional. It is the project's standard error signature for rule violations. Include it when writing new hookify rules.

## Code Review & PR Lifecycle

Three review tools serve different purposes at different points. They do not replace each other.

| Tool | Who | When | Depth | Fix cycle? |
|------|-----|------|-------|------------|
| `/code-review` | Captain | After PR branch built | 7 agents + scoring, ≥80 confidence | No — dispatches |
| `/review-pr` | Human/agent | Ad-hoc, after PR exists | 1 agent, max 5 comments | No |
| `/phase-complete` | Worktree agent | Iteration/phase boundary | Deep QG, 4+ agents | Yes — red→green |

The captain manages the full PR lifecycle: `/sync-all` → rebuild PR branches → `/captain-review` → dispatch findings → worktree agents fix → rebuild → push → draft PR → human review → merge. Run `/pr-prep` before pushing a PR branch (full diff QG against origin/master). Reviews run **locally** before PRs are created. The full protocol is in the captain agent definition and `claude/docs/CODE-REVIEW-LIFECYCLE.md`.

**If you receive a dispatch:** Merge master, read the dispatch file at `claude/usr/{{principal}}/{project}/code-reviews/`, evaluate findings, fix with red→green cycle, append a resolution table, run `/iteration-complete`. The full dispatch handling protocol is in `claude/docs/CODE-REVIEW-LIFECYCLE.md` — injected when relevant skills run.

**Review files:** `claude/usr/{{principal}}/{project}/code-reviews/{project}-{review|dispatch}-YYYYMMDD-HHMM.md`. Committed to the repo as the audit trail.

---

*AND REMEMBER: OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
