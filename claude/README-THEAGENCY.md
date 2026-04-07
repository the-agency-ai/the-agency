# TheAgency

TheAgency is an AI-Augmented Development Lifecycle (AIADLC) framework — methodology, tooling, agent class definitions, and operational conventions for Claude Code development.

For a primer on the Claude Code platform concepts that TheAgency builds on (agents, skills, commands, hooks, events, MCP servers, settings), see the [Claude Code Concepts Primer](#claude-code-concepts-primer) at the end of this document.

## What is an AIADLC?

An AIADLC codifies how humans and AI agents collaborate to build software. It is the emerging equivalent of what Agile/Scrum was for human teams — but designed for a world where AI agents are developers and humans are principals.

TheAgency is one of several emerging AIADLC frameworks, alongside [gstack](https://github.com/garry-t/gstack) and [metaswarm](https://github.com/dsifry/metaswarm), that move beyond "AI assists developers" to **"AI agents are developers, humans are principals."**

## How TheAgency Differs

Traditional AIADLC (FAANG pattern): Design doc → senior review → subsystem planning → sprint → TDD → code review → staging. AI assists individual developers. Humans coordinate via meetings and Jira. 30% speed increase.

TheAgency: Multiple AI agents work in parallel as first-class developers. Agents coordinate via tools (handoffs, dispatches, context bootstrap). Humans set direction and approve at boundaries. Multiplicative throughput, not additive.

| Aspect | Traditional AIADLC | TheAgency |
|--------|-------------------|-----------|
| AI role | Assists one developer | Multiple agents are developers |
| Coordination | Human meetings, Jira | Agent tools (handoff, dispatch, sync) |
| Context | Google Docs, tickets | CLAUDE.md, handoffs, workstream seeds |
| Review | AI auto-comments on PRs | Multi-agent parallel review with scoring |
| Throughput | 30% faster | Parallel agents (multiplicative) |
| Quality | Human-gated | Mechanical quality gates at every boundary |

## What TheAgency Provides

### Methodology
- **Quality gates** — multi-agent parallel review (4+ specialized agents: code, security, design, test), red→green test cycle, QGR (Quality Gate Report) receipts at every commit boundary. The QGR is both the report format (3 tables + narrative) and a standalone receipt file tied to the exact staged content via a deterministic stage hash. `/git-commit` verifies a receipt exists before committing — no QG means no commit.
- **Development flow (Valueflow)** — Idea → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value. Living documents evolve through implementation; Reference produced at plan completion. Full description in the Valueflow section below.
- **Discussion protocol** — 1B1 (one-by-one) for structured decision-making. Resolve each item before moving to the next.
- **Commit discipline** — five boundary types (iteration-complete, phase-complete, plan-complete, pr-prep, pre-phase-review), never partial work, never raw `git commit`
- **Session handoff** — context bootstrap for any purpose (agent-to-agent, cold start, compaction survival)

### Tooling
- **Scaffold tools** — workstream-create, worktree-create, agent-define
- **Context tools** — handoff (read/write/archive), plan-capture
- **Observability** — tool-runs.jsonl, telemetry.jsonl, statusline
- **Review agents** — code-reviewer, security-reviewer, design-reviewer, test-reviewer, scorer

### Agent Definitions
- **Class/instance model** — `claude/agents/{class}/agent.md` defines roles; `usr/{principal}/{agent}/` is the working instance
- **Standard classes** — captain, tech-lead, marketing-lead, platform-specialist, researcher
- **Workstream model** — agents work on workstreams with shared artifacts (seeds, PVR, A&D, Plan)

### Operational Conventions
- **Sandbox principle** — per-principal workspace (`usr/{principal}/`), zero team impact, opt-in adoption
- **Git discipline** — remote master read-only, never push without permission, mechanical enforcement via hookify
- **Code review lifecycle** — three tools (/code-review, /review-pr, /phase-complete) for different purposes
- **Dispatch model** — narrow, broadcast communications between agents and workstreams

---

## Valueflow — The Development Lifecycle

Valueflow is TheAgency's methodology — the complete path from an idea to value that customers are using. It's rooted in Lean thinking: every step must demonstrably reduce rework or increase delivery probability. Steps that don't are waste.

### The Flow

```
Idea → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
```

**Seed.** An idea — a thought, conversation, observation, flag. That gleam in someone's eye, captured. Route it to a workstream.

**Research (MARFI).** Multi-Agent Request for Information. Before defining, gather input. Research agents explore competitors, prior art, implementation approaches in parallel. Cross-cutting research only — domain-specific exploration is the agent's normal work.

**Define (PVR).** Seed + research → discussion with principal → Product Vision & Requirements. The "what" and "why."

**Design (A&D).** Architecture & Design. The "how" and "why." Multi-agent input group contributes before the driving agent writes.

**Plan.** PVR + A&D → phases and iterations. Phase planning is autonomous — no principal engagement unless flagged.

**Implement.** Agents execute phases and iterations autonomously, surfacing for principal input as needed. Quality gate at every boundary.

**Ship.** Captain merges, builds PRs, pushes to origin. Pre-PR quality gate.

**Value.** Customer is using it. Feedback generates new seeds — closing the cycle.

### The Three-Bucket Pattern

The signature of valueflow. When an agent receives feedback on any artifact, it triages into three buckets:

| Bucket | What | Who decides |
|--------|------|-------------|
| **Disagree** | Agent disagrees — presents reasoning | Agent decides, principal reviews |
| **Autonomous** | Agent agrees and acts independently | Agent acts, principal informed |
| **Collaborative** | Requires principal input | 1B1 discussion |

Reviewers give raw findings. The **author** triages into buckets — not the reviewer. This pattern appears in MAR disposition, flag triage, dispatch handling, and plan review.

### Multi-Agent Review (MAR)

Review of artifacts at every transition. Many eyes, all bugs are shallow. With AI agents, the cost of review is seconds, not hours — there is no reason not to review everything.

Captain selects reviewers based on artifact type (PVR gets methodology critics; A&D gets security/performance reviewers; code gets the QG protocol). 24-hour timeout for cross-session agent reviewers. Author triages all findings via three-bucket.

### The Enforcement Ladder

Every capability follows a progressive tightening path. **The ladder is per-capability** — different parts of the framework are at different steps.

1. **Document** — write it in CLAUDE-THEAGENCY.md. Human-readable, no tooling required.
2. **Skill** — wrap it in an invocable skill. Discovery via `/` autocomplete.
3. **Tool** — build the mechanical capability. Pre-approved in settings.json.
4. **Hookify warn** — warn when the tool is bypassed. "You should use X."
5. **Hookify block** — block the bypass. Tool is the only path.

Each layer addresses the bypass discovered in the previous layer. Gate on artifact existence (mechanical, auditable), not on artifact quality (human judgment).

**Where we are today:** Mature capabilities like `git-commit`, `handoff`, and `dispatch` are at steps 4–5 (warn or block enforced). Newer methodology patterns like Valueflow, MAR, MARFI, and three-bucket triage are at step 1 — documented, but not yet skill-wrapped or enforced. Each capability progresses up the ladder as it matures.

The Ladder (progression) is distinct from the **Enforcement Triangle** (structure: tool + skill + hookify). A capability at step 5 has all three Triangle parts; a capability at step 1 has only docs. The Triangle is what each capability looks like when fully built; the Ladder is how it gets there.

### Captain

Captain is the coordination backbone. Always-on by design — first up, last down. If any agent is running, captain is running.

Two modes: **always-on loop** (dispatch processing, commit merging, PR building) and **interactive session** (principal sits down for seed discussions, MAR triage, strategic decisions).

### Artifacts

| Artifact | Content | Lifecycle |
|----------|---------|-----------|
| PVR | What and why | Evolves through discussion + implementation |
| A&D | How and why (technical decisions) | Evolves through implementation |
| Plan | Phases, iterations, QGRs | Updated after every commit |
| QGR | Quality gate results | Standalone receipt + appended to Plan |
| Reference | Final documentation | Produced at plan completion |

## SPEC-PROVIDER Pattern

TheAgency uses a **SPEC-PROVIDER** architectural pattern for capabilities that have multiple possible implementations: preview, deploy, security, and prototype scaffolding. The pattern keeps the framework generic while letting projects plug in their own backends.

### How It Works

Three layers:

| Layer | What | Where |
|-------|------|-------|
| **Spec** | Declares which provider to use | `claude/config/agency.yaml` |
| **Provider** | Tool that implements a contract for one backend | `claude/tools/{capability}-{provider}` |
| **Skill** | Generic dispatcher that reads the spec and calls the provider | `.claude/skills/{capability}/SKILL.md` |

### Example: Preview

**Spec** in `agency.yaml`:
```yaml
preview:
  provider: "docker-compose"   # or "fly", "vercel", "cloudflare"
```

**Provider** at `claude/tools/preview-docker-compose` implements the contract:
```bash
preview-docker-compose start    # launch, print URL
preview-docker-compose stop     # tear down
preview-docker-compose status   # running/stopped/error
preview-docker-compose logs     # stream recent logs
```

**Skill** `/preview` reads the spec, dispatches to the provider tool. Same skill works for any provider that implements the contract.

### Why This Pattern

- **Generic skills, specific implementations.** `/preview` doesn't know about Docker — it knows about the contract. New backends plug in by adding a `preview-{name}` tool.
- **Configuration in one place.** `agency.yaml` is the spec. Switch backends by changing one line.
- **Forward compatible.** Adopters can add their own providers without forking the framework.
- **Consistent UX.** Every SPEC-PROVIDER capability looks the same to the user — same skill invocation, same flags, same output format.

### Capabilities Using SPEC-PROVIDER

| Capability | Skill | Spec key | Provider naming |
|-----------|-------|----------|----------------|
| Preview | `/preview` | `preview.provider` | `preview-{provider}` |
| Deploy | `/deploy` | `deploy.provider` | `deploy-{provider}` |
| Security/Secrets | `/secret` | `secret.provider` | `secret-{provider}` |
| Prototype scaffolding | `/prototype-create` | `prototype.providers` | `prototype-{provider}` *(planned)* |

### Provider Contract

Each provider tool is a CLI that accepts standardized verbs. The skill defines the contract for its capability — providers implement it. New providers added by:

1. Creating `claude/tools/{capability}-{name}` that supports the verbs
2. Documenting the verbs in the tool's `--help`
3. Listing the provider as a valid value in the agency.yaml schema (optional)

The framework intentionally has no central provider registry — providers exist by being installed and named correctly. This keeps the pattern open and forkable.

---

*The sections below mirror the CLAUDE.md template structure. CLAUDE.md has the rules for agents; this README explains the why for humans.*

---

## Quality Gate Protocol

The Quality Gate (QG) is the core quality mechanism. Every commit goes through it. The project-manager agent orchestrates the process; the `/quality-gate` skill executes the 8-stage protocol.

### Why Quality Gates?

Traditional code review is one human reading another human's code. It catches some bugs, misses many, and scales linearly. TheAgency replaces this with parallel multi-agent review — 4+ specialized agents (code correctness, security, design, test quality) examine the work simultaneously, a scorer filters noise, and the agent fixes everything found before committing. The red→green test cycle means every fix is proven, not just asserted.

The result: quality is mechanical, not aspirational. You can't skip it, game it, or defer it. The QGR receipt is the proof.

### The 8 Stages

1. **Parallel review** — 4+ specialized agents (code, security, design, test) run in parallel, plus the agent's own review
2. **Score and consolidate** — scorer agent rates findings 0-100, filter below 50, deduplicate
3. **Bug-exposing tests** — write tests that expose each issue, confirm they fail (red)
4. **Fix issues** — fix each issue, confirm the test now passes (green). Red→green = proof.
5. **Coverage review** — identify gaps from test reviewer findings
6. **Add coverage tests** — edge cases, error paths, integration boundaries
7. **Fix new issues** — if new tests expose problems
8. **Confirm all clean** — lint, format, typecheck, all tests pass. Failing = 0.

### The QGR (Quality Gate Report)

Three tables + checks + narrative:

- **Issues Found and Fixed** — ID, type (bug/security/design/config/ux/performance), summary, how found, tests added
- **Quality Gate Accountability** — bug-exposing, coverage, pre-existing, passing, failing (MUST = 0)
- **Coverage Health** — unit, integration, e2e-cli, e2e-browser, api, performance. Zeros are visible and intentional.
- **Checks** — lint, format, typecheck, tests
- **Quality Gate Summary** — stage-by-stage description of what was done
- **What Was Found and Fixed** — plain-language narrative

### Quality Gate Types

- **Iteration QG** — scoped to the work in that iteration. Standard parallel review (4+ agents + own review). Commit automatically after clean QGR. No approval needed.
- **Phase QG** — deep review of the **entire project codebase**, not just changes. More agents, deeper inspection. Explicitly considers design alignment with A&D. **Approval required.** Design issues flagged for Pre-Phase Review.
- **Quality Phases** — dedicated phases focused on inspection, test development, and issue remediation. Like a HIP sprint. Still get a QG and QGR.
- **PR QG** — full diff against origin/master before PR creation. Run via `/pr-prep`.

### Day Counting Convention

Working day commits lead with `Day N:` where N counts working days per repo (or per workstream for workstream-scoped work). Day 1 is the first day of active work on the repo. "Day 32: foo" means the 32nd day of active work. Compare to calendar days for velocity signal.

Day counting and Phase-Iteration slugs are complementary — coordination commits use `Day N:` (e.g., infrastructure fixes, friction analysis), feature commits use `Phase X.Y:` (e.g., implementation work).

### Commit Message Format

Boundary commits lead with the Phase-Iteration slug:

```
Phase 1.2: feat: preview local + prototype router — Iteration 1.2

Adds local preview environment support via /preview local and
creates router commands for noun-verb naming (DD-10).

Plan: docs/plans/20260322-deployment-infrastructure.md

What was built:
- /preview local: tools/preview-local.ts wrapping Docker dev stack
- /prototype router: .claude/commands/prototype.md (all subcommands)

Quality gate (4-agent review + consolidation) — 16 issues fixed:
- #1 bug (inspection): shell injection via unquoted composePath
- #7 security (inspection): Bash(curl:*) unrestricted (scoped to localhost)

Tests: 334 passing (21 new: 8 bug-exposing, 13 coverage), 0 failing
```

### QGR Receipt Files

Each gate writes a standalone receipt file at the workstream location:

```
claude/workstreams/{ws}/quality-gate-reports/qgr-{boundary}-{phase.iter}-{stage-hash}-{YYYYMMDD-HHMM}.md
```

For workstreams with multiple projects, use a project subdirectory:

```
claude/workstreams/{ws}/project/{project}/quality-gate-reports/qgr-...
```

(Single-project workstreams skip the `project/` level until a second project is added — then existing files migrate.)

The QGR frontmatter includes `agent: {repo}/{principal}/{agent}` for attribution. The stage hash is a deterministic 7-character hash computed from the git staging area. `/git-commit` computes the same hash and globs for a matching receipt — if none exists, it warns that no QG was run.

## Development Methodology

### Plan Mode Bias

TheAgency has a strong bias toward planning before implementation. For any non-trivial task, agents enter plan mode first: explore the codebase, understand existing patterns, design the approach, get principal alignment, then implement.

This is the work pattern: **Discuss → Plan → Review Plan → Revise → Implement.**

Why? Because the cost of planning is low (read-only exploration, a few minutes of alignment) while the cost of rework is high (thrown-away code, confused state, wasted context). Plan mode also makes the agent's thinking visible to the principal — you can see what it found, what it's considering, and correct course before code is written.

### Living Documents

Three documents evolve together through the lifecycle of a project:

1. **Product Vision & Requirements (PVR)** — what we need and why. Captured during discovery/discussion. May start as rough notes and get refined. Use `/define` to drive toward completeness.
2. **Architecture & Design (A&D)** — the technical decisions, naming conventions, system structure, and design rationale. Flows from requirements, updated as we learn through implementation. Includes design decisions (DD-N). Use `/design` to drive toward completeness.
3. **Plan** — what we're doing, phase by phase. Includes quality gate reports as receipts. Updated after every commit.

The flow: **Requirements → Architecture & Design + Plan (evolving together through iteration) → Reference**

At plan completion, the three documents produce a **Reference** — the final "this is how it works" documentation. The living documents are the journey; the reference is the destination. Update architecture decisions as you learn — don't wait until the end.

## Worktrees & Master

TheAgency uses git worktrees to enable multiple agents working in parallel on the same repository. Each agent gets an isolated copy of the repo on its own branch.

### The Model

- **Master (main checkout)** — the captain session runs here. It coordinates: syncs worktrees, builds PR branches, dispatches reviews, pushes to origin. The captain does not implement features.
- **Worktrees (isolated branches)** — feature agents run here. They implement, test, and land work on master via boundary commands (`/phase-complete`).

This separation means agents never step on each other's work. Each worktree has its own branch, its own git state, and its own running environment. The captain orchestrates the flow of work between them.

### How Work Flows

```
Worktree agent builds → /phase-complete lands on master → captain /sync-all picks it up →
captain builds PR branch → /captain-review → dispatch findings (if any) → push + PR
```

### When to Use a Worktree

- **New prototype or feature** — always. Use `/workstream-create` or `/prototype-create` (planned via SPEC-PROVIDER pattern).
- **Quick fix on master** — small, isolated changes that don't need a branch.
- **Dispatch handling** — the worktree agent merges master to pick up the dispatch, fixes issues, lands via `/iteration-complete`.

## Session Handoff — Context Bootstrapping

Handoff files are a first-class Agency primitive. They serve multiple purposes beyond simple session continuity:

- **Session resumption** — pick up where you left off after context compaction, session end, or crash
- **Agent-to-agent transfer** — one agent writes context for another to consume (e.g., captain dispatches to worktree agent)
- **Cold start** — new agent bootstraps into a project's current state without reading the full history
- **Desired state injection** — spin up an agent pre-loaded with specific context, decisions, and work state

### How It Works

Handoff files live at `usr/{principal}/{project}/{agent}-handoff.md` — one per agent (e.g., `captain-handoff.md`, `iscp-handoff.md`, `devex-handoff.md`). The `claude/tools/handoff` tool manages the lifecycle and uses `agent-identity` to resolve which file to write based on the current branch/worktree.

- **`handoff write`** — auto-archives the existing handoff to `history/{agent}-handoff-YYYYMMDD-HHMMSS.md`, then signals the agent to write new content
- **`handoff write --lightweight`** — appends/updates a status line without archiving (for `/sync-all`)
- **`handoff read`** — outputs current handoff content
- **`handoff archive`** — manually archive without writing

The tool resolves paths automatically from the worktree branch and principal directory. Handoff writing is **manual** — agents must invoke the `/handoff` skill (or run `./claude/tools/handoff write`) at the appropriate trigger points below. There is no automatic handoff hook today; the `Stop` hook checks for uncommitted changes but does not write handoffs.

**Always invoke via the `/handoff` skill** — never write handoff files directly, never run the raw tool with `cd /path/to/main &&` (that breaks identity resolution and writes to the wrong agent's file). The `block-raw-handoff` hookify rule enforces this.

### Trigger Points

| Trigger | Type | Notes |
|---------|------|-------|
| `/iteration-complete` | Boundary | Step of the command |
| `/phase-complete` | Boundary | Step of the command |
| `/plan-complete` | Boundary | Final handoff before project close |
| `/pre-phase-review` | Boundary | Before clearance |
| Before exit/restart | Manual | Agent calls `/handoff` before ending session |
| `/sync-all` | Convention | Lightweight status update (captain only) |
| Discussion milestone | Convention | After PVR draft, key A&D decision, or plan revision |

## Discussion Protocol (1B1)

The 1B1 (one-by-one) protocol is how agents present information to principals. It prevents monolithic responses where topics bleed together and decisions get lost.

The core idea: when there are multiple items to discuss, address each one individually. Present → get feedback → confirm understanding (reflective listening) → revise → iterate → resolve → confirm resolution → next item. Never skip the "confirm understanding" step — it's the one agents skip most, and skipping it leads to wasted revision cycles.

The `/discuss` skill implements the full 8-step cycle and auto-starts a `/transcript` to capture decisions as they're made. The discussion IS the record. Transcripts live at `usr/{principal}/{project}/transcripts/` and persist decisions, rationale, and context that would otherwise be lost when the conversation scrolls off-screen or the session ends.

The 1B1 protocol applies to ALL structured discussions, not just when `/discuss` is explicitly invoked. It is the default way agents present information to principals.

## Feedback & Bug Reports (Claude Code)

When agents encounter issues with Claude Code itself (bugs, missing features, unexpected behavior), they draft structured feedback using a standard format that includes diagnostic evidence, reproduction steps, and root cause analysis when known. The format ensures Anthropic's team can triage quickly.

The key principle: **draft it, then wait for approval.** Agents never send feedback externally without the principal reviewing it first. The full format template is in `claude/docs/FEEDBACK-FORMAT.md` and gets injected automatically when feedback skills are invoked.

## Testing & Quality Discipline

### The Philosophy

TheAgency treats quality as non-negotiable and mechanical, not aspirational. The conventional approach — "be careful," "write good tests," "review thoroughly" — relies on discipline that erodes under pressure. TheAgency replaces discipline with automation: if a rule matters, it's enforced by a hook, linter, or skill, not by prose in a document.

The core principle: **we fix things, we don't work around them.** There are no small bugs. When an agent encounters a failing test, a noisy warning, or broken infrastructure, the blocker IS the work — not an obstacle to route around. This applies equally to pre-existing problems: if you find it, you own it.

### Why This Matters

- **Silent failures compound.** A swallowed error today becomes an undebuggable production issue next month. Failing loudly costs minutes; failing silently costs days.
- **Workarounds become permanent.** `--no-verify`, `eslint-disable`, `@ts-ignore` — each one is a crack that widens. Fix the root cause or accept the constraint, but never paper over it.
- **Stale artifacts mislead.** Dead code, unused config, and outdated docs actively harm productivity because they look real. Delete them — version control remembers.
- **Evidence beats theories.** Reading the docs, checking the actual data, and debugging with logs produces fixes. Guessing produces more bugs.
- **Mechanical enforcement beats prose.** Every rule in CLAUDE.md that can be a hookify rule, a linter check, or a pre-commit hook should be. Automation doesn't forget or get tired.

## Bash Tool Usage and the Tool Ecosystem

### The Rule

Run each shell command as a single, simple command — no `&&`, `||`, `;`, pipes, subshells, or `$(…)` substitutions. These bypass the allowed-tools list, triggering extra permission prompts that waste the principal's attention and break flow.

**Alternatives to compound patterns:**

| Instead of... | Use... |
|--------------|--------|
| `cd dir && command` | `cwd` parameter on the Bash tool, or separate calls |
| `command \| grep pattern` | The Grep tool directly |
| `git commit -m "$(cat <<'EOF'...)"` | `/git-commit` skill |
| `command1 && command2` | Two separate Bash tool calls (sequential) |
| `command > file` / `cat <<EOF > file` | The Write tool |
| `cat file` / `head` / `tail` | The Read tool |
| `find . -name "*.ts"` | The Glob tool |
| `grep -r "pattern"` | The Grep tool |
| `for f in *.ts; do ...; done` | Glob to find files, then separate Bash calls |

### The Bigger Picture: Tools Over Inline Bash

TheAgency encourages building **tools** (`tools/`, `claude/tools/`) rather than writing inline bash. This is about more than style:

- **Observability.** Tools built with `_log-helper` emit structured telemetry to `tool-runs.jsonl` — who ran what, when, how long, what happened. Inline bash is invisible.
- **Token economics.** A tool that does the right thing in one call saves tokens compared to multi-step bash sequences with error handling at each step. The tool absorbs the complexity; the agent pays one invocation.
- **Reusability.** A tool used by one agent today is available to all agents tomorrow. Inline bash dies with the conversation.
- **Testability.** Tools can have tests (`tools/__tests__/`). Inline bash can't.
- **Learning.** This connects to the pattern gstack calls "learnings" — capturing what works into durable artifacts that compound over time. A tool is a crystallized learning: "this is the right way to do X."

When an agent needs to do something, the first question should be: **does a tool already exist?** Check `tools/`, `claude/tools/`, and the tool registry before writing bash. If no tool exists and the task will recur, consider building one.

## Web Content Retrieval

### The Escalation Ladder

Agents frequently need to fetch web content — documentation, issue threads, articles, competitor sites. The approach matters for both reliability and token economics:

1. **WebFetch** — try first. Fast, cheap, no browser needed. Works for most documentation sites and APIs. Fails on JS-heavy sites and sites with bot detection.
2. **Playwright MCP snapshot** — if WebFetch fails or returns garbage. Renders JS, returns a structured accessibility tree. Prefer `browser_snapshot` over `browser_take_screenshot` for text content — it's structured and far more token-efficient.
3. **Playwright MCP screenshot** — when visual context is needed (layout, design issues, error states).
4. **Playwright MCP run_code** — for extracting specific content from large pages (`page.$('article').innerText()`). Avoids dumping entire page trees into context.

### Blocked Sites

Some sites block unauthenticated access (X/Twitter, LinkedIn):

- Use Nitter mirrors (e.g., `nitter.poast.org/{user}/status/{id}`) for X/Twitter — no login required, full thread visible.
- If mirrors fail, navigate with Playwright MCP to the real site (may require the principal to log in first).

### Principles

- **Extract what you need** — don't dump whole pages into context. A 50KB page tree burns tokens for content you'll never use.
- **Summarize, don't paste** — raw HTML is noise. Produce structured summaries.
- **For threads/articles** — capture the full content, then distill to key points.

### Future: Better Web Tooling

The current approach (escalation ladder with manual decisions) is functional but not ideal. TheAgency will build dedicated web content tools that handle the escalation automatically, cache results, extract structured content, and integrate with the telemetry/observability stack. This is tracked as a dispatch item for the-agency.

## Git & Remote Discipline

### The Push Model

Remote master is read-only. No agent ever pushes to origin/master directly. All changes reach origin through PRs that the captain creates and the principal approves.

This is mechanically enforced: hookify rules block any push to master and warn on any push at all. An agent must confirm authorization before any push proceeds. The captain is the only agent that pushes, and only via `/sync` with explicit principal approval.

### Role-Based Git Permissions

Git operations are scoped by agent role:

- **Feature agents (worktrees)** build code, commit at boundaries via `/iteration-complete` and `/phase-complete`, land on master via the phase-complete flow. They never push to origin and never create PRs.
- **The captain (master)** receives landed work via `/sync-all`, builds PR branches, runs code review, pushes when approved, and creates draft PRs. The captain never writes application code.
- **The project-manager** never touches git directly. It runs the QG protocol and produces receipts. The calling agent handles all git operations.

### Post-Merge Sync

After a squash PR merges on origin, the next `/sync-all` detects the divergence (local master has the pre-squash commits, origin has the squashed commit). It automatically runs reset+rebase to reconcile. This is Step 2.5 in `/sync-all` — mechanical, no manual step to remember.

Worktree branches may need `--force-with-lease` after sync because reset+rebase rewrites their history.

### Mechanical Enforcement

Git discipline is enforced by hookify rules. The git-related rules:

| Rule | Action | What it does |
|------|--------|-------------|
| `no-push-main` | BLOCK | Prevents any push to main |
| `block-force-push-main` | BLOCK | Prevents force push to main/master |
| `warn-on-push` | WARN | Requires confirmation before any push |
| `warn-destructive-git` | WARN | Flags reset --hard, checkout --, etc. |
| `warn-external-git-actions` | WARN | Flags external-facing git operations |
| `block-cd-to-main` | BLOCK | Prevents worktree agents from cd-ing to main repo |
| `block-raw-git-merge-master` | BLOCK | Forces use of `/sync-all` instead of raw merge |

For the complete enforcement model — Triangle, Ladder, lifecycle hooks, all 33 hookify rules, quality gate tiers, and the permission model — see `claude/README-ENFORCEMENT.md`.

## Local Setup / Sandbox

### The Sandbox Principle

**Everything sandboxed. Zero impact to the team. Completely opt-in.**

Every engineer's personal Claude Code configuration — commands, hookify rules, hooks, settings, project artifacts, plans, data — lives under `usr/{principal}/`. Nothing in this directory forces changes on other team members. The only shared changes are additive code (new modules, new tools) and the minimum wiring to make them work.

This means multiple engineers can experiment with different workflows, rules, and tools on the same repo without stepping on each other. Your experiments are committed (so they're version controlled and portable), but they're not activated for anyone else unless they opt in.

### How Symlink Activation Works

Claude Code discovers commands in `.claude/commands/`, hookify rules in `.claude/hookify.*.local.md`, and settings in `.claude/settings.local.json`. These are the "discovery locations."

Sandbox items live in `usr/{principal}/claude/` (the source). To activate them, you symlink from the discovery location to the source:

```
.claude/commands/usr-jordan.quality-gate.md → ../../usr/jordan/claude/commands/quality-gate.md
.claude/hookify.require-qgr.local.md → usr/jordan/claude/hookify/hookify.require-qgr.local.md
```

The symlinks are gitignored — they exist only on your machine. This is the key: the source files are committed and shared, but the activation is local.

### The Lifecycle: Sandbox → Shared → Team

1. **Sandbox** — engineer creates an experiment in `usr/{principal}/claude/`. Activates locally via `/sandbox-activate`. Tests it in their own sessions. Other engineers don't see it unless they opt in via `/sandbox-try`.

2. **Shared** — if the experiment proves valuable, `/sandbox-adopt` moves it from the sandbox to `.claude/` (the shared location). Now it's committed and active for everyone. The sandbox source can be cleaned up or kept as reference.

3. **Personal** — some items are user-specific and should never be shared. Files with `.user.local.md` suffix are gitignored — they exist only on one machine. Tracked in `~/.claude/user-manifest.md` for portability.

### Hookify Rule Scoping

Hookify rules have three tiers, each with different visibility:

| Location | Scope | Git Status | Who sees it |
|----------|-------|------------|-------------|
| `usr/{principal}/claude/hookify/` | Sandbox | Committed | Only the engineer who activates it |
| `.claude/hookify.foo.local.md` | Shared (adopted) | Committed | Everyone |
| `.claude/hookify.foo.user.local.md` | Personal | Gitignored | Only one machine |

The naming convention matters: `.local.md` means it's a hookify rule (as opposed to a regular markdown file). `.user.local.md` means it's personal and gitignored.

### Why This Matters

Traditional team tooling is all-or-nothing: either everyone uses the same config, or everyone maintains their own fork. The sandbox model gives you both — shared baseline plus personal experimentation, with a clean graduation path from experiment to standard.

## Code Review & PR Lifecycle

### Why Local Review?

Most AI code review tools (Charly, GitHub @claude Action) run in CI against a PR that already exists. They're limited by diff size, require manual triggering, and produce comments that are disconnected from the development flow.

TheAgency reviews code **locally, before PRs exist.** The captain runs 7 specialized review agents against `git diff origin/master...<branch>`, scores findings for confidence, and dispatches actionable issues back to the worktree agent who wrote the code. The review results are committed to the repo and included in the PR diff — so human reviewers see both the code and the machine review.

### Three Review Tools

| Tool | Who | When | Depth | Fix cycle? |
|------|-----|------|-------|------------|
| `/code-review` | Captain | After PR branch built | 7 agents + scoring, ≥80 confidence | No — dispatches |
| `/review-pr` | Human/agent | Ad-hoc, after PR exists | 1 agent, max 5 comments, approval before posting | No |
| `/phase-complete` | Worktree agent | Iteration/phase boundary | Deep QG, 4+ agents, red→green | Yes |

These serve different purposes at different points in the lifecycle. `/code-review` is the captain's tool for pre-PR review. `/review-pr` is for ad-hoc human-initiated review of an existing PR. `/phase-complete` is the worktree agent's QG at boundaries. They don't replace each other.

### The Captain PR Lifecycle

The captain orchestrates the full cycle:

```
1. /sync-all — merge worktree work into master
2. Rebuild PR branches (reset → squash → stage → commit)
3. /captain-review --all — review all PR branches locally
4. If issues found: dispatch to worktree agents via dispatch files
5. Worktree agents fix issues → land on master via /iteration-complete
6. If no issues (or after fixes land): rebuild PR branches (includes fixes + review files)
7. Push and create draft PRs (review results visible in the diff)
8. Human review → convert to ready-for-review → merge
```

If all PRs are clean (zero issues ≥80 confidence), steps 4-5 are skipped.

### The Dispatch Model

When the captain finds issues, it writes two files per project:

1. **Review file** — full output from all 7 agents, all issues with confidence scores
2. **Dispatch file** — actionable issues (≥80 confidence) with file paths, line numbers, suggested fixes, and the reviewed commit SHA

These are committed to master. The worktree agent picks them up by merging master, then works through the findings using the dispatch handling protocol: evaluate validity → bug-exposing test (red) → fix (green) → resolution table → `/iteration-complete`.

Agents use their judgment — a dispatch is review input, not an action list. Findings are either **Fixed** (valid finding, resolved) or **Rejected** (invalid finding, with reasoning). No "Deferred," no "Won't Fix," no severity-based skip. Every valid finding gets fixed — severity orders the fix sequence, never the fix decision.

### Review File Convention

```
usr/{principal}/{project}/
  code-reviews/
    {project}-review-YYYYMMDD-HHMM.md     — full review output
    {project}-dispatch-YYYYMMDD-HHMM.md    — actionable findings
```

YYYYMMDD-HHMM timestamps ensure uniqueness for multiple reviews per day. These files appear in the PR diff as the audit trail — reviewers can see both the code and the review.

---

## How Our Agents Work

### Agent Definitions

- **Class/instance model** — `claude/agents/{class}/agent.md` defines the role; `usr/{principal}/{agent}/` is the working instance with handoff, project artifacts, and session state.
- **Standard classes** — captain (coordination), tech-lead (architecture), marketing-lead (content), platform-specialist (infrastructure), researcher (investigation)
- **Workstream model** — agents work on workstreams with shared artifacts (seeds, PVR, A&D, Plan)

### TheAgency Default Structure

When a project adopts TheAgency, the framework adds a layer alongside the project's existing directories. The project keeps its own structure (`apps/`, `packages/`, `src/`, whatever it has). TheAgency adds:

```
my-project/
├── README.md                    — project README (scaffold)
├── CLAUDE.md                    — project CLAUDE.md (scaffold) — @imports claude/CLAUDE-THEAGENCY.md
│
├── .claude/                     — CLAUDE CODE DISCOVERY LOCATION
│   ├── commands/                — active skills (framework + symlinked personal)
│   ├── skills/                  — skill definitions
│   ├── settings.json            — Claude Code settings (scaffold — never overwritten)
│   └── hookify.*.local.md       — active hookify rules (symlinks)
│
└── claude/                      — THE AGENCY FRAMEWORK (single namespace)
    ├── CLAUDE-THEAGENCY.md      — Agency methodology (imported by root CLAUDE.md)
    ├── README-THEAGENCY.md      — This file — orientation for humans
    ├── README-GETTINGSTARTED.md — Onboarding guide
    ├── config/
    │   ├── agency.yaml          — project-specific Agency config (scaffold)
    │   ├── manifest.json        — tracks installed files and versions
    │   └── settings-template.json — canonical permissions/hooks template (framework)
    ├── agents/                  — agent CLASS definitions (framework)
    │   ├── captain/agent.md     — per-repo coordination
    │   ├── project-manager/agent.md — process enforcement (QG, boundaries)
    │   ├── cos/agent.md         — Chief of Staff (cross-repo, strategic)
    │   └── reviewer-*/agent.md  — review agents (code, design, security, test, scorer)
    ├── docs/                    — reference docs (injected on demand by hooks)
    │   ├── QUALITY-GATE.md      — QGR format, protocol, commit message spec
    │   ├── FEEDBACK-FORMAT.md   — bug report / feature request template
    │   ├── CODE-REVIEW-LIFECYCLE.md — dispatch handling protocol
    │   └── DEVELOPMENT-METHODOLOGY.md — full Seed→Reference lifecycle
    ├── hooks/                   — session lifecycle hooks (config tier)
    ├── hookify/                 — shipped behavioral rules (config tier)
    ├── templates/               — scaffolding templates (framework)
    ├── tools/                   — ALL tools — bash, python, rust, compiled (framework)
    │   ├── lib/                 — tool libraries (_log-helper, _path-resolve, etc.)
    │   ├── handoff              — context bootstrap
    │   ├── stage-hash           — deterministic staging area hash
    │   ├── git-commit           — QG-aware commit wrapper
    │   ├── settings-merge       — merge settings template into current
    │   └── ...                  — (worktree-*, etc.)
    ├── workstreams/             — bodies of work
    │   ├── agency/              — framework methodology (valueflow)
    │   ├── iscp/                — inter-session communication protocol
    │   ├── devex/               — developer experience
    │   └── ...                  — per-project workstreams
    └── starter-packs/           — starter kit templates for agency init
usr/                             — agent INSTANCES (at PROJECT ROOT, not under claude/)
    └── {principal}/
        └── {project}/           — one directory per project
            ├── {agent}-handoff.md — current session state
            ├── {project}-pvr-*.md
            ├── {project}-ad-*.md
            ├── {project}-plan-*.md
            ├── code-reviews/    — captain review + dispatch files
            ├── dispatches/      — incoming dispatches
            ├── transcripts/     — discussion transcripts
            └── history/         — archived handoffs and artifacts
```

**Three file tiers** (governs what `agency-update` does):

| Tier | On init | On update | Example |
|------|---------|-----------|---------|
| **Framework** | Copy | Always overwrite | agents/, docs/, tools/ |
| **Config** | Copy | Overwrite if untouched, skip if user-modified | hooks/, hookify/ |
| **Scaffold** | Generate | Never touch | CLAUDE.md, agency.yaml, settings.json |

**Key principles:**

- **`claude/`** is the single Agency namespace. Everything Agency-related lives here. Good neighbor in someone else's repo.
- **`.claude/`** is Claude Code's discovery location. Mix of framework files and personal symlinks.
- **`claude/tools/`** is all tools — language-agnostic. No separate `scripts/` or `tools/` at repo root.
- **`usr/{principal}/`** is the sandbox. Per-engineer. Committed but only activated locally via symlinks.
- **Git is the rollback.** Updates don't auto-commit. `git checkout -- claude/` undoes any botched update.
- **Your project's directories** (`apps/`, `packages/`, `docs/`, etc.) are untouched. TheAgency is additive.

### How It All Loads: The `@import` Mechanism

Claude Code expands `@path/to/file.md` directives in CLAUDE.md files at session launch, recursively up to 5 levels deep. TheAgency uses this to separate project content from methodology:

```markdown
# CLAUDE.md (project root — written by the project team)

## Project Overview
MonoFolk is OrdinaryFolk's Turborepo monorepo...

## Project Architecture
[project-specific directory tree]

## Project Tooling
[skills table, code quality, runtime, conventions]

---

@claude/CLAUDE-THEAGENCY.md
```

The project `CLAUDE.md` owns the project context — what this repo is, how to build it, what tools it uses. The `@` import at the bottom pulls in the full Agency methodology from `claude/CLAUDE-THEAGENCY.md`. Two physical files, one logical CLAUDE.md.

This separation means:
- **The project team** maintains `CLAUDE.md` with project-specific content. They don't touch the Agency file.
- **TheAgency framework** maintains `claude/CLAUDE-THEAGENCY.md` with methodology. It's the same across repos (installed by `agency init`).
- **Updates to the methodology** propagate to all projects by updating `claude/CLAUDE-THEAGENCY.md` — no changes to individual project CLAUDE.md files needed.
- **`usr/{principal}/claude/CLAUDE.md` (the personal user-level file) goes to zero** — everything it contained is now in either the project CLAUDE.md or the Agency template.

## How Our Principals Work

*Section pending — will cover principal roles, how principals interact with agents, multi-principal coordination, and the principal configuration model (Layer 3).*

---

## Claude Code Concepts Primer

Claude Code has seven core architectural concepts. Together they form the primitives of an agent-native development environment. TheAgency builds on all of them.

**Agents** are isolated AI workers. **Skills** are reusable instructions. **Commands** are how you invoke skills. **Hooks** are mechanical enforcement. **Events** are the lifecycle moments that trigger hooks. **MCP Servers** bring in external tools. **Settings** tie it all together as declarative policy.

Two additional concepts cut across everything: the **Status Line** (real-time session display) and **Permissions** (declarative tool access control).

### Agents

An agent is a specialized AI assistant that runs in its own context window, separate from the main conversation. It gets its own system prompt, tool restrictions, and permission model.

Claude spawns an agent with a task. The agent runs agentic loops in its own isolated context. When it finishes, it returns a summary to the parent. The verbose work stays in the agent's context and never pollutes the parent's. This context isolation is the primary benefit — a code review agent can read dozens of files, run tests, and produce detailed analysis, and the parent only sees the summary.

Key properties: agents can use a different model than the parent, can be restricted to specific tools, cannot spawn other agents (no nesting), and are resumable. Three invocation modes: automatic delegation, explicit `@"agent-name"`, or `--agent <name>` for a full session. Execution modes: foreground (blocking), background (concurrent), or isolated git worktree.

Configuration: Markdown files with YAML frontmatter in `.claude/agents/`.

### Skills

A skill is a Markdown file with optional frontmatter that provides reusable instructions. Claude applies skills when they're relevant to the task, or you invoke them directly with `/skill-name`.

Claude loads skill descriptions into context at session start. When a task matches a skill's description, Claude loads the full content and follows those instructions. Skills can auto-load based on description matching or be restricted to manual invocation only (`disable-model-invocation: true`). They support dynamic content injection — shell commands that run before Claude sees the skill content.

Configuration: `.claude/skills/<name>/SKILL.md` (recommended) or `.claude/commands/<name>.md` (legacy, still works).

### Commands

A command is a slash-invoked action. Three kinds: **built-in** (`/help`, `/config`, `/compact`), **skill-based** (user-defined Markdown files), and **MCP prompts** (exposed by MCP servers). Commands in `.claude/commands/` are skills — same frontmatter, same mechanism.

### Hooks

A hook is a deterministic shell command that executes automatically at specific lifecycle events. Unlike skills, hooks don't rely on LLM judgment — they're mechanical enforcement.

An event fires, all matching hooks receive JSON data on stdin, each returns a decision via exit code and stdout. Exit code 0 = success, exit code 2 = block the action. Four types: **command hooks** (shell script), **HTTP hooks** (POST to endpoint), **prompt hooks** (lightweight LLM evaluation), **agent hooks** (subagent with tool access).

Key distinction: hooks are deterministic and stateless (fire on event patterns, return exit codes). Skills are judgment-based (Claude decides how to apply them). Hookify rules are a higher-level layer built on hooks — stored as `.claude/hookify.*.local.md` files.

Configuration: settings.json at any scope.

### Events

Events are lifecycle points where hooks trigger. The flow: `SessionStart` → `UserPromptSubmit` → agentic loop (`PreToolUse` → tool execution → `PostToolUse`) → `Stop` → `SessionEnd`. Async events: `FileChanged`, `PreCompact`, `SubagentStart`/`SubagentStop`.

Some events can block (`PreToolUse` can prevent a tool call, `PermissionRequest` can auto-approve/deny, `Stop` can re-prompt). Others are informational only.

### MCP Servers

MCP (Model Context Protocol) servers are external tool and data providers. They expose **tools** Claude can call (send Slack message, query database, create GitHub issue), **resources** Claude can reference, and **prompts** that appear as commands. Servers run as local processes (stdio) or HTTP endpoints.

Configuration: `.mcp.json` at project or user level.

### Settings

Settings control Claude Code's behavior at four scopes, highest to lowest priority: **Managed** (server-controlled, org-wide, cannot be overridden) → **User** (`~/.claude/settings.json`) → **Project** (`.claude/settings.json`, team-wide via git) → **Local** (`.claude/settings.local.json`, personal, gitignored).

They control: model and effort level, permission rules, hook configurations, environment variables, status line, plugin enablement.

### How They All Relate

Each concept serves a distinct role. **Hooks** are mechanical enforcement. **Skills** are reusable judgment. **Agents** are isolated delegation. **Settings** are declarative configuration. **MCP** is extensibility. Settings configure everything. Events trigger hooks. Hooks enforce rules on tool calls. Skills guide Claude's judgment. Skills can fork into agents. Commands are the user-facing entry point. MCP servers expose tools that integrate with all of the above.

### The SDLC Lens

Claude Code's architecture is a working model of an agent-native development lifecycle. **Agents** replace human delegation. **Hooks** replace human discipline. **Skills** replace tribal knowledge. **Events** replace human observation. **Settings** replace team agreements. The AIADLC doesn't replace what we know about software development — it mechanically enforces what we've always said we'd do, and then cranks it past what humans could sustain alone.

---

## Revision Guidance

*The following items should be incorporated into this README during the next revision pass:*

- [ ] Add more detail on the comparison with gstack — what gstack does well (template system, learnings JSONL, confidence scoring), what TheAgency does differently
- [ ] Add metaswarm comparison — BEADS task tracking, recursive orchestration, self-reflection patterns
- [ ] Reference the FAANG AIADLC source material at `claude/docs/book-sources/SOURCE-faang-ai-workflow-reddit.md`
- [ ] Add the thesis statement: "The Agency represents the next evolution — from 'AI assists developers' to 'AI agents are developers, humans are principals.'"
- [x] Add section on QG protocol, QGR format, commit message example, QGR receipt files
- [x] Add sections mirroring CLAUDE.md structure (session handoff, discussion, feedback, testing & quality, bash, web content)
- [x] Add development methodology (plan mode bias, living documents)
- [x] Add worktrees & master section
- [x] Add Claude Code Concepts Primer — full content incorporated into README
- [x] Complete pending sections: git & remote, local setup/sandbox, code review & PR lifecycle
- [x] Complete TheAgency Default Structure section
- [ ] Complete How Our Principals Work section
- [ ] Add Agent Startup Protocol section
- [ ] Add Naming Conventions section
- [ ] Add Secrets/Provider model section (`/secret` skill, agency.yaml, Doppler/vault)
- [ ] Add Common Pitfalls section (anti-patterns, "What NOT to Do")
- [ ] Add section on the parameterized CLAUDE.md template — how TheAgency deploys methodology to any repo
- [ ] Add section on the three-layer model: Layer 1 (TheAgency methodology), Layer 2 (project specifics), Layer 3 (principal config — may be zero)
- [ ] Add README-GETTINGSTARTED.md for new adopters
- [ ] Add `/workstream-create` skill (gap identified during review)
- [ ] Consider adding a "Kata Symphony" reference — headless orchestrator with Linear integration
- [ ] Consider adding a "Swamp" reference — AI-native automation runtime (adopted for Mycroft)

---

*AND REMEMBER: OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
