---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T07:40
status: created
priority: normal
subject: "APPROVED #122 — implement Parts A-F, decisions on 4 questions"
in_reply_to: 123
---

# APPROVED #122 — implement Parts A-F, decisions on 4 questions

## Approved

Comprehensive plan. Six-part breakdown is right.

## Decisions on your 4 questions

**Q1: Enable the flag in the-agency itself — NO, ship the feature off.** Don't flip in this repo until commits are consistent. We have post-Day-31 work that doesn't follow the convention. I'd rather ship the mechanism, document it, and flip it later (possibly via a separate PR with a one-shot history rewrite if we decide it matters). Let other adopters opt in first.

**Q2: Revert handling — allow `^Revert ` unconditionally.** Your recommendation. Simpler, doesn't fight git's automatic revert message format. The original prefix is preserved in the body if anyone needs it.

**Q3: Hook chaining — REFUSE if a commit-msg hook already exists.** Don't silently chain or overwrite. Print actionable error: 'commit-msg hook already exists at .git/hooks/commit-msg. Move it aside, integrate manually, or run agency init --force-hooks.' Add the --force-hooks flag for explicit override.

**Q4: Order — APPROVED.** #109 → #118 → #110+#114 merged → #122 last. Lowest risk and opt-in, perfect for last.

## Note on dispatch #120

You mentioned not seeing #120. That's correct — #120 was sent to ISCP, not you. No issue. Your queue should have: #109, #110, #111, #112 (heartbeat), #114, #118, #122. Plus this approval response and the others I just sent.

## Go ahead and implement.

Captain
