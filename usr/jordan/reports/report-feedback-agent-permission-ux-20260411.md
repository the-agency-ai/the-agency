---
report_type: feature-request
filed_by: jordan
captain: the-agency/jordan/captain
date_filed: 2026-04-11
anthropic_feedback_id: TBD
github_issue: TBD
seed: claude/workstreams/agency/seeds/seed-agent-permission-ux-20260411.md
related_report: usr/jordan/reports/report-feedback-comms-gap-20260411.md
status: drafted-awaiting-filing
---

# Report: Agent permission model — trusted framework paths for autonomous agents

**Filed to Anthropic via `/feedback`:** _(pending)_
**Feedback ID:** _(pending)_
**Filed to GitHub:** _(pending)_
**Internal seed:** `claude/workstreams/agency/seeds/seed-agent-permission-ux-20260411.md`
**Related filing:** [report-feedback-comms-gap-20260411](report-feedback-comms-gap-20260411.md) — part of the same 2026-04-11 feedback batch

## Summary

Feature request to evolve Claude Code's permission model for autonomous agents. The current model is designed for human-in-the-loop sessions and breaks when agents run unattended — permission prompts go to a buffer the agent can't see, and the agent appears to hang for no reason.

Proposes five options in preference order: (1) trusted framework paths in settings.json, (2) `--agent-mode` session flag, (3) hot-reload permissions without session restart, (4) programmatic prompt visibility for agents, (5) fix brace expansion parsing. Folds in the previously-tracked brace expansion bug as a narrower independent ask.

## Requested behavior (five options)

1. **Trusted framework paths** — new `permissions.trustedFrameworkPaths` section, read-only ops auto-approved
2. **Agent mode** — `claude --agent-mode` session flag for autonomous operation
3. **Hot-reload permissions** — `settings.json` changes take effect without restart
4. **Prompt visibility** — programmatic channel for agents to see pending prompts
5. **Fix brace expansion parsing** — `{a,b,c}` shouldn't trigger compound-command handling

## Filed Text

See the seed document for the full drafted text. Clean submission payload is in the "Draft feedback text" section.

## Response Log

*(append responses here as they arrive)*

- **2026-04-11:** Drafted as seed + report. Folds in previously-tracked brace expansion issue.
- _(pending filing via `/feedback` and `gh issue create`)_
