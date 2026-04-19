---
report_type: bug-report
filed_by: jordan
captain: the-agency/jordan/captain
date_filed: 2026-04-11
anthropic_feedback_id: cc00b303-5710-4e23-862e-882d6db8c7e0
github_issue: https://github.com/anthropics/claude-code/issues/46546
seed: agency/workstreams/agency/seeds/seed-content-filter-opacity-20260411.md
related_report: usr/jordan/reports/report-feedback-comms-gap-20260411.md
status: filed
---

# Report: Anthropic API content filter returns zero diagnostic signal on block

**Filed to Anthropic via `/feedback`:** 2026-04-11
**Feedback ID:** `cc00b303-5710-4e23-862e-882d6db8c7e0`
**Filed to GitHub:** https://github.com/anthropics/claude-code/issues/46546
**Internal seed:** `agency/workstreams/agency/seeds/seed-content-filter-opacity-20260411.md`
**Public record:** [@AgencyGroupAI tweet 2026-04-11](https://twitter.com/AgencyGroupAI)
**Related filing:** [report-feedback-comms-gap-20260411](report-feedback-comms-gap-20260411.md) — sibling silent-failure pattern filed as [#46531](https://github.com/anthropics/claude-code/issues/46531)

## Summary

Anthropic API content filter returns a `400` error with the message *"Output blocked by content filtering policy"* and a request_id, and nothing else. No category, no matched span, no severity, no guidance. Developers cannot debug false positives, cannot adapt prompts, and cannot distinguish genuine policy violations from classifier false positives.

Two filter blocks fired in rapid succession during routine contribution-doc writing on 2026-04-11 (PR template and Code of Conduct). Both were on entirely benign content. Principal made the frustration public via @AgencyGroupAI the same day.

## Requested behavior (four priority tiers)

1. **Minimum:** Return filter category in the error payload (`violence`, `sexual`, `self-harm`, etc.)
2. **Better:** Return coarse severity (low/medium/high) alongside the category
3. **Higher value:** Return matched span or token range when safe to do so
4. **Best:** Developer-facing lookup endpoint keyed on request_id; publicly documented categories

## Filed Text

See the seed document for the full drafted text. Clean submission payload is in the "Draft feedback text" section of the seed.

## Response Log

*(append responses here as they arrive)*

- **2026-04-11:** Drafted as seed + report. Tweet public via @AgencyGroupAI.
- **2026-04-11:** Filed via `/feedback`. Returned Feedback ID `cc00b303-5710-4e23-862e-882d6db8c7e0` but did **not** return a companion GitHub URL (unlike #46531 and #46538 earlier in the day). Captain filed manually on GitHub.
- **2026-04-11:** Filed to GitHub manually via `gh issue create` as [#46546](https://github.com/anthropics/claude-code/issues/46546) with the Feedback ID prepended into the issue body at creation time. This is the "comment+edit" dance from earlier filings collapsed into one step.
- **2026-04-11:** Cross-reference comment posted on companion filing [#46531](https://github.com/anthropics/claude-code/issues/46531) linking to #46546 as a sibling silent-failure pattern.
