---
report_type: agency-issue
issue_type: friction
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-21
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/395
github_issue_number: 395
status: open
---

# git-safe-commit: add --coord convenience flag (alias for coord-commit happy path)

**Filed:** 2026-04-21T05:17:03Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#395](https://github.com/the-agency-ai/the-agency/issues/395)
**Type:** friction
**Status:** open

## Filed Body

**Type:** friction

## What happened

Tried `./agency/tools/git-safe-commit --coord --message "..."` and got `Unknown option: --coord`. The flag does not exist; coord commits route through the `/coord-commit` skill (which itself calls `git-safe-commit --no-work-item` with coord-artifact staging rules).

### Why this is a nit

From an agent's POV, `--coord` is a natural flag to reach for:

- `/coord-commit` skill exists and is discoverable via `/` autocomplete.
- `/git-safe-commit "..."` skill exists and has `--no-work-item` as the escape hatch.
- Agent memory / pattern-match produces `--coord` as "the flag that means this is a coord artifact."

Hitting `Unknown option` costs one round-trip and re-routing.

### Proposal

Add a `--coord` convenience flag to `git-safe-commit` that:

1. Implies `--no-work-item`.
2. Validates that staged files are coord artifacts per `agency/CLAUDE-THEAGENCY.md §3.3` (handoffs, dispatches, seeds, `usr/{principal}/{agent}/tools/*`, `agency/config/*`, `.claude/skills/*`, `.gitignore`, etc.). Fails if any framework-code file is staged.
3. Uses commit message format `misc: <short summary>` (same as `/coord-commit`).

Effectively a built-in alias for the `/coord-commit` skill's happy path.

### Acceptance criteria

- [ ] `./agency/tools/git-safe-commit "message" --coord` works.
- [ ] `--coord` is documented in `--help`.
- [ ] `--coord` + staged framework code → clear error telling the user to use `/quality-gate` + `/iteration-complete` instead.
- [ ] `/coord-commit` skill can optionally delegate to `git-safe-commit --coord` (internal refactor).

### Priority

Nit / DX improvement. Not blocking. Noticed during 2026-04-21 root-cause sweep after session-resume errors.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-21:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/395
