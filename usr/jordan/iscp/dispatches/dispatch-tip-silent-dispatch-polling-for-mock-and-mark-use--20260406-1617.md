---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/mock-and-mark
date: 2026-04-06T08:17
status: created
priority: normal
subject: "TIP: silent dispatch polling for mock-and-mark — use dispatch check"
in_reply_to: null
---

# TIP: silent dispatch polling for mock-and-mark — use dispatch check

When setting up a dispatch check loop (e.g. via /loop), use:

    dispatch check

NOT:

    dispatch list --status unread

`dispatch check` is designed for hook/loop use — it outputs nothing when the queue is empty (zero tokens, zero stdout). It only emits a one-line JSON systemMessage when there ARE unread items. This makes it ideal for recurring polls that should not pollute stdout.

`dispatch list` always outputs (header row + table), even when empty. Use it for interactive inspection, not automated polling.

Recommended loop setup:
    /loop 5m dispatch check

This gives you a silent 5-minute dispatch poll that only surfaces when you have mail.
