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

D41-R5 fix: instructions now use the safe-tool family. Bare `git` is
hookify-blocked for agents (block-raw-tools.sh). Use `git-safe` /
`git-safe-commit` per the standard discipline.

1. Run `./claude/tools/git-safe status` to see changes
2. Identify which changed files are coordination artifacts (handoffs, dispatches, seeds, config, hookify, CLAUDE*.md, tools in `usr/{principal}/{agent}/tools/`)
3. Stage ONLY coordination artifacts — never stage application code
4. Run `./claude/tools/git-safe diff --cached --stat` to verify what's staged
5. Run `./claude/tools/git-safe log --oneline -3` for commit message style
6. Generate a commit message with `misc:` prefix
7. Run `./claude/tools/git-safe add` for each file separately (the tool blocks `-A`, `--all`, `.`, and wildcards by design)
8. Run `./claude/tools/git-safe-commit "message" --no-work-item` to commit — never raw `git commit`. Coordination artifacts skip QG (no QGR receipt required) but still go through the safe wrapper.
9. Run `./claude/tools/git-safe status` to verify

## What is a coordination artifact?

- `usr/{principal}/*/handoff.md` or `*-handoff.md`
- `usr/{principal}/*/dispatches/*`
- `usr/{principal}/*/seeds/*`
- `usr/{principal}/{agent}/tools/*`
- `usr/{principal}/*/CLAUDE-*.md`
- `claude/config/*`
- `claude/CLAUDE-THEAGENCY.md`
- `.claude/settings.json`
- `.claude/skills/*/SKILL.md`
- `.gitignore`
- Hookify rules (`usr/{principal}/hookify/*`)

## What is NOT a coordination artifact?

- `apps/**` — application code → needs QG
- `packages/**` — library code → needs QG
- `tools/**` (project root) — project tools → needs QG
- `claude/tools/*` — framework tools → needs QG (unless just copying from the-agency)
