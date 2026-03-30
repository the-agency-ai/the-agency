# CLAUDE.md v2 DRAFT — For Review

**Status:** DRAFT — do not deploy until reviewed by Jordan and the-agency captain
**Date:** 2026-03-29
**From:** CoS (monofolk session)

---

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
    agents/              — Claude Code agent definitions
  tools/                 — CLI tools (106+). Run with ./tools/<name>
  usr/{principal}/       — per-principal sandbox (v2)
  source/                — application source code
```

## Tools

**Session:** `myclaude`, `welcomeback`, `session-backup`
**Scaffolding:** `workstream-create`, `agent-create`, `worktree-create`, `worktree-list`, `worktree-delete`
**Messaging:** `msg` (send, broadcast, read, thread, ack)
**Dispatch:** `dispatch` (enqueue, claim, complete, fail, status), `dispatch-request`
**Quality:** `commit-precheck`, `test-run`, `code-review`, `review-spawn`
**Git:** `commit`, `tag`, `sync`
**Secrets:** `secret-vault` (vault), `secret-doppler` (Doppler)
**GitHub:** `gh`, `gh-pr`, `gh-release`, `gh-api`
**Terminal:** `ghostty-setup`, `tab-status`

All tools are in `./tools/`. Run with `./tools/<name>`.

## Tool Output Standard

All `./tools/*` emit minimal stdout to conserve context:

```
{tool-name} [run: {run-id}]
{essential-result}
✓
```

Verbose output goes to the log service. Investigate with: `./tools/agency-service log run {run-id}`

## Development Methodology

The methodology is documented in detail at `claude/docs/DEVELOPMENT-METHODOLOGY.md`. Injected automatically when relevant skills are invoked.

**The flow:** Seed → Discussion (1B1) → PVR → A&D → Plan (phases × iterations)

**Execution:** Phases are whole numbers. Iterations are Phase.Iteration (1.1, 1.2). Every phase carries a slug. Commit at iteration boundaries, phase boundaries. No letters — only numbers.

**Quality gates** run at every commit boundary. The PM agent owns the protocol — see `claude/docs/QUALITY-GATE.md`.

**Code review** follows the lifecycle at `claude/docs/CODE-REVIEW-LIFECYCLE.md`.

## File Organization

**Principal directories (v2):** All personal work lives in `usr/{principal}/`. Each principal has their own sandbox.

```
usr/{principal}/
  claude/          — personal Claude Code config
  scripts/         — cross-cutting scripts
  captain/         — captain coordination
  {project}/       — one directory per project
    handoff.md
    {project}-pvr-YYYYMMDD.md
    {project}-architecture-YYYYMMDD.md
    {project}-plan-YYYYMMDD.md
    transcripts/
    code-reviews/
    history/
```

**Note:** `claude/principals/` is the legacy (v1) location. New work goes in `usr/{principal}/`.

## Discussion Protocol (1B1)

When presenting multiple items: one at a time. Break into discrete threads. Resolve each before moving on. Number explicitly. Use `/discuss` for structured sessions.

Inner loop: Present → Get Feedback → Confirm Understanding → Revise → Iterate → Resolve → Confirm Resolution → Next Item.

## Conventions

### Git Commits

Use `./tools/commit`:
```bash
./tools/commit "summary" --work-item REQUEST-jordan-0065 --stage impl
```

### Naming
- Agents: lowercase, hyphenated (`markdown-pal`, `mock-and-mark`)
- Workstreams: lowercase (`markdown-pal`, `gtm`)
- Files: `{project}-{artifact}-YYYYMMDD.md`
- Guides: `guide-{project}-{slug}-YYYYMMDD.md`
- Dispatches: `dispatch-{slug}-YYYYMMDD.md`

### API Design
Explicit operation names. `POST /api/resource/create` not `POST /api/resource`.

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

## Git Discipline

- Remote master is read-only. All changes through PRs.
- Never push without explicit permission.
- PR branches, not direct to main.
- Fix, don't ask. Read, don't guess.

## Hookify Rules

15 behavioral rules in `claude/hookify/`. Enforced via the hookify plugin.

## What NOT to Do

- Don't file work in `claude/principals/` — use `usr/{principal}/`
- Don't push directly to main — use PR branches
- Don't skip quality gates — even for doc-only changes
- Don't use bare `git commit` — use `./tools/commit`
