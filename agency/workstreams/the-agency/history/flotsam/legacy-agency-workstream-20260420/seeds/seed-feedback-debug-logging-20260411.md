---
type: seed
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: filed
anthropic_feedback_id: 229cbbce-6d28-4390-8eb2-aeaecc192b6c
github_issue: https://github.com/anthropics/claude-code/issues/46538
report: usr/jordan/reports/report-feedback-debug-logging-20260411.md
related_seed: claude/workstreams/agency/seeds/seed-feedback-comms-gap-20260411.md
---

**FILED 2026-04-11.** Anthropic feedback ID `229cbbce-6d28-4390-8eb2-aeaecc192b6c`; GitHub issue [anthropics/claude-code#46538](https://github.com/anthropics/claude-code/issues/46538). Tracking at `usr/jordan/reports/report-feedback-debug-logging-20260411.md`. Cross-reference comment posted on companion filing #46531.

# Seed: `/feedback` failures are not logged to `~/.claude/debug/` — narrow independent fix

## What this is

A narrow, focused bug request asking for one specific fix: when `/feedback` submission fails (for any reason), log the network request and its error response to `~/.claude/debug/` alongside the API calls, tool use, and hook events that are already logged there.

This is **separable from the broader `/feedback` fix** (which is captured in the comms-gap filing [#46531](https://github.com/anthropics/claude-code/issues/46531)). It is independently valuable: even if the underlying bug takes months to fix, adding debug logging immediately gives affected users a diagnostic trail to include when filing bug reports about the failure. Right now they have nothing.

## The gap (short version)

Claude Code logs API calls, tool use, and hook events to `~/.claude/debug/`. When users hit bugs, these log files are the primary diagnostic artifact they include in GitHub issues.

`/feedback` network requests and their errors are **not logged** to `~/.claude/debug/`. Users who hit `/feedback` failures have no diagnostic trail to include in their bug reports — they can only describe what they saw in the terminal, which is either a silent SHA or a cryptic "Could not submit feedback. Please try again later." This means bug reports about `/feedback` are starved of exactly the diagnostic data that would make them actionable.

This is the narrowest possible fix to the broader `/feedback` reliability problem. It doesn't address the underlying failure. It addresses the **diagnostic information gap** that compounds the failure.

## Evidence

From `@ert485`'s comment on [#10905](https://github.com/anthropics/claude-code/issues/10905):

> *"Additionally, the feedback submission failure doesn't get logged to the debug files (`~/.claude/debug/`). Those files capture API calls, tool use, and hook events, but the `/feedback` network request and its error are not recorded. It would help if the error details were logged there so users can provide more useful bug reports when the submission fails."*

This is a specific, actionable observation from a user who has been debugging the `/feedback` failure. It's the smallest imaginable fix and it unlocks better bug reports from everyone else affected.

## Related Agency work

- **Comms gap filing** ([#46531](https://github.com/anthropics/claude-code/issues/46531), filed 2026-04-11) — the broader framing covering the public-messaging gap and technical failure mode. This narrow seed is a focused follow-up that was originally going to be folded into the technical companion filing but was extracted when captain realized almost all the technical content was already in #46531.
- **`/feedback` silent failure (technical companion, originally #2 in batch)** — superseded by the comms gap filing; the only genuinely new content in the technical draft was the root-cause speculation (now added as a comment on #46531) and this debug-logging ask (extracted here).

## Requested behavior

When `/feedback` is invoked and attempts a network submission, log the following to `~/.claude/debug/` in the same format used for other API calls:

- The HTTP request (URL, method, headers with auth redacted, body size)
- The HTTP response (status code, headers, body)
- Any exception or error thrown client-side (stack trace, error type)
- A timestamp and session/request identifier so the entry can be correlated with other events

**On success:** log the request + response as usual.
**On failure:** log the request + failure reason + any error details. This is the critical case.

## Why this matters

- **Users filing bugs about `/feedback` have no diagnostic data.** The bug reports on #10905, #12638, and similar are full of "it says this message and then nothing happens" — with no concrete signal the triage team can use to narrow down the cause. Debug logging would turn those reports into "it returned 503 with this body at this timestamp."
- **This fix is small and independent.** Adding a network-request log line to an existing logging path is hygiene, not architecture. It can ship before the bigger `/feedback` redesign lands.
- **It compounds other fixes.** Once users can include real network data in their bug reports, the broader `/feedback` investigation gets unblocked.
- **Consistency with other logged events.** API calls, tool use, and hook events are already captured. `/feedback` being the one exception is a gap in an otherwise consistent diagnostic posture.

## Draft feedback text (ready for principal to file via `/feedback` + `gh issue create`)

*Captain authors this section. Principal reviews, edits if needed, then files.*

---

# Log `/feedback` network requests and errors to `~/.claude/debug/`

## Problem

Claude Code logs API calls, tool use, and hook events to `~/.claude/debug/`. These log files are the primary diagnostic artifact users include when filing bug reports.

**`/feedback` network requests and their errors are not logged to `~/.claude/debug/`.** When users hit `/feedback` failures, they have no diagnostic trail to include in their bug reports — only the generic terminal message they saw (a silent SHA or `"Could not submit feedback. Please try again later."`). Bug reports about `/feedback` are starved of exactly the diagnostic data that would make them actionable.

This is a narrow, focused ask. It does not fix the underlying `/feedback` reliability issue (that's [#46531](https://github.com/anthropics/claude-code/issues/46531) and the broader cluster referenced from there). It fixes the **information gap** that compounds the reliability issue: right now, when `/feedback` fails, nobody can tell you anything about why, because the failure is invisible to the only tool (`~/.claude/debug/`) that users have for diagnosing Claude Code problems.

## Evidence

From `@ert485`'s comment on [#10905](https://github.com/anthropics/claude-code/issues/10905) (the canonical `/feedback` broken-for-months ticket):

> *"Additionally, the feedback submission failure doesn't get logged to the debug files (`~/.claude/debug/`). Those files capture API calls, tool use, and hook events, but the `/feedback` network request and its error are not recorded. It would help if the error details were logged there so users can provide more useful bug reports when the submission fails."*

That's a specific, actionable observation from a user who has been debugging the failure directly.

## Expected behavior

When `/feedback` is invoked and attempts a network submission, log the following to `~/.claude/debug/` in the same format used for other API calls:

- The HTTP request (URL, method, headers with auth redacted, body size)
- The HTTP response (status code, headers, body)
- Any exception or error thrown client-side (stack trace, error type)
- A timestamp and session/request identifier for correlation

**On success:** log the request + response as usual.

**On failure:** log the request + failure reason + any error details. This is the critical case.

## Why this matters

- **Users filing bugs about `/feedback` have no diagnostic data.** Bug reports on #10905, #12638, and similar are full of *"it says this message and then nothing happens"* — with no concrete signal the triage team can use to narrow down the cause. Debug logging would turn those reports into *"it returned 503 with this body at this timestamp."*
- **This fix is small and independent.** Adding a network-request log line to an existing logging path is hygiene, not architecture. It can ship before any bigger `/feedback` redesign.
- **It compounds other fixes.** Once users can include real network data in their bug reports, the broader `/feedback` investigation gets unblocked.
- **Consistency.** API calls, tool use, and hook events are already logged. `/feedback` being the one exception is a gap in an otherwise consistent diagnostic posture.

## Scope

This is explicitly NOT a request to fix the underlying `/feedback` reliability issue. That's tracked in [#46531](https://github.com/anthropics/claude-code/issues/46531) and the cluster of closed tickets it references ([#10905](https://github.com/anthropics/claude-code/issues/10905), [#12638](https://github.com/anthropics/claude-code/issues/12638)). This is the smallest imaginable separable fix that makes those other fixes land faster because users can finally report the bug with real diagnostic data.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency
- **Claude Code version:** (fill at submission — `claude --version`)

## Related

- [#46531](https://github.com/anthropics/claude-code/issues/46531) — broader `/feedback` comms gap and reliability issue (filed same reporter, same day)
- [#10905](https://github.com/anthropics/claude-code/issues/10905) — canonical `/feedback` broken-for-months ticket (closed, auto-locked) — source of @ert485's observation
- [#12638](https://github.com/anthropics/claude-code/issues/12638) — duplicate of #10905 with "Plugin source missing" diagnostic data
- [#28565](https://github.com/anthropics/claude-code/issues/28565) — `/feedback` vs `/bug` naming mismatch

---

## Revisit triggers

File as part of today's batch. Immediate — this is a small, independent ask that can ship ahead of larger fixes.

## Conversation source

Captured during the Day 36-37 captain session on 2026-04-11 during 1B1 review of the slash-feedback technical bug draft. Captain and principal compared the draft against the already-filed #46531 and found that almost all the technical content was already covered in the comms-gap filing. The three pieces NOT already in #46531 were extracted: (1) root-cause speculation (added as comment on #46531), (2) intermittent data point (added as comment on #46531), (3) this narrow debug-logging ask (extracted into this standalone seed). Extraction pattern decided by principal: *"Let's do a mix of a & b. Update it with a comment and then file the narrowed b."*
