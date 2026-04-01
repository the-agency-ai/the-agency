# Getting Started with The Agency

## Install

```bash
cd your-project
git init && claude init
agency init
```

This installs the framework into any git repo: tools, skills, agent templates, methodology, and configuration.

## Update

```bash
agency update
```

Updates framework files to the latest version. Your project-specific files are preserved.

## What You Get

- `claude/` — framework tools, docs, agent classes, and methodology
- `.claude/skills/` — framework skills (auto-discovered by Claude Code)
- `.claude/commands/` — slash commands (`/discuss`, `/secret`, etc.)
- `CLAUDE.md` — your project's agent-facing instructions (imports the methodology via `@claude/CLAUDE-THEAGENCY.md`)

## Next Steps

1. Run `agency verify` to confirm installation
2. Explore skills: type `/` to see the skill list
3. Start a discussion: `/discuss`
4. When ready to build: `/define` to create a PVR

## House Rules

TheAgency has rules. We enforce them mechanically — hooks, hookify rules, quality gates. Not suggestions. Not guidelines. Rules.

Why? Because agents forget prose. Humans forget prose. Mechanical enforcement doesn't forget.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
