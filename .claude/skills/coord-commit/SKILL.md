---
description: Commit coordination artifacts (handoffs, dispatches, seeds, config) without QG
---

<!--
  Permission note (flag #62, flag #63 / devex dispatch #171):
  This skill intentionally does NOT set allowed-tools. Restricting to specific
  git subcommand patterns silently blocks agents on permission prompts they
  cannot see, and the principal cannot see which tool is being blocked either
  (the permission visibility gap). Devex was stalled for hours on this trap.
  Inherit from .claude/settings.json (Bash(*)) instead. See flag #63.
-->


# Coordination Commit

For captain coordination artifacts only — handoffs, dispatches, seeds, config updates, hookify rules, CLAUDE.md changes. NOT for implementation code.

## Arguments

- `$ARGUMENTS`: Files to stage and commit. If empty, stages all modified/untracked coordination files.

## Instructions

1. Run `git status` to see changes
2. Identify which changed files are coordination artifacts (handoffs, dispatches, seeds, config, hookify, CLAUDE*.md, tools in `usr/jordan/captain/tools/`)
3. Stage ONLY coordination artifacts — never stage application code
4. Run `git diff --cached --stat` to verify what's staged
5. Run `git log --oneline -3` for commit message style
6. Generate a commit message with `misc:` prefix
7. Run `git add` for each file separately (not `git add -A`)
8. Run `git commit` with the message — single command, no heredoc, no `&&`
9. Run `git status` to verify

## What is a coordination artifact?

- `usr/jordan/*/handoff.md` or `*-handoff.md`
- `usr/jordan/*/dispatches/*`
- `usr/jordan/*/seeds/*`
- `usr/jordan/captain/tools/*`
- `usr/jordan/*/CLAUDE-*.md`
- `claude/config/*`
- `claude/CLAUDE-THEAGENCY.md`
- `.claude/settings.json`
- `.claude/skills/*/SKILL.md`
- `.gitignore`
- Hookify rules (`usr/jordan/hookify/*`)

## What is NOT a coordination artifact?

- `apps/**` — application code → needs QG
- `packages/**` — library code → needs QG
- `tools/**` (project root) — project tools → needs QG
- `claude/tools/*` — framework tools → needs QG (unless just copying from the-agency)
