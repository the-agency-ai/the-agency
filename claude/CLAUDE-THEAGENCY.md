# AIADLC Project Instructions (TheAgency)

These instructions establish TheAgency methodology for this project and apply to all agents and principals working in this repository. For background on TheAgency, see `claude/README-THEAGENCY.md`.

This file is imported via `@claude/CLAUDE-THEAGENCY.md` from the project's root `CLAUDE.md`. See `claude/README-THEAGENCY.md` for setup details.

## TheAgency Repo Structure

TheAgency uses two top-level directories: `claude/` for framework code and `usr/` for per-principal sandboxes.

```
claude/                    — framework (tools, agents, docs, hooks, config)
  CLAUDE-THEAGENCY.md      — this file (Agency methodology, imported by root CLAUDE.md)
  README-THEAGENCY.md      — orientation for humans
  README-GETTINGSTARTED.md — onboarding guide
  config/
    agency.yaml            — project-specific Agency config
    manifest.json          — tracks installed files and versions
    settings-template.json — canonical permissions/hooks template
  agents/                  — agent CLASS definitions
    {class}/agent.md       — role, responsibilities, model, tools
  docs/                    — reference docs (injected on demand by hooks)
    QUALITY-GATE.md        — QGR format, protocol, commit message spec
    FEEDBACK-FORMAT.md     — bug report / feature request template
    CODE-REVIEW-LIFECYCLE.md — dispatch handling protocol
    DEVELOPMENT-METHODOLOGY.md — full Seed→Reference lifecycle
  hooks/                   — session hooks (ref-injector, tool-telemetry, session-handoff)
  hookify/                 — shipped behavioral rules
  tools/                   — all tools (bash, python, rust, compiled)
    lib/                   — tool libraries (_log-helper, _path-resolve, etc.)
    handoff                — context bootstrap (read/write/archive)
    stage-hash             — deterministic staging area hash
    git-commit             — QG-aware commit wrapper
    settings-merge         — merge settings template into current settings
    agent-identity         — "who am I" identity resolution
    dispatch               — dispatch lifecycle (create/list/read/check/resolve/status)
    flag                   — agent-addressable flag capture and processing
    iscp-check             — "you got mail" notification hook
    iscp-migrate           — legacy flag/dispatch migration (one-shot)
  templates/               — scaffolding templates
  workstreams/             — bodies of work
    {workstream}/
      CLAUDE-{WORKSTREAM}.md — workstream-scoped instructions
      KNOWLEDGE.md         — patterns, conventions, key decisions
      seeds/               — input materials
      dispatches/          — workstream-targeted dispatches
      reviews/             — QGRs and review files
      history/             — archived artifact versions
  src/                     — --dev only (source code, tests)
usr/                       — agent INSTANCES (per-principal sandboxes, at PROJECT ROOT)
  {principal}/
    {project}/             — one directory per project
      CLAUDE-{AGENT}.md    — agent-scoped instructions
      {agent}-handoff.md   — per-agent session state (one per agent in project)
      {project}-pvr-*.md   — Product Vision & Requirements
      {project}-architecture-*.md — Architecture & Design
      {project}-plan-*.md  — The Plan
      code-reviews/        — captain review and dispatch files
      dispatches/          — incoming dispatches
      transcripts/         — discussion transcripts
      history/             — archived handoffs and artifacts
      tools/               — agent-written scripts (persisted, reusable)
      tmp/                 — scratch space (ephemeral, gitignored)
.claude/                   — Claude Code discovery location
  commands/                — active skills (symlinks from usr/ + shared)
  skills/                  — skill definitions
  settings.json            — Claude Code settings (scaffold — never overwritten by updates)
  hookify.*.local.md       — active hookify rules (symlinks)
```

**IMPORTANT:** `usr/` is at the **project root**, NOT under `claude/`. The path is `usr/{principal}/`, not `claude/usr/{principal}/`.

Your project's own directories (`apps/`, `packages/`, `docs/`, `scripts/`, etc.) are documented in the project-specific section of this CLAUDE.md.

### Scoped CLAUDE.md Files

Every workstream and every agent gets a scoped CLAUDE.md file. These are fully qualified by path — the file name uses the workstream or agent name, and the path provides the namespace:

| Scope | Location | Content |
|-------|----------|---------|
| **Framework** | `claude/CLAUDE-THEAGENCY.md` | Agency methodology (this file) |
| **Workstream** | `claude/workstreams/{name}/CLAUDE-{WORKSTREAM}.md` | Scope, boundaries, conventions, review discipline |
| **Agent** | `usr/{principal}/{project}/CLAUDE-{AGENT}.md` | Identity, startup sequence, coordination, file discipline |

Agent registrations (`.claude/agents/{name}.md`) import both via `@` directives:

```markdown
@usr/{principal}/{project}/CLAUDE-{AGENT}.md
@claude/workstreams/{workstream}/CLAUDE-{WORKSTREAM}.md
```

`/workstream-create` scaffolds the workstream CLAUDE.md. `/agent-create` (via `workstream-create`) scaffolds the agent CLAUDE.md. Both are part of the standard creation workflow.

- **One plan per project.** Date stamp bumps only on a new day. Same file all day.
- **No nesting** — `usr/{{principal}}/folio/`, not `usr/{{principal}}/docs/projects/folio/`.
- **Code** stays in project directories (`apps/`, `src/`, etc.) — not in sandbox project dirs.

## Agent & Principal Addressing

Every agent and principal has a structured address used in dispatches, handoffs, and tool output. This section defines those addresses and how they resolve.

### Principals and Agents

A **principal** is a human who directs agent work. An **agent** is an AI instance running under a principal's direction. Every agent belongs to exactly one principal.

Identify principals and agents by **name** — a lowercase ASCII slug (`[a-z0-9][a-z0-9_-]*`, max 32 characters). Names are machine identifiers for paths, addresses, and code. They are NOT human names.

For human-readable display, set `display_name` in `agency.yaml` — a single freeform Unicode string. Do not parse it, split it into fields, or restrict its characters. People's names contain apostrophes (O'Brien), hyphens (Dea-Mattson), diacritics (José), CJK characters (田中太郎), spaces, and more. The display name accepts whatever the human says their name is. (See: [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/).)

```yaml
principals:
  tanaka:                       # system username on this machine
    name: tanaka                # principal slug (machine identifier)
    display_name: "田中太郎"       # human display (freeform Unicode)
    address:
      informal: "太郎"           # how to address in conversation (default: display_name)
      formal: "田中さん"          # formal address (default: display_name)
    platforms:
      github:
        - username: tanaka-taro
          repos:
            - org: the-agency-ai
              repo: the-agency
```

Defaults: if `address.informal` is omitted, use `display_name`. If `address.formal` is omitted, use `display_name`. Most principals only need `display_name` — the address fields are for when the principal has a preference:

```yaml
  jdm:
    name: jordan
    display_name: "Jordan Dea-Mattson"
    address:
      informal: "Jordan"        # "Hey Jordan" not "Hey Jordan Dea-Mattson"
    platforms:
      github:
        - username: jordandm
          repos:
            - org: the-agency-ai
              repo: the-agency
        - username: jordan-of
          repos:
            - org: OrdinaryFolk
              repo: monofolk
            - org: the-agency-ai
              repo: the-agency
```

**Reserved names** (cannot be used as principal or agent names): `_` (shared agents), `system`, `shared`, `all` (broadcast addressing), `default` (used by `_path-resolve` when no principal can be resolved from `$USER`).

**Display name safety:** `display_name` and `address.*` fields are freeform Unicode. Double-quote them in YAML output. Never use them in filesystem paths, address strings, or machine-parseable identifiers. Tools that emit them into markdown must ensure they cannot produce a bare `---` line (which breaks frontmatter boundaries).

**Use `address.informal`** when addressing the principal in conversation. Use `address.formal` in dispatch headers and formal communications.

### Address Hierarchy

Two addressing targets: **agents** (principal-scoped) and **workstreams** (repo-scoped).

**Agent addressing** — four levels, broadest to narrowest:

```
{org}/{repo}/{principal}/{agent}
```

| Level | What | Constraint | Example |
|-------|------|-----------|---------|
| Org | Hosting namespace (GitHub org, GitLab group) | Case-preserved, `[A-Za-z0-9-]+` | `the-agency-ai`, `OrdinaryFolk` |
| Repo | Repository short name | `[a-z0-9][a-z0-9_-]*`, no slashes | `the-agency`, `monofolk` |
| Principal | Human directing the agent | `[a-z0-9][a-z0-9_-]*` | `jordan`, `peter`, `tanaka` |
| Agent | Agent instance name | `[a-z0-9][a-z0-9_-]*` | `captain`, `devex` |

**Workstream addressing** — two levels, repo-scoped (no principal):

```
{repo}/{workstream}
```

| Level | What | Constraint | Example |
|-------|------|-----------|---------|
| Repo | Repository short name | Same as agent addressing | `the-agency`, `monofolk` |
| Workstream | Workstream name | `[a-z0-9][a-z0-9_-]*` | `iscp`, `mdpal`, `mock-and-mark` |

Workstreams are repo-level concepts — they match `claude/workstreams/{name}/`. No principal scoping.

**Disambiguation:** A bare name (e.g., `iscp`) could be an agent or a workstream. Resolution order: (1) check `claude/workstreams/{name}/` — if exists, it's a workstream; (2) check agent registrations — if exists, it's an agent; (3) fail with actionable error.

Repo short names are the leaf name only — no org prefix, no nested group paths. For GitLab nested groups (`org/subgroup/repo`), the short name is `repo`. The `remotes` registry handles full path resolution.

### What Tools Write vs. What Tools Accept

**Always write fully qualified** — `{repo}/{principal}/{agent}`. Every tool, every dispatch, every handoff, every written record. No exceptions. The written record must be unambiguous regardless of future context changes.

**Accept short forms as input** and resolve them using local context:

| Input form | Pattern | Resolution |
|------------|---------|------------|
| Bare | `captain` | Resolve repo from git, principal from agency.yaml |
| Principal-scoped | `jordan/captain` | Resolve repo from git |
| Fully qualified | `monofolk/jordan/captain` | No resolution needed |
| Org-qualified | `OrdinaryFolk/monofolk/jordan/captain` | No resolution needed (rare — repo name collision across orgs) |

Parse input by segment count: 1 = bare, 2 = principal/agent, 3 = repo/principal/agent, 4 = org/repo/principal/agent. Three segments is ALWAYS `repo/principal/agent` — never `org/repo/principal`. Use all 4 segments for org qualification. Warn if the first segment of a 3-segment address matches a known org name.

**Principal resolution:** Find the `principals` entry in `agency.yaml` whose key matches `$USER`, then use its `name` field as the principal slug. Example: `$USER=jdm` → key `jdm` → `name: jordan` → principal is `jordan`.

### Principal Identity Across Repos

A principal may have different platform identities in different orgs:

| Repo | Local name | GitHub identity | Org |
|------|-----------|----------------|-----|
| the-agency | `jordan` | `jordandm` | `the-agency-ai` |
| monofolk | `jordan` | `jordan-of` | `OrdinaryFolk` |

The framework treats each `{repo}/{principal}` as a distinct context — different role, different permissions, different sandbox. The physical person may be the same, but the addressing system does not assume this.

### Address Resolution

Addresses resolve via local context, not global lookup.

**Local repo identity:** Auto-detected from `git remote -v` (parse origin URL for org and repo name). Override in `agency.yaml` only when auto-detection fails:

```yaml
repo:
  name: monofolk          # override auto-detected name
  org: OrdinaryFolk       # override auto-detected org
```

**Cross-repo resolution:** The `remotes` section maps repo short names to hosting locations for repos that are NOT the current repo's git remotes:

```yaml
remotes:
  monofolk:
    url: https://github.com/OrdinaryFolk/monofolk
```

The transport layer (git push/pull, ISCP) is separate from addressing. Addresses identify; transport delivers. ISCP v1 uses the local filesystem (SQLite DB + git payloads) — cross-machine transport is a future extension.

**Resolution errors:** Unknown repo = hard fail with actionable message. Unknown principal = hard fail. Unknown agent = warn (agent may not be registered yet in a fresh worktree).

### Dispatch & Flag Payload Locations

Addresses resolve to physical locations for dispatch payloads:

| Target type | Address pattern | Dispatch payload location |
|-------------|----------------|--------------------------|
| Agent | `{repo}/{principal}/{agent}` | `usr/{principal}/{project}/dispatches/` |
| Workstream | `{repo}/{workstream}` | `claude/workstreams/{workstream}/dispatches/` |

A **dispatch** is a structured message between agents or from principal to agent. It consists of a notification pointing to a payload file in git at the resolved location above. Dispatch payloads are immutable once written. Named `{type}-{slug}-{YYYYMMDD-HHMM}.md`.

Dispatches are managed by the `dispatch` tool — never created manually. The tool creates both the DB record and the git payload atomically. Dispatch types are validated against an 8-type enum: `directive`, `seed`, `review`, `review-response`, `commit`, `master-updated`, `escalation`, `dispatch`. Integer IDs (from the DB) are used to reference dispatches, not file paths.

A **flag** is a quick-capture observation for later discussion. Flags are DB-only — no git payload, instant capture from any worktree. Agent-addressable: `flag <message>` (self), `flag --to <agent> <message>` (specific agent). Three-state lifecycle: unread → read (on `flag list`) → processed (on `flag discuss` or `flag clear`).

Both dispatch notifications and flags are persisted in a SQLite database at `~/.agency/{repo-name}/iscp.db` (outside git). The DB stores notification metadata and mutable state (read/unread, timestamps). Dispatch payloads remain as immutable markdown files in git. Flags are DB-only (no git payload). See the ISCP reference: `claude/workstreams/iscp/iscp-reference-20260405.md`.

### Commit Messages

Commit message agent prefixes (`housekeeping/captain: ...`) stay bare-form. They are repo-local context and do not need qualification. See Git & Remote Discipline for the full commit message format.

### Future Extensions

- **Shared agents:** A shared agent serves a repo or value stream rather than a specific principal. Addressed as `{repo}/_/{agent}` using the reserved `_` principal name. Not implemented yet.
- **Groups and broadcast:** Role-based addressing (`*/jordan/*`, `monofolk/*/captain`) and broadcast targeting are anticipated but out of scope. The wildcard `*` is not a valid name character, so it can be introduced later without collision.
- **Delegation and ephemeral agents:** When a captain delegates to a worktree agent, the worktree agent is ephemeral — no stable address. Ephemeral agents reply through their captain's address. A derived address form (e.g., `the-agency/jordan/captain:wt-devex`) is anticipated but not implemented.

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

**QGR receipt files:** Each gate produces a standalone receipt at `usr/{{principal}}/{project}/qgr-{boundary}-{phase-iter}-{stage-hash}-YYYYMMDD-HHMM.md`. The stage hash is a deterministic hash of the staged changes (computed by `claude/tools/stage-hash`). `/git-commit` checks for a matching receipt before committing — no receipt means no QG was run.

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

Project artifacts live in `usr/{{principal}}/{project}/` — see the Repo Structure section above for the full directory tree and naming conventions.

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
- The `iscp-check` hook automatically notifies you of unread dispatches on SessionStart — you don't need to merge master to know about them. However, you still need to merge master to access dispatch payload files (the DB notification tells you the file exists; the payload lives on master).
- Never push to origin directly — the captain manages PR branches and pushes.

### When to Create a Worktree

- **New prototype or feature** — always a worktree. Use `/workstream-create` or `/prototype-create`.
- **Bug fix or small change** — can work on master if it's a quick fix that doesn't need isolation.
- **Dispatch handling** — `iscp-check` notifies the worktree agent automatically. The agent runs `dispatch read <id>` to see the payload. If the payload file is on master, merge master first to access it.

## Session Handoff

Handoff files are a first-class Agency primitive for context bootstrapping. They live at `usr/{{principal}}/{project}/handoff.md`, are version controlled, and auto-rotate (each write archives the previous to `history/` with timestamp via `claude/tools/handoff`).

Handoffs are not just session continuity — they bootstrap context for any purpose: agent-to-agent transfer, cold start, project setup, compaction survival, or spinning up a new agent into a desired state. The tool handles infrastructure; the agent writes the content.

**Always use the handoff tool.** Run `bash $CLAUDE_PROJECT_DIR/claude/tools/handoff write --trigger <reason>` to write handoffs. The tool archives the previous handoff to `history/` with a timestamp, resolves the correct path for your project, and ensures consistent formatting. Never write handoff files manually — always use the tool. The `SessionEnd` and `PreCompact` hooks call it automatically, but agents must also call it explicitly at boundary commands and discussion milestones.

**When to write:** At boundary commands (`/iteration-complete`, `/phase-complete`, `/plan-complete`, `/pre-phase-review`), automatically on `PreCompact` and `SessionEnd` hooks, after `/sync-all` (lightweight), and at discussion milestones (PVR draft, key A&D decision, plan revision).

**What to include:** Current phase/iteration status, what was just done, what's next, key decisions or context for a fresh session, open items or blockers.

## ISCP (Inter-Session Communication Protocol)

ISCP is the notification and messaging backbone. Every agent has automatic mail.

### How It Works

The `iscp-check` hook fires on SessionStart, UserPromptSubmit, and Stop. It queries the SQLite DB at `~/.agency/{repo-name}/iscp.db` for unread items addressed to the current agent. Silent when empty (zero tokens). One-line JSON summary when items are waiting.

### Tools

| Tool | What |
|------|------|
| `flag <message>` | Quick-capture to self (DB-only, instant) |
| `flag --to <agent> <message>` | Quick-capture to specific agent |
| `flag list` / `flag discuss` / `flag clear` | Process flags |
| `dispatch create --to <addr> --subject <text>` | Send a dispatch (DB + git payload) |
| `dispatch list` | See dispatches for current agent |
| `dispatch read <id>` | Read payload, mark as read |
| `dispatch resolve <id>` | Mark dispatch resolved |
| `agent-identity` | Resolve "who am I" (repo/principal/agent) |

### When You Have Mail

- **SessionStart:** Process unread items FIRST before other work (hookify enforced)
- **Mid-session:** Act on mail at a natural break, not immediately
- **Dispatch types:** directive (do this), review (fix these), seed (input material), escalation (urgent)

### Reference

Full details: `claude/workstreams/iscp/iscp-reference-20260405.md`

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

### Provenance Headers

Every piece of code — scripts, tools, modules, classes, methods, functions — carries a provenance header. This is how we learn from our own work. The header has two parts:

**What Problem:** What problem are you solving? Not what the code does — what need drove its creation.

**How & Why:** How are you solving it, what led you to this approach, and why you adopted it over alternatives.

```bash
# What Problem: I need to mine session transcripts for patterns, bugs, and
# decisions across multiple projects. This was being done inline by subagents
# every time, costing 20+ tool calls per mining run.
#
# How & Why: Extract user messages from JSONL session files and output as
# readable markdown for agent analysis. Chose grep+jq over full JSON parsing
# because session files are 50MB+ and streaming line-by-line is the only
# approach that doesn't blow memory. Written as a shell script because it
# needs to run in any repo without dependencies.
#
# Written: 2026-04-04 during captain session 18 (ISCP workstream creation)
```

The **What Problem** forces intent articulation. "What it does" is readable from the code. "What problem it solves" is not — and it's the thing that tells a future reader whether this code is still relevant.

The **How & Why** captures the reasoning chain. When someone needs to change this code, they need to know not just what it does but why it does it *this way*. What alternatives were considered? What constraints drove the choice? This is the context that gets lost when code outlives the session that created it.

The **Written** line gives traceability — you can find the session and plan context where the code was born.

**This applies at every level:**

| Scope | Where the header goes |
|-------|----------------------|
| **Script / tool** | Top of file, as comments |
| **Module / package** | Module docstring or header comment |
| **Class** | Class docstring or header comment |
| **Method / function** | Function docstring or header comment (for non-trivial functions) |

For trivial functions (getters, simple transforms, obvious wrappers), the header is overkill. Use judgment — if someone reading the code would ask "why does this exist?", it needs a header.

This is part of **Continual Learning & Improvement** — provenance headers feed transcript mining, telemetry analysis, and pattern discovery. They are the written record of how we think, not just what we build.

### Script Discipline

Every script — whether part of a plan or written ad hoc — must follow two rules:

**1. Provenance header.** Every script starts with a provenance header (What Problem / How & Why / Written — see above).

**2. Persist and reuse.** Scripts live in two places depending on scope:

| Scope | Location | Lifecycle |
|-------|----------|-----------|
| **Framework tool** (plan work, shipped to all projects) | `claude/tools/` | Committed, reviewed, permanent |
| **Agent script** (ad hoc, session work, one-off automation) | `usr/{principal}/{project}/tools/` | Committed, reusable across sessions |
| **Scratch** (truly ephemeral, intermediate output) | `usr/{principal}/{project}/tmp/` | Gitignored, disposable |

**The workflow for ad hoc scripts:**
1. You realize you need a script (parsing, scanning, transforming, testing).
2. Write it to `usr/{principal}/{project}/tools/` with a provenance header.
3. Run it from there.
4. If you need it again later in the session, it's already there — don't rewrite it.
5. If it proves broadly useful, propose moving it to `claude/tools/`.

**Never write the same script twice.** If you wrote it once, it should be in `tools/` and runnable from there. Rewriting the same script multiple times in a session wastes tokens and context window — and signals that the script should have been persisted on first write.

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

Personal config lives in `usr/{{principal}}/` — commands, hookify rules, hooks, settings. Activated by symlinking into `.claude/` — symlinks are gitignored, so activation is local.

- `/sandbox-activate` — symlink a sandbox item to the discovery location
- `/sandbox-try` — try another engineer's experiment
- `/sandbox-adopt` — graduate to shared team-wide tooling

### Hookify Rule Scoping

| Location | Scope | Git Status |
|----------|-------|------------|
| `claude/hookify/` | Framework (shipped rules) | Committed |
| `usr/{{principal}}/claude/hookify/` | Sandbox (per-engineer) | Committed |
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

**If you receive a dispatch:** Run `dispatch list` to see pending dispatches with their integer IDs. Run `dispatch read <id>` to read the payload and mark it as read. Evaluate findings, fix with red→green cycle, append a resolution table, run `/iteration-complete`. When done, `dispatch resolve <id>` marks it resolved. For review dispatches, send a `review-response` dispatch with `--reply-to <id>`. The full dispatch handling protocol is in `claude/docs/CODE-REVIEW-LIFECYCLE.md` — injected when relevant skills run.

**Review files:** `usr/{{principal}}/{project}/code-reviews/{project}-{review|dispatch}-YYYYMMDD-HHMM.md`. Committed to the repo as the audit trail.

---

*AND REMEMBER: OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
