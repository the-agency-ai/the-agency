---
type: seed
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: filed
anthropic_feedback_id: 95fe4771-6780-4be7-9e8e-30d7feea3496
github_issue: https://github.com/anthropics/claude-code/issues/46531
report: usr/jordan/reports/report-feedback-comms-gap-20260411.md
related_seed: agency/workstreams/agency/seeds/seed-slash-feedback-silent-failure-20260411.md
priority: file-first
---

**FILED 2026-04-11.** Anthropic feedback ID `95fe4771-6780-4be7-9e8e-30d7feea3496`; GitHub issue [anthropics/claude-code#46531](https://github.com/anthropics/claude-code/issues/46531). Tracking at `usr/jordan/reports/report-feedback-comms-gap-20260411.md`.

**Notable data point:** `/feedback` successfully filed this submission and returned both a feedback ID and a GitHub URL — the channel is not universally broken, it is intermittent. This does not invalidate the comms-gap framing; it reinforces it. Users cannot distinguish "currently working" from "currently broken" from "silently dropping" without filing and waiting for visible evidence. That is the point.

# Seed: Claude Code team publicly directs users to `/feedback` while it has been broken for 5+ months

## What this is

A feedback report to file with Anthropic about a **communications gap**, not (directly) the underlying technical bug. The technical bug — `/feedback` silently failing or failing with an unhelpful error — has been publicly documented since at least November 2025. It is [GitHub issue #10905](https://github.com/anthropics/claude-code/issues/10905), which was CLOSED without a confirmed fix, auto-locked, and has multiple user comments reporting continued failure **after** the closure. A related duplicate ([#12638](https://github.com/anthropics/claude-code/issues/12638)) was filed November 28 2025, marked as duplicate, and closed the same way.

Despite the underlying bug being known for this long, **the Claude Code team has continued to publicly direct users to file via `/feedback`** — including during high-visibility incidents like the Opus 4.5 degradation concerns in February 2026. This is the gap being reported: **Anthropic is routing users to a broken channel while telling them it's the right channel, and the public tickets documenting the breakage are closed and locked so the gap is invisible to users who search before filing.**

This is not "Anthropic has a bug." This is "Anthropic's public communications are actively misdirecting users to a broken tool, and the user community is carrying that cost." The two together are worse than either alone.

**File this one FIRST** — before the companion technical bug report ([`seed-slash-feedback-silent-failure-20260411.md`](seed-slash-feedback-silent-failure-20260411.md)) — because the comms gap is the higher-level issue that contextualizes the technical bug. Once this is on record, the technical bug report lands with stronger framing.

## The gap (short version)

1. `/feedback` has been broken for months (documented in #10905, #12638, and user comments).
2. GitHub issues about it are **closed** and **auto-locked**, so new users searching before filing see "closed" and assume "fixed."
3. The Claude Code team (specifically [@trq212](https://x.com/trq212/status/2001541565685301248) in February 2026) has publicly directed users to `/feedback` during real incidents.
4. Users following that public guidance get silent drops or cryptic errors with no diagnostic signal (the errors aren't even logged to `~/.claude/debug/`).
5. Users cannot file about the broken state because the canonical issue is auto-locked.
6. The command is called `/feedback` in the CLI and `/bug` in the documentation, so searching doesn't reliably find the existing ticket ([#28565](https://github.com/anthropics/claude-code/issues/28565) tracks this naming inconsistency).

Each of those steps is survivable individually. Together they form a closed trust loop where **users cannot get feedback about feedback to reach Anthropic.**

## The evidence

### 1. The bug has been publicly known since November 2025

**[#10905 "[BUG] /feedback not working for bug reports"](https://github.com/anthropics/claude-code/issues/10905)**
- Filed by: `santoshmano` (Santosh Manoharan)
- Labels: `area:tui`, `bug`, `has repro`, `platform:macos`
- State: **CLOSED**
- Comments: 21

Relevant comment quotes from #10905:

> **"This has been broken for several months. I've never, ever been able to submit. It always just says 'Could not submit feedback. Please try again later.', then it lets me futilely try again, then fails completely."**
> — user comment on #10905

> **"Same issue on macOS (Darwin 25.2.0), Claude Code v2.1.56, Anthropic API. On the first attempt, the error is clear... But when you retry, the command exits silently with no indication of whether the submission succeeded or failed..."**
> — `ert485` on #10905

> **"I ran into this today as well. I'm using claude-code version 2.1.58 on MacOS Tahoe 26.3.1. At the very least it would be good to fix the 'press enter to retry' part so that people don't lose the bug report they just finished typing in."**
> — `falcon838a` on #10905

> **"Still not working for me"** (with screenshots of continued failure)
> — `ert485` on #10905

> **"I've always used a personal GitHub account"** (rebutting the theory that it's a GitHub auth issue)
> — `marcoscale98` on #10905

> **"Additionally, the feedback submission failure doesn't get logged to the debug files (`~/.claude/debug/`). Those files capture API calls, tool use, and hook events, but the `/feedback` network request and its error are not recorded."**
> — `ert485` on #10905 (critical meta-observation)

And then the kicker: **the issue is auto-locked:**

> *"This issue has been automatically locked since it was closed and has not had any activity for 7 days. If you're experiencing a similar issue, please file a new issue and reference this one if it's relevant."*

So the canonical ticket is invisible to new users (closed state = "resolved" in most users' mental model) and cannot be updated to reflect reality. The loop closes.

### 2. The duplicate was also closed

**[#12638 "Feedback command fails to submit report to Anthropic API"](https://github.com/anthropics/claude-code/issues/12638)**
- Filed by: `JeffreyUrban` (Jeffrey Urban)
- Filed: 2025-11-28
- Labels: `duplicate`
- State: **CLOSED** (auto-closed as duplicate of #10905)

The bug is reproducible on Claude Code v2.0.55 on macOS (Darwin, PyCharm terminal). Error details from the filing include a "Plugin source missing" stack trace — a concrete technical hint about where the failure is happening, but the issue was closed as a duplicate without triage acknowledging the diagnostic data.

### 3. The documentation/CLI naming mismatch obstructs search

**[#28565](https://github.com/anthropics/claude-code/issues/28565)** tracks the fact that the command is called `/feedback` in the CLI but `/bug` in the documentation. This is why users searching before filing don't find #10905 — they search for `/feedback` and the docs talk about `/bug`, or vice versa. The naming inconsistency is itself a discoverability failure that compounds the comms gap.

### 4. The team continues to publicly direct users to the broken channel

**Thariq [@trq212](https://x.com/trq212) — Claude Code engineer** — [posted on X](https://x.com/trq212/status/2001541565685301248):

> *"We've received some feedback about a potential degradation of Opus 4.5 specifically in Claude Code. We're taking this seriously: we're going through every line of code changed and monitoring closely. **In the meantime please submit any transcripts with issues through /feedback**"*

This post was during a real incident (Opus 4.5 degradation concerns). Users reading it — Claude Code customers concerned about model quality — would naturally follow the directive and try `/feedback`. They would hit the bug that has been known for months and is documented in a closed auto-locked issue. They would have no way to verify whether their transcript reached the team. The people the team was asking for help from were being routed into a broken funnel.

Boris Cherny ([@bcherny](https://x.com/bcherny)) — Claude Code creator — has similarly directed users to feedback channels in public posts around new feature launches. The pattern is systemic, not a one-off from Thariq.

### 5. Our direct experience

We (the-agency framework development project) filed the silent-periodic-tool-calls feedback on 2026-04-08 via `/feedback`. It returned Anthropic feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add`. We also cross-filed to GitHub as [#45017](https://github.com/anthropics/claude-code/issues/45017) as a belt-and-suspenders. The GitHub issue landed visibly. The `/feedback` ID is an opaque token we have no way to verify reached the triage queue — which we only realized was a real concern after trying to file subsequent items across April 2026 and seeing them drop into the same opaque abyss.

We then discovered we had accumulated **four other feedback items** in a local tracking file (`anthropic-issues-to-file-20260406.md`) that we believed filed via `/feedback` over the course of a week but that never produced any visible outcome. All four are being re-drafted today and filed via `gh issue create` to clear the backlog. This incident is what triggered the seed you're reading.

Jordan made the underlying experience public via [@AgencyGroupAI on 2026-04-11](https://twitter.com/AgencyGroupAI):

> *"Stumbling in the dark with Claude. Working with @claudeai Code to put together code of conduct for my open source project. Seeing API calls fail due to: 'Output blocked by content filtering policy'. Zero feedback. No way to correct. How am I supposed to correct? Stumbling around in the dark with zero guidance. Burning tokens trying to figure out what is objectionable. @AnthropicAI I don't mind you having content policies, but you need to tell me what it is. If a human editor has a policy that I can't say, 'f\*\*k' in a piece, they don't just reject the piece. They tell me, remove that 'f\*\*k'. @bcherny @trq212"*

The tweet targets the content filter silent-failure pattern specifically, but the underlying complaint — *"no way to know what went wrong"* — is the same failure mode as the `/feedback` drop. Users have lost the ability to get signal back from the channels they're being told to use.

## Our research

1. **GitHub search for "[BUG] /feedback not working"** — lands on #10905 and #12638. Both closed. Multiple comments reporting continued failure after closure.
2. **GitHub search for "duplicate /feedback"** — surfaces an ongoing pattern of new issues being filed, auto-deduped, auto-closed, and auto-locked. The pattern is now months deep. Each new affected user files, gets deduped, and the trail goes cold.
3. **X/Twitter search for `/feedback bcherny OR trq212`** — confirms the Claude Code team's public posture is to direct users to `/feedback`. Specifically Thariq's February 2026 post during Opus 4.5 degradation is the most visible and recent example, but the pattern is broader.
4. **Anthropic documentation search for `/bug` vs `/feedback`** — confirms the naming inconsistency documented in #28565. The `/bug` command (or slash command page) is documented; the `/feedback` name used by the CLI is not consistently documented. This makes it harder for users to search for existing reports before filing, compounding the dedupe-and-lose cycle.

## Why it matters — what the comms gap actually costs

**For users:**
- Burn trust in the feedback system — users try once, fail silently, and stop filing forever
- Lose bug report content — users type out detailed reports and the retry path has lost input in some versions
- Waste time searching — the naming mismatch + closed-duplicate cycle hides the known issue from people trying to do the right thing
- Create a fragmented feedback surface — affected users end up filing on Discord, Twitter, Reddit, private Slack communities, or not at all, because the "official" path is broken

**For Anthropic:**
- Loses a huge portion of high-signal developer feedback — exactly the feedback Anthropic has consistently said they want
- Every public "please file via /feedback" post is a moment where the team is unintentionally sending a cohort of users into a broken funnel — creating negative sentiment that the team never hears about because the channel they'd hear about it through is broken
- The closed-and-locked pattern for the underlying bug creates an information asymmetry: the team doesn't see ongoing reports because they're blocked from being filed
- This directly contradicts the "we take feedback seriously" posture — not because it's insincere, but because the instrument is broken and nobody upstream has the feedback to know

**For the developer ecosystem around Claude Code:**
- Framework builders (like us, building `the-agency`) who file feedback regularly either stop using Claude Code for feedback-heavy work or build elaborate workarounds. Both outcomes are bad for Anthropic.
- Public posts like Jordan's tweet today become the visible channel — meaning the feedback Anthropic DOES get is skewed toward whoever is willing to go public on social media, which is not a representative sample.

## Requested behavior

This is a **communications fix**, not (only) a technical fix. The technical fix is covered in the companion seed `seed-slash-feedback-silent-failure-20260411.md`. The communications fix requested here:

### Priority 1 — Acknowledge the broken state publicly

- Post a pinned acknowledgment in the claude-code GitHub repo readme or issues page that `/feedback` is currently unreliable and users should file via GitHub Issues or the `/bug` command directly until further notice.
- Re-open #10905 (or file a new canonical tracking issue) with current status and a commitment to fix or deprecate.
- Update the closed/locked state of the existing issues so users searching find an active ticket.

### Priority 2 — Stop directing users to the broken channel

- Review outstanding public posts from the Claude Code team (Twitter/X, Threads, Discord, blog) that reference `/feedback` and either update them with a note about the current state or remove the directive.
- Establish an internal checklist: no public communication should direct users to `/feedback` until it is known-working and monitored.

### Priority 3 — Fix the discoverability problem

- Resolve the `/feedback` vs `/bug` naming inconsistency (#28565) so future users searching for existing reports find them.
- Add `/feedback` failure diagnostics to `~/.claude/debug/` so users hitting the bug can include real diagnostic data in their GitHub filings.
- Give the auto-dedupe bot a "this issue is actually still a problem" escape hatch so real affected users can reopen instead of being auto-closed into silence.

### Priority 4 — Close the loop with a public post-mortem

- Once `/feedback` is fixed, publish a short post-mortem about how the comms gap persisted for months and what's changed to prevent recurrence. This is the "three recent issues" post-mortem Anthropic published for engineering incidents — same principle.
- This is not about blame. It's about showing the community that the feedback loop is valued enough to get fixed visibly.

## Mechanical notes for submission

**Role split:**
- **Captain authors** the seed and draft text (this document).
- **Principal files** the feedback via `/feedback` (as a final test of the broken channel) and cross-files to GitHub via `gh issue create` (the trusted path).
- Captain updates the report tracker with both the `/feedback` ID (if returned) and the GitHub issue URL.

**Recommended cross-filing pattern for this item specifically:**
1. Principal reviews this seed and approves the "Draft feedback text" section below
2. Principal files via `/feedback` first — explicitly attempting to file feedback ABOUT `/feedback` through the broken channel, as the most meta possible dogfooding of the issue. Capture the SHA it returns (or the error).
3. Principal cross-files to GitHub via `gh issue create --repo anthropics/claude-code` — this is the **canonical filing** since we expect `/feedback` to either drop it or return an unverifiable token.
4. **Do not file as a comment on #10905** — that issue is auto-locked. File as a new issue referencing #10905, #12638, #28565, #45017, and the Thariq/Bcherny tweets as context.
5. Captain updates report tracker and REPORTS-INDEX.md.

**Reporter identity (pre-filled from `agency.yaml`):**
- Jordan Dea-Mattson
- GitHub: @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- Email: jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- Framework reference: https://github.com/the-agency-ai/the-agency
- Related public post: https://twitter.com/AgencyGroupAI (2026-04-11)
- Claude Code version: run `claude --version` at submission time

**File first:** This seed is marked `priority: file-first` in the frontmatter. Of the batch of five+ feedback items being filed today, this one goes first so it can be referenced by the technical bug report that follows.

## Draft feedback text (ready for principal to file via `/feedback` + `gh issue create`)

*Captain authors this section. Principal reviews, edits if needed, then files.*

---

# Communications gap: `/feedback` has been broken for 5+ months while the Claude Code team publicly directs users to it

## Problem

This is a communications / product-trust issue, not (directly) a technical bug report. The technical bug — `/feedback` silently failing or failing with an unhelpful error — has been publicly documented since at least November 2025 in [#10905](https://github.com/anthropics/claude-code/issues/10905) and [#12638](https://github.com/anthropics/claude-code/issues/12638). Both issues are **closed** and **auto-locked**. Multiple users report in the comments that the bug continues to happen *after* closure, on recent Claude Code versions, across macOS and other platforms.

Despite the underlying bug being known for this long, members of the Claude Code team have continued to publicly direct users to file via `/feedback`. Most visibly, [@trq212 posted on X](https://x.com/trq212/status/2001541565685301248) during the Opus 4.5 degradation concerns in February 2026:

> *"We've received some feedback about a potential degradation of Opus 4.5 specifically in Claude Code. We're taking this seriously: we're going through every line of code changed and monitoring closely. **In the meantime please submit any transcripts with issues through /feedback**"*

Users following that guidance would hit the broken channel. They would get either a silent SHA drop or a cryptic "Could not submit feedback. Please try again later." error. They would have no way to verify whether their feedback reached Anthropic. The errors are not even logged to `~/.claude/debug/`, so they have no diagnostic trail to file a GitHub issue with.

Meanwhile, the canonical GitHub issue (#10905) is auto-locked. New users searching before filing see "closed" and assume "fixed." The duplicate detector auto-closes new reports as duplicates of the closed issue. The feedback loop is structurally shut.

This is the gap I'm reporting: **Anthropic is routing users to a broken channel while telling them it's the right channel, and the public tickets documenting the breakage are closed and locked so the gap is invisible to users who search before filing.**

## Evidence

### The underlying bug has been public for 5+ months

- [#10905 "[BUG] /feedback not working for bug reports"](https://github.com/anthropics/claude-code/issues/10905) — filed November 2025, CLOSED, auto-locked, 21 comments including multiple users reporting continued failure AFTER closure on Claude Code 2.1.56, 2.1.58, macOS Tahoe 26.3.1
- [#12638 "Feedback command fails to submit report to Anthropic API"](https://github.com/anthropics/claude-code/issues/12638) — filed 2025-11-28, auto-closed as duplicate of #10905. Contains specific diagnostic data including a "Plugin source missing" error trace.
- [#28565](https://github.com/anthropics/claude-code/issues/28565) — tracks the separate issue that the command is called `/feedback` in the CLI but `/bug` in the documentation, making search harder.

Representative comment from #10905:

> *"This has been broken for several months. I've never, ever been able to submit. It always just says 'Could not submit feedback. Please try again later.', then it lets me futilely try again, then fails completely."*

Another representative comment, noting a critical meta-observation:

> *"The feedback submission failure doesn't get logged to the debug files (`~/.claude/debug/`). Those files capture API calls, tool use, and hook events, but the `/feedback` network request and its error are not recorded."*

So users can't even include useful diagnostic data when they do manage to file a GitHub issue about the failure.

### The team continues to publicly direct users to the broken channel

- **Thariq [@trq212](https://x.com/trq212/status/2001541565685301248)** (February 2026, Opus 4.5 degradation concerns): *"In the meantime please submit any transcripts with issues through /feedback"* — during a real incident, directing concerned users into the broken funnel.
- **Boris Cherny [@bcherny](https://x.com/bcherny)** has similarly directed users to feedback channels in various launch and update announcements. Pattern is systemic, not a one-off.

### My direct experience (today, 2026-04-11)

As a developer building a framework (`the-agency-ai/the-agency`) on top of Claude Code, I file feedback against Claude Code regularly. Over the past week I accumulated **four separate feedback items** that I believed filed via `/feedback` but never produced any visible outcome. Today I discovered they were never delivered. I am filing them now via `gh issue create` directly. I also captured my frustration publicly on X: [@AgencyGroupAI 2026-04-11](https://twitter.com/AgencyGroupAI).

The only feedback item I can confirm reached Anthropic is one I **cross-filed** to both `/feedback` and GitHub on 2026-04-08 — [#45017](https://github.com/anthropics/claude-code/issues/45017). The GitHub path is the one I can verify. The `/feedback` path returned feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add`, which I have no way to look up or verify resolved to anything on Anthropic's side.

## Why this matters

### For users

- Trust in the feedback system is being burned. Users try once, fail silently, and stop filing forever. Every such user is an advocate lost and a signal source gone dark.
- Detailed bug reports are being lost — users type them out and the retry path has lost input in some versions.
- The naming mismatch + closed-duplicate cycle hides the known issue from people trying to do the right thing.
- Affected users end up on Discord, Twitter, Reddit, or private Slack communities because the "official" path is broken. Feedback is fragmenting away from Anthropic.

### For Anthropic

- You are losing a significant chunk of high-signal developer feedback — exactly the feedback you've consistently said you want.
- Every public "please file via /feedback" post is a moment where your team is unintentionally sending a cohort of users into a broken funnel, creating negative sentiment you never hear about because the channel you'd hear about it through is broken.
- The closed-and-locked pattern for the underlying bug creates an information asymmetry: the team doesn't see ongoing reports because they're blocked from being filed.
- This directly contradicts the "we take feedback seriously" posture — not because it's insincere, but because the instrument is broken and nobody upstream has the feedback to know.

### For the developer ecosystem

- Framework builders (like me) who file feedback regularly either stop using Claude Code for feedback-heavy work or build elaborate workarounds. Both outcomes are bad for Anthropic.
- Public posts like my tweet today become the visible channel — meaning the feedback Anthropic DOES get is skewed toward whoever is willing to go public on social media, which is not a representative sample.

## Requested actions

### Priority 1 — Acknowledge publicly

Post a pinned acknowledgment in the claude-code GitHub repo readme or issues page that `/feedback` is currently unreliable and users should file via GitHub Issues directly until further notice. Re-open #10905 (or file a new canonical tracking issue) with current status and a commitment to fix or deprecate.

### Priority 2 — Stop directing users to the broken channel

Review outstanding public posts from the Claude Code team (Twitter/X, Threads, Discord, blog) that reference `/feedback` and update them with a note about the current state. Establish an internal checklist: no public communication should direct users to `/feedback` until it is known-working and monitored.

### Priority 3 — Fix discoverability

Resolve the `/feedback` vs `/bug` naming inconsistency (#28565). Add `/feedback` failure diagnostics to `~/.claude/debug/` so users hitting the bug can include real diagnostic data when filing on GitHub. Give the auto-dedupe bot an escape hatch so real affected users can reopen instead of being auto-closed into silence.

### Priority 4 — Post-mortem

Once `/feedback` is fixed, publish a short post-mortem about how the comms gap persisted for months and what's changed to prevent recurrence. Same principle as [Anthropic's engineering postmortems](https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues) — visible ownership of the failure builds trust that's currently being eroded.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency
- **Public post:** https://twitter.com/AgencyGroupAI (2026-04-11)
- **Claude Code version:** (fill at submission time — `claude --version`)

## Related issues and filings

- [#10905](https://github.com/anthropics/claude-code/issues/10905) — canonical `/feedback` bug (CLOSED, auto-locked)
- [#12638](https://github.com/anthropics/claude-code/issues/12638) — duplicate, closed same pattern
- [#28565](https://github.com/anthropics/claude-code/issues/28565) — `/feedback` vs `/bug` naming mismatch
- [#45017](https://github.com/anthropics/claude-code/issues/45017) — my previous successful cross-file (silent periodic tool calls)
- Anthropic feedback ID `8dd67e96-63ea-4a22-b687-d26a1b2d0add` — my `/feedback` submission corresponding to #45017 (opaque token, never verified)
- Companion technical bug report filed in the same batch as this one (seed file: `seed-slash-feedback-silent-failure-20260411.md`)
- [@trq212 February 2026 tweet](https://x.com/trq212/status/2001541565685301248) directing users to `/feedback`
- [@AgencyGroupAI 2026-04-11 tweet](https://twitter.com/AgencyGroupAI) — public expression of the same frustration about silent failures in Claude Code/Anthropic API

---

## Revisit triggers

File immediately. This is the first of the batch — the rest of the feedback items reference this one for context on why they're being filed via GitHub rather than `/feedback`.

## Conversation source

Captured during the Day 36-37 captain session on 2026-04-11, after the principal observed the content filter silent-failure pattern, the captain started drafting the technical `/feedback` bug report, and the principal observed: *"We also want to file about the fact that /feedback was down - for apparently a week - while we were being told by Boris and Thariq to file there. Separate item, but let's file it first and then cross reference the hash and the original github on it (search)?"*

Captain searched for and found #10905 (the canonical broken-for-months ticket) and Thariq's tweet directing users to the broken channel. The seed expanded from "about a week" to "5+ months" based on the evidence in #10905's filing date and comments.
