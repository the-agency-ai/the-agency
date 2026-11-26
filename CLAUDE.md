# The Agency

This is the **framework development repo** — TheAgency itself. You are building the tools, methodology, agent classes, and skills that `agency init` ships to other projects.

## This Repo

- **Framework code:** `claude/` (tools, agents, docs, hooks, skills, templates, starter packs)
- **App workstreams:** `agency/workstreams/mdpal/`, `agency/workstreams/mock-and-mark/` (Reference Source License)
- **Test fixtures:** `test/test-agency-project/` (embedded git repo — commit inside it separately)
- **Principal sandbox:** `usr/jordan/` (captain instance, dispatches, transcripts)

## Design Directions

Forward-looking constraints that shape new framework work. These are *directions*, not yet-built requirements — every design decision from here should honor them, or consciously note when it can't and why.

**These targets rest on how Claude Code, Claude Cloud, and the Slack tag actually behave — which we will research over time. Verify what the platform does before designing against it; do not assume.**

- **Claude Cloud as a supported runtime.** the-agency should be able to run in Claude Cloud — including being driven by **@claude tags in Slack** — as an *option*, not a replacement. The local captain/fleet model stays primary. What that runtime supports (filesystem persistence, auth, background processes, hooks, git) is an open research question; keep the target in view as we build and confirm the constraints as we learn them.
- **Distribute as Claude Code plugin(s).** Package the framework as one or more plugins to ease installation, augmenting today's `agency init` file-copy. What a plugin can actually bundle and how it's installed is likewise a research question; structure new work to stay plugin-friendly as we learn the real capabilities.
- **Containerization — parked.** The container test-isolation arc (#42) is on the shelf; revisit later. Scoping brief: `usr/jordan/captain/briefings/ci-container-wire-in-scoping-20260903.md`.

## Licensing

Open core model:
- **Framework** (everything except app workstreams) — MIT License (`LICENSE`)
- **App workstreams** (mdpal, mock-and-mark) — Reference Source License (per-directory `LICENSE`)

## Testing

- BATS for tool tests: `bats src/tests/tools/`
- ISCP tools: `bats src/tests/tools/iscp-db.bats src/tests/tools/agent-identity.bats src/tests/tools/dispatch-create.bats src/tests/tools/dispatch.bats src/tests/tools/flag.bats src/tests/tools/iscp-check.bats src/tests/tools/iscp-migrate.bats` (142 tests)
- Vitest for TypeScript: `npx vitest run`
- Test fixtures are embedded git repos with their own `.git/` — changes inside them require commits inside the fixture, then a submodule-reference update in the outer repo

## Repo-Specific Conventions

- Tools live in `agency/tools/` — bash wrappers with `_log-helper` integration
- Skills live in `.claude/skills/{name}/SKILL.md` — auto-discovered by Claude Code
- Commands live in `.claude/commands/{name}.md` — user-invoked via `/{name}`
- Agent classes live in `agency/agents/{class}/agent.md`
- Agent registrations live in `.claude/agents/{name}.md`

@agency/CLAUDE-THEAGENCY.md
