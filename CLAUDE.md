# The Agency

A multi-agent development framework for Claude Code.

## Project Structure

```
the-agency/
  CLAUDE.md              — you are here
  claude/
    config/agency.yaml   — principal mapping, project config
    agents/              — agent identities and knowledge
    docs/                — reference docs (quality gate, methodology, code review, etc.)
    hooks/               — Claude Code hooks (ref-injector, session-handoff, etc.)
    hookify/             — behavioral rules (15 rules)
    templates/           — scaffolding templates
    starter-packs/       — framework-specific conventions
    workstreams/         — workstream knowledge
  .claude/
    commands/            — slash commands (/discuss, etc.)
    settings.json        — hooks, permissions, plugins
    agents/              — Claude Code agent definitions (name.md)
    worktrees/           — worktree working copies (gitignored)
  tools/                 — CLI tools (106+). Run with ./tools/<name>
  usr/{principal}/       — per-principal sandbox
  source/                — application source code
```

## File Organization

All project work lives in `usr/{principal}/`. Each agent or workstream gets its own directory.

```
usr/{principal}/
  claude/              — personal Claude Code config
  scripts/             — cross-cutting scripts
  captain/             — captain coordination (handoffs, guides, dispatches)
  {agent|workstream}/  — one directory per agent or workstream
    handoff.md
    {project}-pvr-YYYYMMDD.md
    {project}-architecture-YYYYMMDD.md
    {project}-plan-YYYYMMDD.md
    transcripts/       — discussion transcripts (written progressively during /discuss)
    code-reviews/      — review artifacts
    history/           — archived artifacts
```

`claude/workstreams/` holds shared workstream KNOWLEDGE.md files. All other work goes in `usr/`.

**IMPORTANT:** `claude/principals/` is the LEGACY (v1) location. Do NOT file new work there. All new work goes in `usr/{principal}/`.

## Tools

**Session:** `myclaude`, `welcomeback`, `session-backup`
**Scaffolding:** `workstream-create`, `agent-create`, `worktree-create`, `worktree-list`, `worktree-delete`
**Messaging:** `msg` (send, broadcast, read, thread, ack)
**Dispatch:** `dispatch` (enqueue, claim, complete, fail, status), `dispatch-request`
**Quality:** `commit-precheck`, `test-run`, `code-review`, `review-spawn`
**Git:** `commit`, `tag`, `sync`
**Secrets:** `secret-vault` (vault), `secret-doppler` (Doppler)
**GitHub:** `gh`, `gh-pr`, `gh-release`, `gh-api`
**Terminal:** `ghostty-setup`

All tools are in `./tools/`. Run with `./tools/<name>`.

## Tool Output Standard

All `./tools/*` emit minimal stdout to conserve context:

```
{tool-name} [run: {run-id}]
{essential-result}
✓
```

Verbose output goes to the log service. Investigate with: `./tools/agency-service log run {run-id}`

## Agents

Agents are defined in two places:
- **Agency identity:** `claude/agents/{name}/agent.md` — role, responsibilities, knowledge
- **Claude Code registration:** `.claude/agents/{name}.md` — frontmatter + bootstrap prompt

Launch agents with: `claude --agent {name} --name {name}`

The `./tools/agent-create` tool creates both files automatically.

## Development Methodology

The methodology is documented in detail at `claude/docs/DEVELOPMENT-METHODOLOGY.md`. Injected automatically when relevant skills are invoked.

**The flow:** Seed > Discussion (1B1) > PVR > A&D > Plan (phases x iterations)

**Execution:** Phases are whole numbers. Iterations are Phase.Iteration (1.1, 1.2). Every phase carries a slug. Commit at iteration boundaries, phase boundaries. No letters — only numbers.

**Quality gates** run at every commit boundary. The PM agent owns the protocol — see `claude/docs/QUALITY-GATE.md`.

**Code review** follows the lifecycle at `claude/docs/CODE-REVIEW-LIFECYCLE.md`.

## Discussion Protocol (1B1)

**Applies to ALL multi-item work** — not just `/discuss` sessions. When there are multiple issues, bugs, tasks, or items: work one at a time. This is non-negotiable.

One at a time. Break into discrete threads. Resolve each before moving on. Number explicitly. Use `/discuss` for structured sessions.

Inner loop: Present > Get Feedback > Confirm Understanding > Revise > Iterate > Resolve > Confirm Resolution > Next Item.

**During /discuss:** Write to both the PVR and the transcript after each item resolves. Do not batch artifact writes to the end. Transcripts are separate files in `usr/{principal}/{project}/transcripts/`.

## Agent Startup Protocol

Before any discussion or artifact work:
1. Read `handoff.md` for your project/role
2. Check for new `guide-*.md` and `dispatch-*.md` files in your scope
3. If you are a workstream agent: enter your worktree (create one if needed) BEFORE starting `/discuss` or writing files
4. If a skill invocation is interrupted (e.g., redirected to a worktree), re-invoke the skill from the new context — do not manually replicate its output

## Handoff Discipline

Write a handoff at EVERY session boundary — this is a blocker, not a suggestion. Handoffs live at `usr/{principal}/{project}/handoff.md` (or `usr/{principal}/captain/handoff.md` for the captain). Each write archives the previous version to `history/`.

## Conventions

### Git

- **Remote main is read-only.** All changes reach remote through PRs. No exceptions.
- **Never commit directly to main.** Create a branch, PR it, get it merged.
- **Never push to any remote without explicit permission.**
- Use `./tools/commit` for commits:
  ```bash
  ./tools/commit "summary" --work-item REQUEST-jordan-0065 --stage impl
  ```
- Lead commit messages with Phase-Iteration slug when in a plan: `Phase 1.3: feat: summary`

### Naming

- Agents: lowercase, hyphenated (`markdown-pal`, `mock-and-mark`)
- Workstreams: lowercase (`markdown-pal`, `gtm`)
- Files: `{project}-{artifact}-YYYYMMDD.md`
- Guides: `guide-{project}-{slug}-YYYYMMDD.md` (for principals/humans, not agents)
- Dispatches: `dispatch-{slug}-YYYYMMDD.md` (for agent-to-agent communication)

### API Design

Explicit operation names. `POST /api/resource/create` not `POST /api/resource`.

## Worktrees

Worktrees enable parallel agent sessions. Created at `.claude/worktrees/{name}/`.

```bash
./tools/worktree-create {name}              # Create
./tools/worktree-list                       # Status
./tools/worktree-delete {name}              # Remove
```

Claude Code's built-in `EnterWorktree` tool also uses `.claude/worktrees/`.

## Secrets

Use `./tools/secret-vault` (default) or `./tools/secret-doppler` (if configured).

```bash
./tools/secret-vault get secret-name
./tools/secret-vault create my-secret --type=api_key --service=GitHub
```

See `claude/docs/SECRETS.md` for full reference.

## Session Context

Save context throughout sessions with `./tools/context-save`. Restored automatically on session start. Lead with restored context — don't give generic greetings.

## Testing & Quality

**Fix what you find. No broken windows. No unactionable noise.**

- Every warning triggers action or gets fixed at the source.
- Never suppress failures. The blocker IS the work.
- Never propose `--no-verify` or "we can fix this later."
- Verify, don't assume — read docs, check data, debug with evidence.

## Bash Tool Usage

Single, simple commands — no `&&`, `||`, `;`, pipes, subshells. Use separate Bash tool calls. Use dedicated tools: Grep not grep, Glob not find, Read not cat, Write not echo, Edit not sed.

## What NOT to Do

- Don't file work in `claude/principals/` — use `usr/{principal}/`
- Don't write artifacts to `claude/workstreams/` — project work goes in `usr/{principal}/{workstream}/`
- Don't commit or push directly to main — use PR branches
- Don't skip quality gates — even for doc-only changes
- Don't use bare `git commit` — use `./tools/commit`
- Don't give generic greetings — lead with session context
- Don't guess at APIs or flags — read the docs first
- Don't address multiple items at once — use 1B1 protocol
- Don't manually replicate a skill's output — invoke the skill
- After editing JSON files, verify the result is valid JSON
