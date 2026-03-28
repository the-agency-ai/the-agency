# Principal: {{PRINCIPAL_NAME}}

Welcome to The Agency. This is your sandbox — everything here is yours.

## Directory Structure

```
usr/{{PRINCIPAL_NAME}}/
  claude/              — Your Claude Code config
    CLAUDE.md          — Personal instructions (symlink to ~/.claude/CLAUDE.md)
    commands/          — Custom slash commands
    hookify/           — Behavioral rules (*.local.md)
    hooks/             — Shell hooks
    agents/            — Agent definitions
    refs/              — Reference documents (injected on-demand)
  scripts/             — Cross-cutting scripts
  {project}/           — One directory per project
    handoff.md         — Current session handoff
    {project}-pvr-YYYYMMDD.md
    {project}-architecture-YYYYMMDD.md
    {project}-plan-YYYYMMDD.md
    transcripts/       — Discussion records
    code-reviews/      — Review dispatch files
    history/           — Archived artifacts
```

## Creating a Project

Create a directory under `usr/{{PRINCIPAL_NAME}}/` for each project:

```bash
mkdir -p usr/{{PRINCIPAL_NAME}}/my-project/{transcripts,code-reviews,history}
```

## File Naming Convention

All project artifacts follow: `{project}-{artifact}-YYYYMMDD.md`

- `my-project-pvr-20260329.md` — Product Vision & Requirements
- `my-project-architecture-20260329.md` — Architecture & Design
- `my-project-plan-20260329.md` — Implementation Plan

## Sandbox Principle

Everything in `usr/{{PRINCIPAL_NAME}}/` is sandboxed:
- Zero impact to other team members
- Symlinks activate items into `.claude/` — local, opt-in
- Nothing here forces changes on the team

---

*Welcome to The Agency!*
