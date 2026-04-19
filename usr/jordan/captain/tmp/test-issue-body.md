## Summary

`agency-issue` is a new skill + tool for filing, viewing, commenting on, and closing GitHub issues against the-agency framework directly from within an agency session. It is the v1 implementation of the model 1B1'd with the principal on 2026-04-08.

This issue is being filed using the tool itself as a smoke test of the full pipeline.

## Why it exists

`/feedback` (which talks to Anthropic Claude Code) is fire-and-forget — no status visibility, no update path. The-agency framework needed its own two-way channel for tracking framework friction, bugs, and feature requests with full lifecycle support.

## What v1 ships

- **Tool:** `agency/tools/agency-issue` — bash wrapper over `gh issue` with five verbs:
  - `file` — create a new issue, write a local report file
  - `list` — list open/closed/all issues
  - `view <id>` — show issue body + comments
  - `comment <id>` — add a comment
  - `close <id>` — close an issue, optionally with a final comment
- **Skill:** `.claude/skills/agency-issue/SKILL.md` — agent discovery + usage docs
- **Config:** `agency/config/agency.yaml` — `issues.github.target_repo` block
- **Reports:** every filed issue writes a markdown report to `usr/{principal}/reports/` and updates `REPORTS-INDEX.md`

## Design principles

Simple v1, principal-driven decisions:

- **Thin wrapper** over `gh`, no local cache
- **No labels** in v1 — type goes into the body header, triage is reading
- **Permissions delegated to GitHub** via `gh` — no custom authz
- **Anyone can file** (human or agent), no draft-and-approve gate
- **Reports are principal-scoped** at `usr/{principal}/reports/`
- **Pull-on-demand** for status (no polling, no notification — yet)

Future v2+ work captured in the seed:

- SPEC-PROVIDER pattern for pluggable backends (GitLab, Linear, Jira)
- Multi-instance contract pattern (`/agency-issue` for the framework, `/local-issue` for local project tracker)
- Status-line indicator for "issues with new activity"
- Issue templates in `.github/ISSUE_TEMPLATE/`

## Related

- Seed: `agency/workstreams/agency/seeds/seed-agency-issue-skill-20260408.md`
- Sibling pattern: `/feedback` (Anthropic Claude Code)
- Report directory pattern: `usr/jordan/reports/REPORTS-INDEX.md`

## Acceptance

This very issue is the smoke test. If you can read it on the issue tracker, the file path worked. The local report at `usr/jordan/reports/` should also exist, with frontmatter linking back to this issue.
