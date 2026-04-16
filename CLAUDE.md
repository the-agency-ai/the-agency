# The Agency

This is the **framework development repo** — TheAgency itself. You are building the tools, methodology, agent classes, and skills that `agency init` ships to other projects.

## This Repo

- **Framework code:** `claude/` (tools, agents, docs, hooks, skills, templates)
- **App workstreams:** `apps/` (mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark — Reference Source License)
- **Shared workstream content:** `claude/workstreams/{W}/` (PVRs, A&Ds, plans, seeds, receipts, transcripts)
- **Principal sandboxes:** `usr/{P}/{A}/` (personal state: handoffs, tools, history)
- **Agent registrations:** `.claude/agents/{P}/{A}.md` (principal-scoped, invoke with `claude --agent {P}/{A}`)

## Content Placement

See `claude/REFERENCE-WORKSTREAM-CONTENT-SPLIT.md` for where artifacts belong (shared vs personal).

## Licensing

Open core model:
- **Framework** (everything except app workstreams) — MIT License (`LICENSE`)
- **App workstreams** (mdpal, mock-and-mark) — Reference Source License (per-directory `LICENSE`)

## Testing

- BATS for tool tests: `bats tests/tools/`
- BATS for schemas: `bats tests/schemas/`

## Repo-Specific Conventions

- Tools live in `claude/tools/` — bash wrappers with `_log-helper` integration
- Skills live in `.claude/skills/{name}/SKILL.md` — auto-discovered by Claude Code
- Commands live in `.claude/commands/{name}.md` — user-invoked via `/{name}`
- Agent classes live in `claude/agents/{class}/agent.md`
- Agent registrations live in `.claude/agents/{P}/{A}.md` (principal-scoped)

@claude/CLAUDE-THEAGENCY.md
