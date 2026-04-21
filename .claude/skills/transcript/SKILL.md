---
description: Real-time conversation capture — records dialogue and decisions as they happen.
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Transcript — Conversation Capture

Real-time conversation capture tool. Records dialogue and decisions as they happen.

## Subcommands

- `start "topic"` — Begin transcript capture
- `capture "title" "description"` — Append decision entry
- `append "text"` — Append freeform text
- `stop` — Finalize transcript
- `list` — List recent transcripts
- `status` — Report if active, mode, file path

## Start Options

- `--mode dialogue|review|design` — capture mode (default: dialogue)
- `--file path` — explicit file path
- `--project name` — project name for path resolution

## Project Detection

If `--project` not specified, derive as follows:
- In a worktree on a feature branch: take the last segment of the branch name after `/` (e.g., `proto/folio` → `folio`)
- On master (or main checkout): use the basename of `$CLAUDE_PROJECT_DIR` (e.g., `/Users/x/code/{repo}` → `{repo}`)

This matches the `_agency-init` Step 5b resolver — every skill defaulting a project/workstream name should use the same basename rule so fleet paths stay consistent. (the-agency#343)

## File Location

Transcripts go to `agency/workstreams/{W}/transcripts/` where `{W}` is the current workstream (derived from branch name or `--project` argument). `{principal}` is detected via glob `usr/*/`.

Filename: `{mode}-transcript-{YYYYMMDD}.md` (e.g., `dialogue-transcript-20260401.md`)

## Dialogue Mode

After every substantive response in the conversation, append the exchange to the transcript file:

1. Summarize the key points of the exchange
2. Preserve the user's actual words for important decisions
3. Record decisions with a `**Decision:**` prefix
4. Record action items with a `**Action:**` prefix

## Review/Design Modes

Same as dialogue but with mode-specific headers and structure:
- Review mode: organized by file/component reviewed
- Design mode: organized by design decision

## Status

When asked for status, report:
- Whether a transcript is active
- Current mode
- File path
- Number of entries captured
