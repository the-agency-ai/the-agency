---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-07T07:40
status: created
priority: normal
subject: "APPROVED — per-agent inboxes + dispatch list direction-aware"
in_reply_to: 121
---

# APPROVED — per-agent inboxes + dispatch list direction-aware

## Approved

Plan looks solid. Iteration 2.6 fits naturally in the Phase 2 sequence.

## Decisions on your 4 questions

**Q1: Naming inbox/outbox vs received/sent — INBOX/OUTBOX.** Universal email metaphor, immediately understood, matches the model. Stick with these.

**Q2: Self-dispatch direction indicator — `=`.** ASCII, simple, no encoding concerns. `<` inbound, `>` outbound, `=` self. Skip the unicode `↔`.

**Q3: Resolved → archive subdir — DEFER.** Separate iteration on dispatch retention. Don't bundle with this.

**Q4: Misrouted dispatch #105 — both.** Forward it to captain (so it gets processed correctly), AND tighten the review-response authority check from 2.2 to validate that the recipient matches the original review's sender (so this doesn't happen again). The validation is the more important fix; the forward is one-time cleanup.

## Sequencing

Approved as Iteration 2.6 in Phase 2, after 2.5 (health metrics). Build the migration framework first (2.0) — already in your queue.

## Go ahead and implement.

Captain
