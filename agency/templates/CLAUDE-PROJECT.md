# {{PROJECT_NAME}}

> **First time here?** Run `/agency-welcome` for a guided tour of The Agency, or read `agency/README-GETTINGSTARTED.md` for the manual setup.

## About this repo

<!-- REPLACE THIS BLOCK: one-paragraph description of what {{PROJECT_NAME}} is,
     who uses it, and what problem it solves. This is the first context every
     agent sees — keep it crisp and load-bearing. -->

- **Principal:** {{PRINCIPAL}}
- **Project:** {{PROJECT_NAME}}

## This Repo

<!-- Fill these in based on your repo layout. Delete sections that don't apply. -->

- **Source code:** <!-- e.g., src/, apps/, packages/ -->
- **Tests:** <!-- e.g., tests/, __tests__/, src/tests/ -->
- **Docs:** <!-- e.g., docs/, agency/workstreams/{{PROJECT_NAME}}/research/ -->
- **Workstreams:** `agency/workstreams/{{PROJECT_NAME}}/` — shared project artifacts (PVR/A&D/Plan/KNOWLEDGE)
- **Principal sandbox:** `usr/{{PRINCIPAL}}/` — handoffs, dispatches, transcripts

## Testing

<!-- Replace with the test commands / conventions for this project.
     Examples:
       npm test           # vitest
       pnpm test          # workspaces
       bats src/tests/    # bats for bash tools
       uv run pytest      # python
-->

## Repo-Specific Conventions

<!-- Language, framework, linting, formatting, commit style, etc.
     What must agents know to contribute correctly? -->

## Agent Classes

Default agent classes available via `/agent-create` and Claude Code subagent auto-discovery (`.claude/agents/{{PRINCIPAL}}/`):

- **captain** — coordination, dispatch routing, quality gates, PR lifecycle

Additional classes available in `agency/agents/` (tech-lead, reviewer-code, reviewer-security, reviewer-design, reviewer-test, reviewer-scorer, designex, devex, iscp, etc.). Register with `./agency/tools/agent-create <name> <workstream>` as needed.

## Methodology

@agency/CLAUDE-THEAGENCY.md
