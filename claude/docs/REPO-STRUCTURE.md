# What Problem: The CLAUDE-THEAGENCY.md bootloader is too large for efficient
# context injection. The repo structure section needs to be extractable as a
# standalone reference doc that skills and hooks can inject on demand, rather
# than requiring the full bootloader.
#
# How & Why: Extracted verbatim from CLAUDE-THEAGENCY.md lines 6-97 (the
# "TheAgency Repo Structure" section including Scoped CLAUDE.md Files). This
# keeps the canonical content in one place while allowing targeted injection.
#
# Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring)

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
  hooks/                   — session hooks (ref-injector for skills; project-local hooks added per project)
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
    collaboration          — cross-repo dispatch lifecycle (captain only)
  templates/               — scaffolding templates
  workstreams/             — bodies of work
    {workstream}/
      CLAUDE-{WORKSTREAM}.md — workstream-scoped instructions
      KNOWLEDGE.md         — patterns, conventions, key decisions
      seeds/               — input materials
      dispatches/          — workstream-targeted dispatches
      reviews/             — QGRs and review files
      history/             — archived artifact versions
  starter-packs/           — starter kit templates for agency init
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
