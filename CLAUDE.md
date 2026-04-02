# The Agency

This is the **framework development repo** — TheAgency itself. You are building the tools, methodology, agent classes, and skills that `agency init` ships to other projects.

## This Repo

- **Framework code:** `claude/` (tools, agents, docs, hooks, skills, templates, starter packs)
- **App workstreams:** `claude/workstreams/mdpal/`, `claude/workstreams/mock-and-mark/` (Reference Source License)
- **Test fixtures:** `test/test-agency-project/` (embedded git repo — commit inside it separately)
- **Principal sandbox:** `usr/jordan/` (captain instance, dispatches, transcripts)

## Licensing

Open core model:
- **Framework** (everything except app workstreams) — MIT License (`LICENSE`)
- **App workstreams** (mdpal, mock-and-mark) — Reference Source License (per-directory `LICENSE`)

## Testing

- BATS for tool tests: `bats tests/tools/`
- Vitest for TypeScript: `npx vitest run`
- Test fixtures are embedded git repos with their own `.git/` — changes inside them require commits inside the fixture, then a submodule-reference update in the outer repo

## Repo-Specific Conventions

- Tools live in `claude/tools/` — bash wrappers with `_log-helper` integration
- Skills live in `.claude/skills/{name}/SKILL.md` — auto-discovered by Claude Code
- Commands live in `.claude/commands/{name}.md` — user-invoked via `/{name}`
- Agent classes live in `claude/agents/{class}/agent.md`
- Agent registrations live in `.claude/agents/{name}.md`

@claude/CLAUDE-THEAGENCY.md
