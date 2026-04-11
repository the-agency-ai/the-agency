---
type: seed
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: draft-pending-filing
report: usr/jordan/reports/feedback-slash-feedback-silent-failure-20260411.md
related_seed: claude/workstreams/agency/seeds/seed-silent-periodic-tool-calls-20260408.md
---

# Seed: `/feedback` command silently fails (Claude Code bug — meta-issue)

## What this is

A feedback/bug report to file with Anthropic (Claude Code team) documenting that the `/feedback` slash command accepts input, generates a SHA confirmation, and reports success — but the feedback is never actually delivered to Anthropic's tracking systems. Silent failure with no error signal.

**This is the meta-bug.** It is the reason other feedback items sat in a local draft list for weeks without being filed. When a developer cannot trust the feedback channel, the feedback stops flowing, and the product team stops hearing from its users. Every other feedback report in this filing batch exists because this one failed.

## The gap (short version)

`/feedback` returns a SHA confirmation after the user submits feedback, but **the SHA is an opaque token that cannot be looked up from any user-facing channel**. The user has no way to verify whether their submission actually reached Anthropic's triage queue. When submissions do not visibly result in a public ticket or a team response, the user cannot distinguish between "normal triage delay" and "silent drop on the floor."

Observationally, multiple submissions across weeks of use have produced SHA confirmations that never correlated to any visible outcome on the Anthropic side — not even acknowledgment, not even a "we received this" receipt. The 2026-04-08 silent-periodic filing *did* return a SHA (`8dd67e96...`), but the user only knows that submission reached Anthropic because it was **also** filed to GitHub as issue #45017. The GitHub filing is the verifiable path. The `/feedback` path is an act of faith.

The core failure mode: **"submission accepted" without any proof of delivery the user can verify**. Contrast with `gh issue create` which returns a URL to a live issue the user can open immediately and watch forever.

This report does not claim `/feedback` always drops submissions. It claims **the user has no way to tell whether it did**, and observationally several submissions have in fact been dropped. In both cases — actual drop or unverifiable delivery — the resulting user experience is the same: trust evaporates and users stop filing.

## Related Agency work

This feedback sits at the center of a cluster of silent-failure patterns we have observed recently across Claude Code and the Anthropic API:

- **`anthropic-issues-to-file-20260406.md`** — master tracking file in `usr/jordan/captain/` that grew from 1 item to 4 items over a week as captain attempted to file each via `/feedback`, saw success confirmations, and later discovered none had landed. The tracking file was originally meant as a scratchpad before filing; it became a graveyard of unfiled drafts.
- **Content filter opacity** (sibling seed: [`seed-content-filter-opacity-20260411.md`](seed-content-filter-opacity-20260411.md)) — Anthropic API returns 400 "Output blocked" with zero diagnostic signal. Same failure-mode family: the system fails, the user is not told why. Jordan made this pattern public via [@AgencyGroupAI on 2026-04-11](https://twitter.com/AgencyGroupAI) with a tweet saying *"Stumbling in the dark with Claude... Zero feedback. No way to correct."*
- **Silent periodic tool calls** ([`seed-silent-periodic-tool-calls-20260408.md`](seed-silent-periodic-tool-calls-20260408.md), already filed 2026-04-08 as GitHub [#45017](https://github.com/anthropics/claude-code/issues/45017)) — this one WAS filed via `/feedback`, producing feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add`. But even there, the captain filed it via `gh issue create` as a *second* channel because trust in the `/feedback` pipeline alone was already shaky. Today's investigation reinforces that the secondary channel was the right call.
- **Agent permission UX**, **`--agent` env var missing**, **macOS permission break on update** — three more items from the same unfiled backlog. Each would have been filed promptly if `/feedback` had worked. All are being filed today via `gh issue create` as part of unblocking the backlog.

**Pattern recognition:** Claude Code has an emerging "silent failure" problem across multiple user-facing surfaces (feedback, content filtering, permission prompts that route nowhere visible for autonomous agents). None of them log an error the user can act on. Individually, each looks like a bug. Together, they suggest a design-time principle that is not being followed consistently: **"never fail silently. If you cannot do what the user asked, tell them."**

## Our observations

Specific instances of `/feedback` failing silently, drawn from captain's work history and flag queue:

1. **2026-04-06** — Captain composed the first three items of `anthropic-issues-to-file-20260406.md` intending to file each via `/feedback`. Filed them. Saw SHA confirmations. Assumed delivery. **(No record of delivery on Anthropic's side when checked days later.)**
2. **2026-04-08** — Captain filed the silent-periodic-tool-calls feedback via `/feedback` and also via `gh issue create` as a backup. The `gh issue create` produced a live URL immediately (#45017). The `/feedback` submission returned a SHA but was never correlatable to any visible outcome. The fact that the captain instinctively filed twice that day suggests the captain had already lost faith in `/feedback` alone.
3. **2026-04-11 (today)** — Captain and principal realized that **four separate items** from the April 6 list had never reached Anthropic. Principal asked "do the feedback (and the others pending) and we will send them off." Investigation found the master draft list. Decision: file everything via `gh issue create` going forward. Treat `/feedback` as untrusted until fixed.

## What we've tried

1. **Filing via `/feedback` alone** — silent dropout, no confirmation feedback reached Anthropic.
2. **Filing via `/feedback` + `gh issue create`** — the `gh` path works reliably and produces a traceable URL. The `/feedback` path remains opaque.
3. **Maintaining a local draft list** (`anthropic-issues-to-file-20260406.md`) to batch items before filing — necessary workaround, but turns into a graveyard when `/feedback` is broken.
4. **Building a dedicated feedback skill** — captured as Task #14 in this session. A repeatable skill that reads principal identity from `agency.yaml`, follows `FEEDBACK-FORMAT.md`, drafts the report, and files via `gh issue create`. This is the workaround we will operationalize.

## Use case for the feedback

Multi-agent framework (`the-agency-ai/the-agency`) where the principal and captain file feedback against Claude Code regularly as part of dogfooding. The framework is explicitly designed to surface bugs and feature gaps to upstream tools. When the upstream feedback channel is broken, the whole dogfooding loop breaks:

- Bugs discovered while building the framework don't reach Anthropic
- Anthropic loses a high-signal source of real-world usage data
- Framework developers stop trying to report issues because reporting is an expensive act of faith
- The relationship between framework and tool vendor degrades from "active collaboration" to "trust-degraded workaround"

This is not a hypothetical. We have a master list of items Anthropic never heard about for weeks.

## Root cause (suspected)

Without access to the internal implementation, I can only speculate. Possibilities:

1. **The submission backend endpoint has changed, been removed, or been rate-limited**, but the client still reports success. If the backend URL or auth scheme changed and the client wasn't updated, submissions would silently 404 or 401 at the transport layer while the client happily returned a locally-generated SHA.
2. **The command is generating a local SHA for tracking** and never actually attempting network submission. This would be the case if the feedback-submission code path was stubbed out during a refactor and never re-enabled.
3. **A network or auth error is being swallowed silently** in a try/catch block that was intended as a "don't crash the session" safety net and turned into a "don't notify the user" bug.
4. **The backend is receiving submissions but they are not being persisted or routed to triage** — a dead-letter queue with no visibility to either the user or the triage team.

The **key failure mode** in all of these: the command does not surface failure to the user. That is the fix point, regardless of the underlying cause. If the implementation can't deliver, it should say so.

## Requested behavior

**Priority 1 (minimum fix):**
- If feedback submission fails for any reason — network, auth, backend unavailable, rate limited — the command must surface the failure clearly. No silent SHA-confirming "success."
- The SHA confirmation message must correspond to something the user can verify was received.

**Priority 2 (better fix):**
- `/feedback` should return a **URL** where the user can track the status of their submission (or at minimum, confirm the submission exists on Anthropic's side).
- If the backend channel is deprecated, deprecate the command — don't leave a broken loop in place. A deprecated command that prints `"/feedback is no longer supported, please file at github.com/anthropics/claude-code/issues"` is strictly better than a command that silently drops input.

**Priority 3 (best fix):**
- Route `/feedback` through a public, documented channel — likely GitHub Issues on `anthropics/claude-code` with a templated form. Users file, they get a real issue URL, they can watch it, Anthropic can triage it publicly, the trust loop is closed.
- Alternately: a first-class feedback portal at `feedback.claude.com/{user}` or similar that shows pending + resolved items for the user, with real submission tracking.

## Why it matters

**Short version:** A developer tool's feedback channel being silently broken is the specific failure mode that signals *"the team building this doesn't dogfood the feedback loop."* I don't believe that's actually true for Anthropic. But that's how the current state reads from the outside, and perception becomes reality fast when the fix window closes.

**Longer version:**

- **Silent feedback failure is trust-destroying.** Users who care about improving the product stop trying after the first or second dropped submission. The users who don't stop (like me) find workarounds (filing via `gh` manually), which fragments feedback across channels and buries it in places the triage team may not watch.
- **The observable pattern is bad.** An AI tool vendor whose feedback submission silently drops is in a weird mirror image of the content-moderation false-positive problem: in both cases, the system fails the user without telling them what went wrong. Anthropic has been thoughtful about transparency in other areas (system card, usage policies, etc.). The `/feedback` silent failure is a gap in that posture.
- **This directly blocks the-agency framework development.** We file feedback against Claude Code weekly as part of our work. When the channel is broken, we either waste effort filing twice (manual gh + /feedback) or give up and accumulate a graveyard.
- **The fix is not technically hard.** "Return an error when something fails" is not a major redesign. It is hygiene.

## Mechanical notes for submission

**Role split:**
- **Captain authors** the seed and draft text. That's this document.
- **Principal files** the feedback via `/feedback` and cross-files to GitHub via `gh issue create` (or the `/agency-bug` equivalent). Captain does not presume to file without principal approval.

**Recommended cross-filing pattern:**
1. Principal reviews this seed, approves or edits the "Draft feedback text" section below
2. Principal files via `/feedback` (which may or may not land on Anthropic's side — the bug is that we cannot verify)
3. Principal cross-files to GitHub via `gh issue create --repo anthropics/claude-code --title "..." --body-file <path>` to guarantee a traceable public record
4. Captain updates the report tracker in `usr/jordan/reports/` with both the `/feedback` ID (if one is returned) and the GitHub issue URL
5. Response log is appended as responses arrive

**Why cross-file:** The silent-periodic-tool-calls feedback filed on 2026-04-08 *did* return an Anthropic feedback ID (`8dd67e96-63ea-4a22-b687-d26a1b2d0add`) and was *also* filed to GitHub as [#45017](https://github.com/anthropics/claude-code/issues/45017). The GitHub path is the verifiable one. The `/feedback` ID is an opaque token the user cannot lookup, which is precisely what this bug report is about.

**Reporter identity (pre-filled from `agency.yaml`):**
- Jordan Dea-Mattson
- GitHub: `@jordandm` (the-agency-ai), `@jordan-of` (OrdinaryFolk)
- Email: `jordandm@users.noreply.github.com`, `jordan-of@users.noreply.github.com`
- Claude Code version: run `claude --version` at submission time
- Framework reference: https://github.com/the-agency-ai/the-agency
- Related public record: [@AgencyGroupAI tweet 2026-04-11](https://twitter.com/AgencyGroupAI) — content filter opacity (sibling silent-failure pattern)
- Related filing: This is item 1 of 5 in a batch being re-drafted and filed today to clear the backlog

## Draft feedback text (ready for principal to file via `/feedback` + `gh issue create`)

*Captain authors this section. Principal reviews, edits if needed, then files via both channels (cross-file pattern — see Mechanical Notes). Do not presume captain will file; filing is an explicit principal action.*

---

# `/feedback` command silently fails — accepts input, returns SHA, nothing filed

## Problem

The `/feedback` slash command is the documented channel for submitting feedback to Anthropic from within Claude Code. Users enter their feedback, the command reports success with a SHA confirmation, and users believe their feedback has been submitted.

**It hasn't.** There is no indication that the submission ever reached Anthropic's side. The SHA does not correspond to any retrievable record the user can look up. Follow-up observation confirms the feedback was never received.

The command is a trust-destroying silent failure: it tells you "yes, filed" when nothing happened.

## Steps to reproduce

1. Open Claude Code (any recent version)
2. Run `/feedback`
3. Enter a body of feedback text
4. Observe the success confirmation with a SHA
5. Attempt to retrieve the feedback from any Anthropic-facing channel (support portal, GitHub, Anthropic staff)
6. Observe: the feedback is not there. It was never filed.

## Observed behavior

- Multiple `/feedback` invocations over multiple weeks (2026-04-06 through 2026-04-11) produced zero visible outcome on the Anthropic side.
- On 2026-04-08, the same user filed one feedback item via both `/feedback` and `gh issue create --repo anthropics/claude-code`. The `gh` path produced issue [#45017](https://github.com/anthropics/claude-code/issues/45017) immediately. The `/feedback` path returned a SHA but was never correlatable to any visible outcome.
- As of 2026-04-11, at least four separately-drafted feedback items from a local tracking file (`anthropic-issues-to-file-20260406.md`) were believed filed via `/feedback` but never reached Anthropic. All four are being re-filed today via `gh issue create`.

## Expected behavior

At minimum: surface failure when the submission does not reach Anthropic. No silent SHA-confirming "success."

Preferred: return a trackable URL where the user can verify the submission exists on Anthropic's side.

Best: route `/feedback` through a public, documented channel (e.g., GitHub Issues on anthropics/claude-code with a templated form). Closes the trust loop completely.

## Root cause (suspected)

Without access to the internal implementation, this is speculation. Possibilities include: backend endpoint change with stale client, feedback-submission code path stubbed during refactor and never re-enabled, network/auth errors being swallowed silently. The key failure mode in all of these: the command does not surface failure to the user.

## Why this matters

**This is a meta-bug.** It's the reason other feedback items don't reach Anthropic. When the feedback channel is broken, users who care about improving the product stop trying. The users who don't stop find workarounds that fragment feedback across channels.

**Trust decays fast.** After discovering multiple silent drops, developers stop using `/feedback` entirely. Every user who has this experience is an advocate lost.

**The observable pattern is concerning.** A developer tool's feedback channel being silently broken is the specific failure mode that signals "the team building this doesn't dogfood the feedback loop." I don't believe that's actually true for Anthropic — but that's how the current state reads from the outside.

**The fix is simple.** "Return an error when something fails" is not a major redesign. It is hygiene.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency
- **Claude Code version:** (fill at submission time — `claude --version`)

## Related

- This is one of a batch of feedback items being filed today (2026-04-11) to clear a backlog that accumulated because `/feedback` was untrusted.
- Related public tweet: [@AgencyGroupAI 2026-04-11](https://twitter.com/AgencyGroupAI) — documents the same silent-failure pattern in the Anthropic API content filter.
- Related filing (already landed): [#45017](https://github.com/anthropics/claude-code/issues/45017) — silent periodic tool calls, filed 2026-04-08 via both `/feedback` and `gh` as a belt-and-suspenders.

---

## Revisit triggers

File immediately. This is the blocking meta-bug for the entire feedback backlog. No revisit conditions — proceed to file on principal approval.

## Conversation source

Captured during the Day 36-37 captain session on 2026-04-11 when the principal observed "I think we had written a number and never sent them out." Investigation of `usr/jordan/captain/anthropic-issues-to-file-20260406.md` revealed four items drafted on April 6 that were believed filed but had never reached Anthropic. Principal response: *"Because feedback was broken. Remember."*
