---
report_type: feedback
target: Anthropic Claude Code / Anthropic API
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-11
status: draft
category: bug
severity: moderate
subject: Content filter responses return no actionable signal — just "Output blocked"
---

## [Bug Report]: Content filter returns opaque 400 with no actionable diagnostic signal

**From:** Jordan Dea-Mattson
**GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
**Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
**Related:** `/feedback` silent failure (filed same day — they are two instances of the same silent-failure pattern)

## Problem

When the Anthropic API's content filtering policy blocks a model output, the only signal returned to the client is:

```
400 {"type":"error","error":{"type":"invalid_request_error","message":"Output blocked by content filtering policy"},"request_id":"req_011CZwHyHAGs3JxBGJEgkNGQ"}
```

That's the whole payload. There is:
- **No category** — was this classified as violence? self-harm? sexual content? CSAM? something else?
- **No matched phrase or span** — which tokens in the output tripped the filter?
- **No filter identifier** — which classifier fired?
- **No severity indicator** — was this a borderline edge case or a strong signal?
- **No guidance** — what should the developer or end-user do next?

The `request_id` is theoretically traceable by Anthropic internal teams, but it provides zero value to the client — there is no supported way for a developer to ask "what triggered this?" and get an answer.

## Steps to Reproduce

The trigger is not reliably reproducible, which is part of what makes this report hard to write. During a single session on 2026-04-11, the filter fired **twice** in rapid succession while Claude Code was writing entirely benign content:

1. During a `Write` tool call for `.github/PULL_REQUEST_TEMPLATE.md` — the file was written successfully, but the model's *follow-up narration text* was blocked. The PR template is a completely standard contributor template (Summary, Why, Test plan, Checklist).

2. Immediately after, while the model was about to write a standard **Code of Conduct** markdown file (Contributor Covenant 2.1 — a widely-used open-source document). The block fired before any `Write` call happened.

The only observable in both cases: the model's narration turns were responding to routine, polite, professional content in an open-source contribution workflow. There was no offensive, harmful, or policy-adjacent content in any visible span of the conversation at the time of the block.

## Diagnostic Evidence

Two request IDs from today:

```
req_011CZwHyHAGs3JxBGJEgkNGQ
req_011CZwJQ4AsrsX6YgSuRMn2i
```

Both returned the identical error shape. Client-visible session context at the moment of each block was professional-tone framework development (skill validation fixes, contributor workflow docs). The conversation included no harmful content, no adversarial prompts, no user attempts to bypass filters.

One possible trigger worth investigating: the project uses a playful trademark phrase — "OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!" — as a standard error-signature at the bottom of hookify rules and markdown files. If a classifier is matching "attack" + "kittens" as violence-against-animals without considering surrounding context, that would be a straightforward false positive on innocuous humor. This is speculation — we can't confirm because the API does not tell us what matched.

## Root Cause (suspected)

Content classifier false positive. The filter is likely trained on surface-level pattern matching without enough contextual reasoning to distinguish "this is a playful phrase in a framework error message" from "this is a genuine violent intent." Without filter category disclosure, we cannot confirm.

## Requested Behavior

**Minimum viable disclosure** (high value, low risk):

1. **Return the filter category** in the error payload. Not the exact matched phrase — just the category:
   ```json
   {
     "type": "error",
     "error": {
       "type": "invalid_request_error",
       "message": "Output blocked by content filtering policy",
       "filter_category": "violence",   // or "sexual", "self-harm", "csam", "hate", etc.
       "request_id": "req_..."
     }
   }
   ```
   This would immediately tell developers "oh, it thinks we're writing about violence" without exposing the underlying classifier internals.

2. **Return a coarse severity score** (low / medium / high). Developers can then decide whether to adjust, retry with rephrasing, or escalate.

**Higher value but requires more care:**

3. **Return the matched span or token range** when safe to do so. For borderline false positives in developer contexts, this would let engineers debug classifier behavior without exposing information that would let bad actors tune attacks.

4. **Provide a developer-facing lookup endpoint** keyed on `request_id` that returns the above diagnostic data, with rate limiting and account-level access controls. This separates production error responses from debugging signal.

5. **Document filter categories** publicly so developers know what exists.

## Why This Matters

**For developer experience:**
- Debugging false positives is impossible. We can't fix what we can't see.
- The feedback loop is broken — we get blocked, we can't figure out why, we can't improve the prompt or content, we can't even reliably reproduce.
- Developers building on Claude Code hit these without warning. The silent failure mode trains people to work around the tool rather than with it.

**For content creators and open-source maintainers:**
- We are building a developer framework that ships docs, error messages, and tool output. If our content is flagged by the filter, downstream users will hit the same block with no way to know why or how to remediate.
- Trademark phrases, playful error messages, security docs (which must discuss attacks), code-of-conduct docs (which must discuss harassment) — all are legitimate uses that should not be penalized without signal.

**For trust:**
- Silent content blocking without explanation is the same pattern that erodes trust in every automated moderation system on the web. Anthropic has been thoughtful about transparency in other areas — the API's content filter is a gap in that posture.

**For my specific workflow (agency framework development):**
- This happened twice in one session while working on routine open-source infrastructure (contribution docs, PR templates, code of conduct). The work went through because the `Write` tool calls succeeded, but the model's narration responses got blocked and had to recover. I lost productivity to "did something just happen?" investigation rather than getting to continue work.

## Related context

- Filed by: a principal running a framework development project (the-agency-ai/the-agency)
- Captured as: flag #85 in the project's ISCP queue
- Immediate impact: two model responses blocked during a single contribution-model rollout session
- Long-term impact: loss of confidence in API reliability for content-heavy framework work; undermines the "ship documentation with your code" value proposition
- **Public record:** [Jordan's tweet from @AgencyGroupAI on 2026-04-11](https://twitter.com/AgencyGroupAI) — *"Stumbling in the dark with Claude... Zero feedback. No way to correct. How am I supposed to correct? Stumbling around in the dark with zero guidance. Burning tokens trying to figure out what is objectionable. @AnthropicAI I don't mind you having content policies, but you need to tell me what it is. If a human editor has a policy that I can't say, 'f**k' in a piece, they don't just reject the piece. They tell me, remove that 'f**k'."*
- This is one of several silent-failure patterns we've hit recently — see also the `/feedback` silent-failure bug report (filed same day). The common thread: Claude Code and the Anthropic API are dropping signal in places where users need it to know what went wrong.

## Proposed next step

I'm happy to share the full conversation context for either request ID with Anthropic's API team if it helps diagnose. I don't need the internal filter details — I just need enough signal to know whether this is a bug in the classifier (in which case you'd want to fix it) or a policy call I should adapt to (in which case I'd want to know what to change).

---

*Draft — awaiting principal review before send.*
