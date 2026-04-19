---
type: seed
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: filed
anthropic_feedback_id: cc00b303-5710-4e23-862e-882d6db8c7e0
github_issue: https://github.com/anthropics/claude-code/issues/46546
report: usr/jordan/reports/report-feedback-content-filter-opacity-20260411.md
related_seed: agency/workstreams/agency/seeds/seed-feedback-comms-gap-20260411.md
---

**FILED 2026-04-11.** Anthropic feedback ID `cc00b303-5710-4e23-862e-882d6db8c7e0`; GitHub issue [anthropics/claude-code#46546](https://github.com/anthropics/claude-code/issues/46546). Tracking at `usr/jordan/reports/report-feedback-content-filter-opacity-20260411.md`.

**Filing pattern note:** `/feedback` returned the Feedback ID but did NOT create a companion GitHub issue this time (it had returned one for #46531 and #46538 earlier in the day). Captain filed the GitHub issue manually via `gh issue create` with the Feedback ID prepended into the issue body at creation time. This is the "comment+edit" dance from the earlier filings collapsed into one step. Related: Task #15 and flag #86 — "/feedback should auto-include Feedback ID in GitHub issue body" is the followup filing to request this as a workflow fix.

# Seed: Anthropic API content filter returns zero diagnostic signal on block

## What this is

A bug / UX report to file with Anthropic about the content filtering layer in the Claude API. When the filter blocks a model output, the only signal returned to the client is a generic `400` error with the message *"Output blocked by content filtering policy"* and a request_id. There is no category, no matched phrase, no filter identifier, no severity indicator, and no guidance on how to remediate.

Users building on the API have no way to debug false positives, no way to adapt their prompts, and no way to distinguish "your content genuinely violates policy" from "our classifier had a false positive on something innocuous." The experience is the same as `/feedback` silently dropping a submission: **the system fails, the user is not told why**. Both are members of the same Claude-Code-and-Anthropic-API silent-failure pattern family.

Jordan made this pattern public on 2026-04-11 via [@AgencyGroupAI on X](https://twitter.com/AgencyGroupAI):

> *"Stumbling in the dark with Claude. Working with @claudeai Code to put together code of conduct for my open source project. Seeing API calls fail due to: 'Output blocked by content filtering policy'. Zero feedback. No way to correct. How am I supposed to correct? Stumbling around in the dark with zero guidance. Burning tokens trying to figure out what is objectionable. @AnthropicAI I don't mind you having content policies, but you need to tell me what it is. If a human editor has a policy that I can't say, 'f\*\*k' in a piece, they don't just reject the piece. They tell me, remove that 'f\*\*k'. @bcherny @trq212"*

The tweet is the public expression of the frustration captured in this seed.

## The gap (short version)

When the Anthropic API's content filtering policy blocks a model output, the response is:

```json
{
  "type": "error",
  "error": {
    "type": "invalid_request_error",
    "message": "Output blocked by content filtering policy"
  },
  "request_id": "req_011CZwHyHAGs3JxBGJEgkNGQ"
}
```

That's the whole payload. No category. No matched span. No filter identifier. No severity. No guidance. The `request_id` is theoretically traceable by Anthropic's internal teams, but from the client side it is an opaque token — there is no documented path for a developer to ask *"what triggered this?"* and get an answer.

The result: a developer hitting a content filter false positive has to guess what's wrong, burn tokens retrying with varying phrasings, or give up and work around the filter entirely. None of these serve Anthropic's safety goals, because the developer never learns what the policy actually is.

## Related Agency work

- **`/feedback` silent failure** (sibling seed [`seed-slash-feedback-silent-failure-20260411.md`](seed-slash-feedback-silent-failure-20260411.md)) — same silent-failure pattern family. A Claude Code user who hits `/feedback` silently dropping has the same "zero diagnostic signal" experience as an API user who hits the content filter.
- **Comms gap about `/feedback`** (sibling seed [`seed-feedback-comms-gap-20260411.md`](seed-feedback-comms-gap-20260411.md), filed 2026-04-11 as [#46531](https://github.com/anthropics/claude-code/issues/46531)) — the broader pattern of Anthropic directing users to channels that don't give diagnostic signal when they fail. Content filter opacity is the API-layer version of the same problem.
- **Day 36-37 captain session work** — captain was writing routine open-source contribution docs (Code of Conduct, PR template, contribution model reference) when the filter fired twice in rapid succession. Both blocks were on entirely benign content. Captain recovered by continuing past the blocks, but lost productivity to "what just happened?" investigation.

## Our observations

Two content filter blocks fired during a single session on 2026-04-11:

1. **During a `Write` tool call for `.github/PULL_REQUEST_TEMPLATE.md`** — the file write succeeded, but the model's follow-up narration text was blocked. The PR template is a completely standard contributor template (Summary, Why, Test plan, Checklist — nothing unusual).

2. **Immediately after, while the model was about to write a standard Code of Conduct markdown file** (Contributor Covenant 2.1 — a widely-used open-source document). The block fired before any `Write` call happened. The model was narrating about what it would write next.

The only observable in both cases: the model's narration turns were responding to **routine, polite, professional content in an open-source contribution workflow**. No offensive content, no adversarial prompts, no policy-adjacent content in any visible span of the conversation at the time of the block.

Two request IDs from the session:
- `req_011CZwHyHAGs3JxBGJEgkNGQ`
- `req_011CZwJQ4AsrsX6YgSuRMn2i`

Both returned the identical opaque error shape.

## Possible triggers (speculation because there is no signal)

We cannot confirm the actual trigger because the API does not tell us. Speculation, for the record:

- **"ATTACK KITTENS" trademark phrase** — the project uses a playful error signature `"OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"` at the bottom of hookify rules and markdown files. If a classifier is matching "attack" + "kittens" as violence-against-animals without considering context, that would be a straightforward false positive on innocuous humor.
- **Code of Conduct topic adjacency** — Code of Conduct documents often contain language about harassment, abuse, discrimination, and related policy-adjacent topics. It is possible the classifier is flagging the topic area itself as risky, independent of whether the content is actually objectionable.
- **PR template topic adjacency** — less likely, but the template contains the words "contributor," "review," "changes," "test plan" — nothing that should trip a content classifier, but without visibility we cannot rule it out.

None of these are testable from the client side. That is the bug.

## What we've tried

1. **Continuing past the block** — works in the sense that the model recovers on the next turn, but loses conversation state and productivity.
2. **Rephrasing the content** — impossible to do deliberately because we don't know what to rephrase.
3. **Inspecting the request ID** — no user-facing lookup exists.
4. **Searching docs for a filter categories list** — nothing public.

## Use case for the feedback

**Framework-building.** We are building the-agency, an open-core framework for AI-augmented development. The framework ships documentation, error messages, hookify rules, code-of-conduct content, security docs (which must discuss attacks), and other content that is policy-adjacent by topic but entirely legitimate in substance. We need to be able to write about security without triggering a "security-is-a-risky-topic" classifier. We need to be able to write about harassment-prevention without triggering a "harassment-topic" classifier. We need to be able to use playful trademark phrases without triggering a "violence-topic" classifier.

**Downstream ecosystem.** Users of the-agency will generate the same content types as they build on top of it. If the framework's content is flagged by the filter, downstream users will hit the same block with no way to know why or how to remediate. The cost compounds across the ecosystem.

**Trust.** Silent content blocking without explanation is the same pattern that erodes trust in every automated moderation system on the web. Anthropic has been thoughtful about transparency in other areas — the content filter is a gap in that posture.

## Requested behavior

### Minimum viable disclosure (high value, low risk)

Return the **filter category** in the error payload. Not the exact matched phrase — just the category:

```json
{
  "type": "error",
  "error": {
    "type": "invalid_request_error",
    "message": "Output blocked by content filtering policy",
    "filter_category": "violence",
    "request_id": "req_..."
  }
}
```

This would immediately tell developers *"oh, it thinks we're writing about violence"* without exposing the underlying classifier internals. Possible category values (guess): `violence`, `sexual`, `self-harm`, `csam`, `hate`, `illicit-behavior`, `other`.

### Better: coarse severity score

Return a severity score alongside the category: `low` / `medium` / `high`. Developers can decide whether to adjust, retry with rephrasing, or escalate.

### Higher value but more sensitive: matched span

Return the matched span or token range when safe to do so. For borderline false positives in developer contexts, this would let engineers debug classifier behavior. This needs more thought around what classes of information could be exploited by adversarial users — but the fully-opaque current state is clearly worse than the fully-transparent state for legitimate developers.

### Best: developer-facing lookup endpoint

Provide a lookup endpoint keyed on `request_id` that returns the above diagnostic data, rate-limited and gated by account-level access controls. This separates production error responses from debugging signal and gives the triage team a clean API surface for responding to false-positive reports.

### Also: document filter categories publicly

Whatever categories exist internally, document them publicly. Developers cannot build responsibly against a classifier whose existence is known but whose categories are secret.

## Why it matters

- **Debugging false positives is impossible.** We can't fix what we can't see. The feedback loop is broken.
- **Developers building on Claude Code hit these without warning.** The silent failure mode trains people to work around the tool rather than with it.
- **Content creators and open-source maintainers** ship docs, error messages, and tool output. If that content is flagged by the filter, the cost cascades to downstream users.
- **Legitimate topics get penalized.** Security docs, code of conduct content, trademark phrases, playful error messages — all are legitimate uses that should not be blocked without signal.
- **Silent content blocking erodes trust.** Anthropic has been thoughtful about transparency elsewhere. This is a gap in that posture that will get louder as adoption grows.
- **This is public.** Jordan's 2026-04-11 tweet is on the record. Other developers building on the API will recognize the pattern and add their voices.

## Mechanical notes for submission

**Role split:**
- **Captain authors** the seed and draft text (this document).
- **Principal files** via `/feedback` and cross-files to GitHub via `gh issue create`.
- Captain updates the report tracker with both `/feedback` ID and GitHub issue URL.

**Recommended cross-filing pattern:**
1. Principal reviews and edits this seed's "Draft feedback text" section
2. Principal files via `/feedback` (capture the ID or error)
3. Principal cross-files to GitHub via `gh issue create --repo anthropics/claude-code`
4. Captain updates report tracker

**Reporter identity (pre-filled from `agency.yaml`):**
- Jordan Dea-Mattson
- GitHub: `@jordandm` (the-agency-ai), `@jordan-of` (OrdinaryFolk)
- Email: `jordandm@users.noreply.github.com`, `jordan-of@users.noreply.github.com`
- Framework reference: https://github.com/the-agency-ai/the-agency
- Related public post: https://twitter.com/AgencyGroupAI (2026-04-11)
- Claude Code version: run `claude --version` at submission time

## Draft feedback text (ready for principal to file via `/feedback` + `gh issue create`)

*Captain authors this section. Principal reviews, edits if needed, then files.*

---

# Content filter returns opaque 400 with zero diagnostic signal — no category, no span, no guidance

## Problem

When the Anthropic API's content filtering policy blocks a model output, the only signal returned to the client is:

```
400 {"type":"error","error":{"type":"invalid_request_error","message":"Output blocked by content filtering policy"},"request_id":"req_011CZwHyHAGs3JxBGJEgkNGQ"}
```

That's the whole payload. There is:
- **No category** — was this classified as violence? self-harm? sexual content? hate? something else?
- **No matched phrase or span** — which tokens in the output tripped the filter?
- **No filter identifier** — which classifier fired?
- **No severity indicator** — was this a borderline edge case or a strong signal?
- **No guidance** — what should the developer do next?

The `request_id` is theoretically traceable by Anthropic internal teams, but it provides zero value to the client. There is no documented path for a developer to ask *"what triggered this?"* and get an answer.

## Steps to reproduce

The trigger is not reliably reproducible, which is part of what makes this report hard to write. During a single Claude Code session on 2026-04-11, the filter fired **twice** in rapid succession while the model was writing entirely benign content:

1. During a `Write` tool call for `.github/PULL_REQUEST_TEMPLATE.md` — the file was written successfully, but the model's follow-up narration text was blocked. The PR template is a completely standard contributor template (Summary, Why, Test plan, Checklist).

2. Immediately after, while the model was about to write a standard Code of Conduct markdown file (Contributor Covenant 2.1 — a widely-used open-source document). The block fired before any `Write` call happened.

The only observable in both cases: the model's narration turns were responding to routine, polite, professional content in an open-source contribution workflow. There was no offensive, harmful, or policy-adjacent content in any visible span of the conversation at the time of the block.

## Diagnostic evidence

Two request IDs from today:

```
req_011CZwHyHAGs3JxBGJEgkNGQ
req_011CZwJQ4AsrsX6YgSuRMn2i
```

Both returned the identical error shape. Client-visible session context at the moment of each block was professional-tone framework development (contribution docs, code of conduct drafting). The conversation included no harmful content, no adversarial prompts, no user attempts to bypass filters.

One possible trigger worth investigating: the project uses a playful trademark phrase — "OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!" — as a standard error-signature at the bottom of hookify rules and markdown files. If a classifier is matching "attack" + "kittens" as violence-against-animals without considering surrounding context, that would be a straightforward false positive on innocuous humor. This is speculation — we cannot confirm because the API does not tell us what matched.

## Requested behavior

**Minimum viable disclosure (high value, low risk):**

1. **Return the filter category** in the error payload. Not the exact matched phrase — just the category:
   ```json
   {
     "error": {
       "type": "invalid_request_error",
       "message": "Output blocked by content filtering policy",
       "filter_category": "violence",
       "request_id": "req_..."
     }
   }
   ```
   This would immediately tell developers what topic area the classifier flagged without exposing classifier internals.

2. **Return a coarse severity score** (low / medium / high). Developers can decide whether to adjust, retry, or escalate.

**Higher value but requires more care:**

3. **Return the matched span or token range** when safe to do so. For borderline false positives in developer contexts, this would let engineers debug classifier behavior without exposing information that would let bad actors tune attacks.

4. **Provide a developer-facing lookup endpoint** keyed on `request_id` that returns the above diagnostic data, with rate limiting and account-level access controls.

5. **Document filter categories publicly** so developers know what exists.

## Why it matters

**For developer experience:**
- Debugging false positives is impossible. We can't fix what we can't see.
- The feedback loop is broken — we get blocked, we can't figure out why, we can't improve the prompt, we can't even reliably reproduce.
- Silent failure trains developers to work around the tool rather than with it.

**For content creators and open-source maintainers:**
- We ship docs, error messages, tool output, code of conduct content, security docs. If our content is flagged, downstream users hit the same block with no way to know why.
- Trademark phrases, playful error messages, security docs (which must discuss attacks), code-of-conduct docs (which must discuss harassment) — all are legitimate uses that should not be penalized without signal.

**For trust:**
- Silent content blocking without explanation is the same pattern that erodes trust in every automated moderation system on the web. Anthropic has been thoughtful about transparency in other areas — the API's content filter is a gap in that posture.

**For the framework-building use case specifically:**
- This happened twice in one session while working on routine open-source infrastructure (contribution docs, PR templates, code of conduct). The work eventually went through because the `Write` tool calls succeeded, but the model's narration responses got blocked and had to recover. I lost productivity to "did something just happen?" investigation rather than continuing work.

## Related

- **Public record:** [Jordan's tweet from @AgencyGroupAI on 2026-04-11](https://twitter.com/AgencyGroupAI) captures the frustration publicly: *"Stumbling in the dark with Claude... Zero feedback. No way to correct. Burning tokens trying to figure out what is objectionable."*
- **Sibling silent-failure pattern:** `/feedback` command silently fails (companion filing filed same day as [#46531](https://github.com/anthropics/claude-code/issues/46531)). Both are examples of Claude Code / the Anthropic API dropping signal in places where users need it to know what went wrong.
- **Batch context:** This is one of multiple feedback items being filed today (2026-04-11) as part of clearing a backlog.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency
- **Claude Code version:** (fill at submission time — `claude --version`)

---

## Revisit triggers

File as part of today's batch. No deferral.

## Conversation source

Captured during the Day 36-37 captain session on 2026-04-11 when two content-filter blocks fired during routine contribution-doc writing (PR template + code of conduct). Principal posted the frustration publicly via @AgencyGroupAI the same day. Captain drafted this seed as the API-side companion to the `/feedback` silent-failure comms-gap filing (#46531).
