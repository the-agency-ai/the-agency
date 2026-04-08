---
report_type: feature-request
filed_by: jordan
captain: the-agency/jordan/captain
date_filed: 2026-04-08
anthropic_feedback_id: 8dd67e96-63ea-4a22-b687-d26a1b2d0add
github_issue: https://github.com/anthropics/claude-code/issues/45017
seed: claude/workstreams/agency/seeds/seed-silent-periodic-tool-calls-20260408.md
status: filed
---

# Report: Periodic silent execution primitive for autonomous agents

**Filed to Anthropic via `/feedback`:** 2026-04-08
**Feedback ID:** `8dd67e96-63ea-4a22-b687-d26a1b2d0add`
**Filed to GitHub:** https://github.com/anthropics/claude-code/issues/45017
**Internal seed:** `claude/workstreams/agency/seeds/seed-silent-periodic-tool-calls-20260408.md`

## Summary

Claude Code has no mechanism to execute periodic scheduled tool calls (`CronCreate`, `/loop`) without rendering them in the terminal transcript. For autonomous-agent infrastructure (like the-agency) that needs to self-poll between user turns, this is pollution that scales linearly with polling frequency.

The gap: hooks are silent but event-driven only; `CronCreate` is periodic but every fire renders visibly. No mechanism combines silent + periodic + agent-context-aware.

## Requested Options

1. **Periodic hook type** in `settings.json` (preferred — minimal new surface)
2. **`hook:` parameter on `CronCreate`** (may be cleaner depending on scheduler internals)
3. **Document status line as the canonical display-only path** (fallback, doesn't close gap)

## Filed Text

See the seed document for the full drafted text. The filed version is identical except for the identity block, which uses:

- **From:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com

## Response Log

_(append responses here as they arrive)_

- **2026-04-08:** Filed via `/feedback`. Confirmation: Feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add`.
- **2026-04-08:** Filed on GitHub via `gh issue create`: https://github.com/anthropics/claude-code/issues/45017
