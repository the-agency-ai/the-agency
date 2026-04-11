---
report_type: feedback
target: Anthropic Claude Code
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-11
status: draft
category: bug
severity: high
subject: /feedback command silently fails — accepts input, returns SHA, nothing is actually filed
source: usr/jordan/captain/anthropic-issues-to-file-20260406.md (item 4)
meta: This bug is the reason other feedback items sat in a draft list for weeks
---

## [Bug Report]: `/feedback` command silently fails — accepts input, returns SHA, nothing filed

**From:** Jordan Dea-Mattson
**GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
**Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
**Related:** This is the meta-bug that caused a backlog of other feedback to sit unfiled for weeks

## Problem

The `/feedback` slash command in Claude Code is the documented channel for submitting feedback to Anthropic. Users enter their feedback, the command reports success with a SHA confirmation, and users believe their feedback has been submitted.

**It hasn't.** There is no indication that the submission ever reached Anthropic's side. The SHA does not correspond to any retrievable record that the user can look up. Follow-up questions to the Anthropic team confirm the feedback was never received.

The command is a **trust-destroying silent failure**: it tells you "yes, filed" when nothing happened.

## Steps to Reproduce

1. Open Claude Code
2. Run `/feedback`
3. Enter a body of feedback text
4. Observe the success confirmation with a SHA
5. Attempt to retrieve the feedback from any Anthropic-facing channel (support portal, GitHub, Anthropic staff)
6. Observe: the feedback is not there. It was never filed.

## Diagnostic Evidence

- I have personally run `/feedback` multiple times over multiple weeks during development of the-agency framework. Zero of those submissions produced any visible outcome on the Anthropic side that I could verify.
- Our workaround: maintain a local list of pending feedback in `usr/jordan/captain/anthropic-issues-to-file-20260406.md`, and now file everything via GitHub issues at `github.com/anthropics/claude-code/issues` manually.
- As of 2026-04-11, we have **at least 4 pending feedback items** that were drafted between 2026-04-06 and today that we could not file via `/feedback` because we could not trust the command worked.
- This is now the subject of a public tweet by me (see @AgencyGroupAI on 2026-04-11) because the adjacent issue (content filter opacity) also generates silent failure with no signal, and the combined picture is starting to look like a systemic gap in how Claude Code handles "I couldn't do what you asked."

## Root Cause (suspected)

Without access to the internal implementation, I can only speculate. Possibilities:
- The feedback-submission backend endpoint has changed, been removed, or been rate-limited, but the client still reports success
- The command is generating a local SHA for tracking without ever attempting network submission
- A network or auth error is being swallowed silently

The **key failure mode** in all of these: the command does not surface failure to the user. That is the fix point, regardless of the underlying cause.

## Requested Behavior

**Minimum fix (priority 1):**
- If the feedback submission fails for any reason — network, auth, backend unavailable, rate limited — the command must report the failure clearly. No silent SHA-confirming "success."
- The SHA confirmation message must correspond to something the user can verify was received.

**Better fix:**
- `/feedback` should return a **URL** where the user can track the status of their submission (or at minimum, confirm it exists).
- If the backend channel is deprecated, deprecate the command — don't leave a broken loop in place.

**Best fix:**
- Route `/feedback` through a public, documented channel — likely GitHub Issues on `anthropics/claude-code` with a templated form. Users file, they get a real issue URL, they can watch it, Anthropic can triage it publicly. The trust loop is closed.
- Alternately: a first-class feedback portal at `feedback.claude.com/{user}` or similar that shows pending + resolved items for the user.

## Why This Matters

**This is the meta-bug.** It's not just one broken command — it's the reason other feedback doesn't reach Anthropic. When the feedback channel is broken, users who care about improving the product stop trying. The ones who don't stop find workarounds (like me filing via GitHub manually), which fragments feedback across channels and buries it.

**Trust decays fast.** I personally submitted multiple `/feedback` calls believing they were being delivered. When I discovered they weren't, I stopped using `/feedback` entirely. Every user who has this experience is an advocate lost.

**The observable pattern is bad:** A developer tool's **feedback channel being silently broken** is the specific failure mode that signals "the team building this doesn't dogfood the feedback loop." I don't believe that's actually true for Anthropic — but that's how the current state reads from the outside.

## Related context

- This bug is the **reason** multiple other feedback items (documented in `anthropic-issues-to-file-20260406.md`) sat unfiled for weeks
- Now also referenced in [Jordan's 2026-04-11 tweet about content filter opacity](https://twitter.com/AgencyGroupAI) — both are examples of silent-failure patterns in Claude Code's communication with its users
- We've adopted the workaround of filing directly via GitHub issues on `anthropics/claude-code`, but this isn't discoverable for new users

---

*Draft — awaiting principal review before send.*
