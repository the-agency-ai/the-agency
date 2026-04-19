---
report_type: bug-report
filed_by: jordan
captain: the-agency/jordan/captain
date_filed: 2026-04-11
anthropic_feedback_id: 229cbbce-6d28-4390-8eb2-aeaecc192b6c
github_issue: https://github.com/anthropics/claude-code/issues/46538
seed: agency/workstreams/agency/seeds/seed-feedback-debug-logging-20260411.md
related_report: usr/jordan/reports/report-feedback-comms-gap-20260411.md
status: filed
---

# Report: Log `/feedback` network requests and errors to `~/.claude/debug/`

**Filed to Anthropic via `/feedback`:** 2026-04-11
**Feedback ID:** `229cbbce-6d28-4390-8eb2-aeaecc192b6c`
**Filed to GitHub:** https://github.com/anthropics/claude-code/issues/46538
**Internal seed:** `agency/workstreams/agency/seeds/seed-feedback-debug-logging-20260411.md`
**Related filing:** [report-feedback-comms-gap-20260411](report-feedback-comms-gap-20260411.md) — broader `/feedback` issue filed as [#46531](https://github.com/anthropics/claude-code/issues/46531)

## Summary

A narrow, focused bug request asking for one specific fix: log `/feedback` network requests and their errors to `~/.claude/debug/` alongside the API calls, tool use, and hook events already logged there.

This is independently valuable and separable from the broader `/feedback` reliability fix. Even if the underlying bug takes months to fix, adding debug logging immediately gives affected users a diagnostic trail to include when filing bug reports about the failure. Right now they have nothing.

Evidence: @ert485's comment on #10905 explicitly observed this gap. This filing extracts that observation into a standalone ask.

## Requested behavior

Log to `~/.claude/debug/` on every `/feedback` invocation:
- HTTP request (URL, method, redacted headers, body size)
- HTTP response (status code, headers, body)
- Exceptions or client-side errors
- Timestamp and session/request identifier for correlation

**Critical:** log on failure, not just on success.

## Filed Text

See the seed document for the full drafted text. Clean submission payload is in the "Draft feedback text" section.

## Response Log

*(append responses here as they arrive)*

- **2026-04-11:** Drafted as seed + report. Extracted from the original slash-feedback technical bug draft during 1B1 review when captain and principal found most technical content was already covered in #46531. The three new pieces (root-cause speculation, intermittent data point, and this narrow debug-logging ask) were split — first two added as a comment on #46531, this one filed as a standalone narrow bug request.
- **2026-04-11:** Filed via `/feedback`. Returned Feedback ID `229cbbce-6d28-4390-8eb2-aeaecc192b6c` and GitHub URL https://github.com/anthropics/claude-code/issues/46538.
- **2026-04-11:** Cross-reference comment posted on the companion filing [#46531](https://github.com/anthropics/claude-code/issues/46531#issuecomment-4228260833) pointing at this narrow filing.
- **2026-04-11:** Cross-reference comment posted on this issue [#46538](https://github.com/anthropics/claude-code/issues/46538#issuecomment-4228260768) with the Feedback ID and pointer back to #46531.
