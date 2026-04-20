# Principal: test

Welcome to The Agency. This is your sandbox — everything here is yours.

## Directory Structure

```
usr/test/
  claude/              — Your Claude Code config
    CLAUDE.md          — Personal instructions (symlink to ~/.claude/CLAUDE.md)
    commands/          — Custom slash commands
    hookify/           — Behavioral rules (*.local.md)
    hooks/             — Shell hooks
    agents/            — Agent definitions
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

Create a directory under `usr/test/` for each project:

```bash
mkdir -p usr/test/my-project/{transcripts,code-reviews,history}
```

## File Naming Convention

All project artifacts follow: `{project}-{artifact}-YYYYMMDD.md`

- `my-project-pvr-20260329.md` — Product Vision & Requirements
- `my-project-architecture-20260329.md` — Architecture & Design
- `my-project-plan-20260329.md` — Implementation Plan

## Sandbox Principle

Everything in `usr/test/` is sandboxed:
- Zero impact to other team members
- Symlinks activate items into `.claude/` — local, opt-in
- Nothing here forces changes on the team

---

*Welcome to The Agency!*
