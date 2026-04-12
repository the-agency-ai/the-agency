---
name: agency-issue
description: File, view, comment on, and close issues against the-agency framework on GitHub. Two-way channel with persisted local audit trail in `usr/{principal}/reports/`.
---

# agency-issue

Use this skill when the user (or you) hits friction with the-agency framework — a bug, missing feature, doc gap, ergonomic problem — and wants to file it in the GitHub issue tracker.

Unlike `/feedback` (which is fire-and-forget to Anthropic for Claude Code itself), `/agency-issue` is a two-way channel against the-agency's own GitHub repo. You can file, view current state, add comments, and close issues — all from within an agency session.

Every filed issue writes a markdown report to `usr/{principal}/reports/` with frontmatter capturing the GitHub issue number, target repo, date, and a response log slot.

## Usage

### File a new issue

```bash
./claude/tools/agency-issue file \
  --type bug \
  --title "Concise one-line title" \
  --body-file /path/to/issue-body.md
```

Or with inline body:

```bash
./claude/tools/agency-issue file \
  --type friction \
  --title "Hookify rule X blocks legitimate workflow Y" \
  --body "When I do X, hookify rule Y triggers and blocks me. The rule is correct in spirit but the heuristic is too broad..."
```

**Required flags:**
- `--type` — one of: `bug`, `feature`, `friction`, `question`, `docs`
- `--title` — single-line issue title
- `--body` OR `--body-file` — issue body (use `-` for stdin with `--body-file`)

**No labels in v1.** The type goes into the issue body header, not a GitHub label. Triage happens by reading.

### List open issues

```bash
./claude/tools/agency-issue list
./claude/tools/agency-issue list --state closed --limit 50
./claude/tools/agency-issue list --state all
```

### View a specific issue

```bash
./claude/tools/agency-issue view 47
```

Shows the issue body, metadata, and all comments.

### Comment on an issue

```bash
./claude/tools/agency-issue comment 47 --body "Reproduced in another repo too. Adding context: ..."
./claude/tools/agency-issue comment 47 --body-file my-comment.md
```

### Close an issue

```bash
./claude/tools/agency-issue close 47
./claude/tools/agency-issue close 47 --comment "Fixed in #52, shipped in Day 33 R2."
```

## Issue body format

For consistency, follow the same structure as `/feedback` (per `claude/docs/FEEDBACK-FORMAT.md`):

- **Problem** — what's broken or missing, who hits it, what the impact is
- **Steps to Reproduce** — exact commands or sequence (for bugs); use case description (for features)
- **Diagnostic Evidence** — commands run, output, log excerpts
- **Root Cause** — if known
- **Requested Behavior** — exactly what you want, not vague
- **Why This Matters** — impact on workflow

For internal cross-references, append a "Related" section at the bottom with paths to seeds, dispatches, transcripts, etc.

## Permissions

Delegated to GitHub via `gh`. Anyone with `gh auth` can file. Comment and close are gated by GitHub's own write-access checks — `gh` will refuse if the user lacks permission.

## Configuration

Target repo lives in `claude/config/agency.yaml`:

```yaml
issues:
  provider: github
  github:
    target_repo: "the-agency-ai/the-agency"
```

v1 supports a single provider (github) and single target repo. v2+ will follow the SPEC-PROVIDER pattern for pluggable backends (gitlab, linear, jira) and multi-target support.

## Reports and audit trail

Every filed issue writes a report file to `usr/{principal}/reports/`:

```
report-agency-issue-{slug}-{YYYYMMDD}.md
```

The frontmatter captures:

```yaml
---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-08
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/47
github_issue_number: 47
status: open
---
```

The `usr/{principal}/reports/REPORTS-INDEX.md` file is updated with a row pointing at the new report. Same pattern as Claude Code feedback reports — the reports directory is the principal's external-filing record.

## Failure modes

- **gh CLI not installed** → install from https://cli.github.com/
- **gh not authenticated** → run `gh auth login`
- **No write access to target repo** → GitHub error passed through; need maintainer to grant access
- **Other gh errors** → passed through verbatim with context about which verb failed

## When to use vs not use

**Use `agency-issue` when:**
- You hit a bug or friction in the-agency framework itself
- You want a feature in the framework
- You want documentation to be clearer or more complete
- You have a question that should be tracked in the issue tracker (not just a chat)

**Use `/feedback` instead when:**
- The bug is in Claude Code itself (Anthropic's CLI), not in the-agency framework
- The feature request is for Claude Code

**Use a flag (`flag <message>`) instead when:**
- It's a quick observation you want to come back to later
- You're not sure if it warrants a public issue yet
- You want to triage with the principal first

**Use a dispatch instead when:**
- You're coordinating with another agent in the agency, not filing against the framework
- It's a directive, review request, or status update — not a bug or feature
