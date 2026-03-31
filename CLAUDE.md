# The Agency

A multi-agent development framework for Claude Code.

## Project Structure

The repo has three distinct hierarchies.

### Framework (shared, cross-principal)

```
claude/
  config/agency.yaml        — principal mapping, project config, provider settings
  agents/{class}/            — agent class definitions (agent.md, KNOWLEDGE.md, ONBOARDING.md)
  docs/                     — reference docs (quality gate, methodology, code review, etc.)
  hooks/                    — Claude Code hooks
  hookify/                  — behavioral rules (shared, team-wide)
  templates/                — scaffolding templates
  starter-packs/            — framework-specific conventions
  tools/                    — Agency framework tools
    lib/                    — sourced helpers (_log-helper, _path-resolve, _provider-resolve)
  workstreams/{workstream}/ — shared workstream artifacts
    KNOWLEDGE.md            — what this workstream is (README)
    seeds/                  — input materials (specs, chatlogs, prompts)
    {workstream}-pvr-YYYYMMDD.md
    {workstream}-ad-YYYYMMDD.md
    {workstream}-plan-YYYYMMDD.md
    {workstream}-ref-YYYYMMDD.md
    reviews/                — QGRs, code/design/test reviews
    history/                — archived artifact versions
```

### Agent instances (per-principal)

```
usr/{principal}/
  claude/                   — personal Claude Code config
    hookify/                — sandbox behavioral rules (per-principal)
  scripts/                  — cross-cutting scripts
  {agent}/                  — one directory per agent instance
    handoff.md
    transcripts/            — discussion transcripts
    history/                — archived handoffs
```

`claude/agents/{class}/` is the **class** — what the role IS (e.g., tech-lead, captain, researcher). `usr/{principal}/{agent}/` is the **instance** — a principal's deployment of that class on a workstream.

### Captain (coordination)

The captain is a special agent. Its instance directory includes dispatches:

```
usr/{principal}/captain/
  handoff.md
  dispatches/               — broadcast directives to other agents
  transcripts/
  history/
```

### Tooling and config

```
.claude/
  commands/                 — slash commands (/discuss, etc.)
  settings.json             — hooks, permissions, plugins
  agents/                   — Claude Code agent registrations ({name}.md)
  worktrees/                — worktree working copies (gitignored)
tests/                      — Test suites (bats for tools, etc.)
source/                     — application source code (optional, organization is workstream's business)
```

### Lifecycle

Seeds go directly to `claude/workstreams/{workstream}/seeds/` — they're input, not sandbox work. During discussion, the agent works in `usr/{principal}/{agent}/` (transcripts, handoffs). When implementation launches, PVR, A&D, and Plan move to `claude/workstreams/{workstream}/` where they become shared artifacts. Artifact versioning is tooling-enforced.

**IMPORTANT:** `claude/principals/` is the LEGACY (v1) location. Do NOT file new work there.

## Tools

Agency framework tools live in `claude/tools/` (shipped via `agency-init`). Sourced helpers live in `claude/tools/lib/`.

All tools are token-conserving wrappers — minimal stdout to context, verbose to `.claude/logs/tool-runs.jsonl`. Run with `./claude/tools/<name>`.

### Framework Setup
`agency-init`, `agency-update`, `terminal-setup`

### Scaffolding
`principal-create`, `agent-create`, `agent-define`, `workstream-create`, `worktree-create`, `worktree-list`, `worktree-delete`

### Git
`git-commit`, `git-tag`, `git-sync`, `git-fetch`

### Quality
`test-run`, `commit-precheck`, `code-review`, `review-spawn`

### Secrets (pluggable)
`secret-vault` (bundled default), `secret-doppler`. `/secret` skill dispatches to configured provider.

### GitHub
`gh`, `gh-pr`, `gh-release`, `gh-api`

### Context
Handoff is a first-class Agency primitive. Hook-driven (SessionStart, SessionEnd, PreCompact) + manual. Not just session continuity — it's how you inject context into any session for any reason: agent-to-agent, cold start, project setup, compaction survival.

### Utilities
`agency-whoami`, `tool-find`, `tool-create`, `now`, `dependencies-check`, `dependencies-install`, `telemetry`, `handoff`

### Plugin Provider Pattern

External service integrations follow a pluggable model: a dispatcher reads config from `agency.yaml` and delegates to a `{noun}-{provider}` tool. Bundled defaults ship with every installation.

```yaml
# agency.yaml
secrets:
  provider: vault
terminal:
  provider: ghostty
platform:
  provider: macos
```

## Tool Output Standard

All tools emit minimal stdout to conserve context. Tools live in `claude/tools/`.

```
{tool-name} [run: {run-id}]
{essential-result}
✓
```

Verbose output goes to `.claude/logs/tool-runs.jsonl`. Investigate with: `./claude/tools/telemetry --recent`

## Agents

### Agent Classes

Agent classes define roles. They live in `claude/agents/{class}/agent.md`.

| Class | Purpose | Default Usage |
|-------|---------|---------------|
| captain | Coordination, dispatch, PR lifecycle | Standing agent |
| cos | Cross-repo coordination | Standing agent (optional) |
| project-manager | Quality gates, QGR protocol | Standing agent |
| tech-lead | Product work: define, design, implement | Standing per workstream |
| marketing-lead | GTM strategy, positioning, launch | Standing per workstream |
| platform-specialist | Platform operations, integrations | Standing per platform |
| researcher | Deep research, synthesis | Subagent |
| reviewer-code | Code review | Subagent |
| reviewer-design | Design review | Subagent |
| reviewer-security | Security review | Subagent |
| reviewer-test | Test review | Subagent |
| reviewer-scorer | Confidence scoring | Subagent |

### Agent Registration

Agents are defined in two places:
- **Class definition:** `claude/agents/{class}/agent.md` — role, responsibilities, knowledge
- **Claude Code registration:** `.claude/agents/{name}.md` — frontmatter + bootstrap prompt pointing to class + workstream

`agent-define` creates a new class (planned — not yet built). `agent-create` creates an instance and writes the `.claude/agents/{name}.md` registration file.

Launch agents with: `claude --agent {name} --name {name}`

### Registration Format

`.claude/agents/{name}.md` frontmatter + bootstrap:

```yaml
---
name: markdown-pal
description: "Define, design, and build Markdown Pal"
model: opus
---

Read your role and responsibilities from `claude/agents/tech-lead/agent.md`.
Read your project knowledge from `claude/workstreams/markdown-pal/KNOWLEDGE.md`.
Read seed materials from `claude/workstreams/markdown-pal/seeds/`.
```

The registration points to the **class** (role definition) and **workstream** (project knowledge). The class defines behavior; the workstream provides context.

## The Work Pattern

Discuss > Plan Mode (explore + design) > Review Plan > Revise > Review > Finalize > Implement. "Plan Mode" is Claude Code's planning feature — read-only exploration and design before writing code.

## Development Methodology

Documented in detail at `claude/docs/DEVELOPMENT-METHODOLOGY.md`. Injected automatically when relevant skills are invoked.

### The Flow

```
Seed > Discussion (1B1) > PVR (evolving) > A&D (evolving) > Plan (phases x iterations)
```

1. **Seed** — a starting point (document, idea, spec). Goes to `claude/workstreams/{workstream}/seeds/`.
2. **Discussion** — using the 1B1 protocol. Explore requirements, constraints, trade-offs. No jumping to implementation.
3. **PVR (Product Vision & Requirements)** — the what and why. Evolves through implementation.
4. **A&D (Architecture & Design)** — the how and why. Technical decisions, patterns, system design.
5. **Plan** — phases comprised of iterations. Updated after every commit.

### Skills for Definition and Design

- `/discuss` — the 1B1 protocol. Structured conversation on any topic. Always produces a transcript.
- `/define` — drives toward a complete PVR with a completeness checklist. Uses `/discuss` internally.
- `/design` — drives toward a complete A&D with a completeness checklist. Uses `/discuss` internally.

`/discuss` is the interaction protocol. `/define` and `/design` bring the agenda — they know what topics to cover and what "done" looks like.

### Execution

- **Phases** are whole numbers: Phase 1, Phase 2, Phase 3.
- **Iterations** are Phase.Iteration: 1.1, 1.2, 2.1. No letters — only numbers.
- **Every phase and iteration carries a slug** (e.g., "Phase 2: Provider Abstraction"). Renumber freely — the slug is the stable identifier.
- Commit at iteration and phase boundaries.

### Artifacts

| Artifact | Abbrev | Content | Lifecycle |
|----------|--------|---------|-----------|
| Product Vision & Requirements | PVR | What and why | Evolves through discussion + implementation |
| Architecture & Design | A&D | How and why (technical) | Evolves through implementation |
| Plan | Plan | Phases, iterations, boundary transitions | Updated after every commit |
| Quality Gate Reports | QGR | Tables + summary | Separate files in workstream reviews/ |
| Reference | Ref | Final documentation | Produced at plan completion |

QGRs are **separate from the Plan**. The Plan documents boundary transitions (phase complete, committed, date). The QGR is the receipt filed in `reviews/`.

### Living Documents

PVR, A&D, and Plan evolve together during active work. Update architecture decisions as you learn — don't wait until the end.

## Quality Gate (QG)

Quality gates run at every commit boundary. The PM agent (`project-manager`) owns the full protocol — see `claude/docs/QUALITY-GATE.md`.

**Code review** follows the lifecycle at `claude/docs/CODE-REVIEW-LIFECYCLE.md`. The captain manages code review dispatch. Three review scopes: iteration (scoped QG), phase (deep QG, full codebase), and PR prep (everything).

## Discussion Protocol (1B1)

**Applies to ALL multi-item work** — not just `/discuss` sessions. When there are multiple issues, bugs, tasks, or items: work one at a time. This is non-negotiable.

- **Break the list into discrete threads.** Address each item one at a time, not all at once.
- **Resolve each item before moving to the next.** Don't mix concerns across items.
- **Number the items explicitly** so the user can reference them by number.
- **Capture decisions as they're made** — don't wait until the end to summarize.

Inner loop: Present > Get Feedback > Confirm Understanding (reflective listening) > Revise > Iterate > Resolve > Confirm Resolution > Next Item.

**During /discuss:** Write to both the PVR and the transcript after each item resolves. Do not batch artifact writes to the end. Transcripts are separate files in `usr/{principal}/{agent}/transcripts/`.

## Agent Startup Protocol

Before any discussion or artifact work:
1. Read `handoff.md` for your project/role
2. Check for new `dispatch-*.md` files in your scope (directives from other agents)
3. Check for new `guide-*.md` files — these are instructions written for the principal (human), but reading them gives you context on what the principal is working on
4. If you are a workstream agent: enter your worktree (create one if needed) BEFORE starting `/discuss` or writing files
5. If a skill invocation is interrupted (e.g., redirected to a worktree), re-invoke the skill from the new context — do not manually replicate its output

## Handoff Discipline

Handoffs are a first-class Agency primitive — not just session continuity, but context bootstrapping for any purpose.

Write a handoff at EVERY session boundary — this is a blocker, not a suggestion. Handoffs live at `usr/{principal}/{agent}/handoff.md` (or `usr/{principal}/captain/handoff.md` for the captain). Each write archives the previous version to `history/`.

Triggers: SessionEnd, PreCompact, iteration-complete, phase-complete, plan-complete.

## Git & Remote Discipline

- **Remote main is read-only.** All changes reach remote through PRs. No exceptions.
- **Never commit directly to main.** Create a branch, PR it, get it merged.
- **Never push to any remote without explicit permission.** Pushing is always deliberate.
- **Never `reset --hard` without confirming work is preserved.** A diverged branch may have new commits.
- Use `./claude/tools/git-commit` — never bare `git commit`.
- Lead commit messages with Phase-Iteration slug when in a plan: `Phase 1.3: feat: summary`.
- **Fix, don't ask.** When you find bugs or quality problems, fix them. Findings are the work order.
- **Read, don't guess.** Read actual documentation before guessing at APIs, flags, or schemas.

## Naming Conventions

- Agent classes: lowercase, hyphenated (`tech-lead`, `platform-specialist`)
- Agent instances: lowercase, hyphenated (`markdown-pal`, `mock-and-mark`)
- Workstreams: lowercase (`markdown-pal`, `gtm`)
- Tools: noun-verb convention (`agent-create`, `tool-find`, `git-commit`, `git-tag`, `git-sync`).
- Tool providers: `{noun}-{provider}` (`secret-doppler`, `secret-vault`)
- Files: `{project}-{artifact}-YYYYMMDD.md`
- Guides: `guide-{project}-{slug}-YYYYMMDD.md` (for principals/humans, not agents)
- Dispatches: `dispatch-{slug}-YYYYMMDD.md` (broadcast directives)
- API endpoints: explicit operations (`POST /api/resource/create` not `POST /api/resource`)

## Worktrees

Worktrees enable parallel agent sessions. Created at `.claude/worktrees/{name}/`.

```bash
./claude/tools/worktree-create {name}    # Create (installs deps, custom branch name)
./claude/tools/worktree-list             # Status (clean/dirty, branch, HEAD)
./claude/tools/worktree-delete {name}    # Remove (checks for uncommitted work)
```

**Do NOT use Claude Code's built-in `EnterWorktree`.** It creates `worktree-`-prefixed branches, installs no dependencies, and may auto-delete worktrees with your work. Use the Agency tools instead.

## Secrets

Pluggable provider model. Default: `secret-vault` (bundled, zero external deps).

```yaml
# agency.yaml
secrets:
  provider: vault    # or: doppler, aws, 1password
```

The `/secret` skill is the interactive front-end (set, get, list, delete, rotate, scan). `secrets-scan` integrates into the quality gate at iteration/phase/PR boundaries.

## Web Content Retrieval

When you need to fetch web content, follow this escalation ladder:

1. **WebFetch** — try first. Fast, cheap, no browser needed. Fails on JS-heavy sites and bot detection.
2. **Playwright MCP snapshot** — if WebFetch fails or returns garbage. Renders JS, returns structured accessibility tree. Use `browser_snapshot` over `browser_take_screenshot` for text content (structured, token-efficient).
3. **Playwright MCP screenshot** — when visual context is needed (layout, design, errors).
4. **Playwright MCP run_code** — for extracting specific content from large pages (`page.$('article').innerText()`).

**For sites that block unauthenticated access (X/Twitter, LinkedIn):**
- Use Nitter mirrors (e.g., `nitter.poast.org/{user}/status/{id}`) for X/Twitter — no login required, full thread visible.
- If Nitter fails, navigate with Playwright MCP to the real site (may require the principal to log in first).

**Principles:**
- Extract what you need, don't dump the whole page into context.
- Summarize content, don't paste raw HTML.
- For threads/articles, capture the full content then produce a structured summary.
- Don't try WebFetch once and give up — escalate through the ladder.

## Testing & Quality

**We fix things. We don't work around them. There are no small bugs — just fix it.**

- No unactionable noise — every warning triggers action or gets fixed at the source.
- Fix what you find — don't defer nits. The cost now is low.
- No silent failures — fail loudly or handle explicitly.
- Verify, don't assume — read the docs, check the data, debug with evidence.
- Enforce conventions mechanically — hooks and rules, not prose.
- No stale artifacts — dead code, unused config, orphaned files — delete or update them.
- Re-read files after lint/format runs. Always read before write.
- Never suppress failures. The blocker IS the work.
- Never propose `--no-verify`, `eslint-disable`, `@ts-ignore`, or "we can fix this later."
- Consult before acting on failures. Diagnose first, propose a fix second, act only with approval.

## Bash Tool Usage

Single, simple commands — no `&&`, `||`, `;`, pipes, subshells, or `$(...)` substitutions. Use separate Bash tool calls (parallel when independent, sequential when dependent). Use dedicated tools: Grep not grep, Glob not find, Read not cat, Write not echo, Edit not sed.

## Sandbox Principle

**Everything sandboxed. Zero impact to the team. Completely opt-in.**

- All personal work lives in `usr/{principal}/`
- Framework tools live in `claude/tools/` — there if you want them
- Nothing forces changes on other team members
- Symlinks activate sandbox items — local, never committed

### Hookify Rules

| Location | Scope | Git Status |
|----------|-------|------------|
| `claude/hookify/` | Shared (team-wide) | Committed |
| `usr/{principal}/claude/hookify/` | Sandbox (per-principal) | Committed |
| `.claude/hookify.foo.user.local.md` | Personal (user-only) | Gitignored |

## What NOT to Do

- Don't file work in `claude/principals/` — use `usr/{principal}/`
- Don't commit or push directly to main — use PR branches
- Don't skip quality gates — even for doc-only changes
- Don't use bare `git commit` — use `./claude/tools/git-commit`
- Don't use Claude Code's `EnterWorktree` — use `./claude/tools/worktree-create`
- Don't give generic greetings — lead with handoff context
- Don't guess at APIs or flags — read the docs first
- Don't address multiple items at once — use 1B1 protocol
- Don't manually replicate a skill's output — invoke the skill
- After editing JSON files, verify the result is valid JSON
