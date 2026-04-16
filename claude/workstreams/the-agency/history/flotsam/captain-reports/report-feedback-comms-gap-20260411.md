---
report_type: bug-report
filed_by: jordan
captain: the-agency/jordan/captain
date_filed: 2026-04-11
anthropic_feedback_id: 95fe4771-6780-4be7-9e8e-30d7feea3496
github_issue: https://github.com/anthropics/claude-code/issues/46531
seed: claude/workstreams/agency/seeds/seed-feedback-comms-gap-20260411.md
status: filed
---

# Report: Communications gap — `/feedback` broken for 5+ months while team publicly directs users to it

**Filed to Anthropic via `/feedback`:** 2026-04-11
**Feedback ID:** `95fe4771-6780-4be7-9e8e-30d7feea3496`
**Filed to GitHub:** https://github.com/anthropics/claude-code/issues/46531
**Internal seed:** `claude/workstreams/agency/seeds/seed-feedback-comms-gap-20260411.md`

## Summary

A communications / product-trust issue, filed against Claude Code about the gap between **what the Claude Code team publicly tells users to do** (file via `/feedback`) and **what the technical state actually is** (`/feedback` has been broken or intermittent since at least November 2025, with the canonical tracking issue #10905 closed and auto-locked and new reports being auto-deduped into silence).

The filing names names: @trq212's February 2026 tweet directing concerned users to `/feedback` during Opus 4.5 degradation, @bcherny's pattern of similar messaging around feature launches, and the structural failure of the closed-and-locked dedupe cycle that hides the known issue from users searching before filing.

## Key evidence cited in the filing

- [#10905](https://github.com/anthropics/claude-code/issues/10905) — canonical `/feedback` bug, filed November 2025, CLOSED and auto-locked, 21 user comments reporting continued failure after closure
- [#12638](https://github.com/anthropics/claude-code/issues/12638) — duplicate filed 2025-11-28, auto-closed with diagnostic data (`Plugin source missing` trace)
- [#28565](https://github.com/anthropics/claude-code/issues/28565) — `/feedback` vs `/bug` naming mismatch blocking search
- [#45017](https://github.com/anthropics/claude-code/issues/45017) — previous successful cross-file from this reporter (silent periodic tool calls, filed 2026-04-08)
- [@trq212 February 2026 tweet](https://x.com/trq212/status/2001541565685301248) — directing users to `/feedback` during Opus 4.5 degradation concerns
- [@AgencyGroupAI 2026-04-11 tweet](https://twitter.com/AgencyGroupAI) — reporter's public expression of the silent-failure frustration

## Requested actions (four priority tiers)

1. Acknowledge publicly that `/feedback` is currently unreliable; pin status in the claude-code repo
2. Stop directing users to the broken channel until it is known-working and monitored
3. Fix discoverability (resolve naming mismatch, log `/feedback` failures to `~/.claude/debug/`, give the dedupe bot a "still broken" escape hatch)
4. Publish a post-mortem once fixed, same principle as Anthropic's engineering postmortems

## Filed Text

See the seed document for the full drafted text. The filed version is identical except for the identity block, which uses:

- **From:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com

## Response Log

*(append responses here as they arrive)*

- **2026-04-11:** Filed via `/feedback` — **the channel worked this time**. Returned Feedback ID `95fe4771-6780-4be7-9e8e-30d7feea3496` and GitHub URL https://github.com/anthropics/claude-code/issues/46531. This is itself a data point for the comms gap: the channel is intermittent, not universally broken, which reinforces rather than invalidates the filing's thesis.
- **2026-04-11:** Filed to GitHub as issue [#46531](https://github.com/anthropics/claude-code/issues/46531).
