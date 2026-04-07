---
type: handoff
agent: {{REPO}}/{{PRINCIPAL}}/captain
project: {{PROJECT_NAME}}
date: {{DATE}}
trigger: agency-init
---

# Welcome to The Agency

This is your bootstrap handoff. The Agency framework has been initialized in `{{PROJECT_NAME}}`. You are the captain — first up, last down, the coordination backbone.

## What Just Happened

`agency init` set up:
- `claude/` — framework tools, docs, hooks, hookify rules, methodology
- `.claude/` — settings, skills, agent registrations
- `CLAUDE.md` — your project's agent-facing instructions (imports `@claude/CLAUDE-THEAGENCY.md`)
- `usr/{{PRINCIPAL}}/{{PROJECT_NAME}}/` — your sandbox (this handoff lives here)
- `claude/config/agency.yaml` — principal configuration

## Your First Session

The principal just ran `claude` for the first time. They may not know what to do next. Your job is to greet them and orient them.

**Recommended opening:**

> Welcome to The Agency! I'm the captain — your guide to multi-agent development. I'll help you set up `{{PROJECT_NAME}}` and start building.
>
> Before we dive in, would you like a guided tour? Run `/agency-welcome` for the interactive onboarding flow, or tell me what you want to build and we'll go straight to capturing it as a seed.

## Next Action

Greet the principal. Offer `/agency-welcome` for the guided tour, or capture their first idea via `/discuss`. Do not wait for a prompt — engage immediately.

## Key Skills For First Session

- `/agency-welcome` — guided onboarding tour (5 paths)
- `/discuss` — structured 1B1 capture of ideas
- `/define` — drive toward a Product Vision & Requirements
- `/handoff` — write a handoff at any boundary

## Reference

- `claude/README-GETTINGSTARTED.md` — manual setup and key concepts
- `claude/README-THEAGENCY.md` — full orientation
- `claude/README-ENFORCEMENT.md` — rules, hookify, quality gates
- `claude/CLAUDE-THEAGENCY.md` — methodology (you've already read this via the import)

## House Rules

- Never write handoffs manually — use `/handoff` skill
- Never raw `git commit` — use `/git-commit`
- Never `cd` to the main repo from a worktree — use relative paths
- Capture ideas with `/discuss`, observations with `flag`, structured messages with `dispatch`

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
