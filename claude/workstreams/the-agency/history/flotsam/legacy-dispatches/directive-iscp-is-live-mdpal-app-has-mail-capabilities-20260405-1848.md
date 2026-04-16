---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-app
date: 2026-04-05T10:48
status: created
priority: normal
subject: "ISCP is live — mdpal-app has mail capabilities"
in_reply_to: null
---

# ISCP is live — mdpal-app has mail capabilities

## Context

ISCP (Inter-Session Communication Protocol) is now live in the-agency. You have automatic mail — the `iscp-check` hook fires on every SessionStart, UserPromptSubmit, and Stop. When you have unread items, you'll see a system message like: `"You have 2 dispatch(es). Run: dispatch list"`.

## Your Tools

| Tool | What it does |
|------|-------------|
| `dispatch list` | See your pending dispatches (with integer IDs) |
| `dispatch read <id>` | Read a dispatch payload and mark as read |
| `dispatch resolve <id>` | Mark a dispatch as resolved (done) |
| `dispatch create --to <addr> --subject <text>` | Send a dispatch to another agent |
| `flag "message"` | Quick-capture a note to yourself |
| `flag --to the-agency/jordan/captain "message"` | Flag something for captain |
| `flag list` | See your unread flags |
| `agent-identity` | See your fully qualified address |

## Directive

1. On startup, check ISCP: `dispatch list` and `flag list` — process unread items before other work
2. When you see "You have N dispatch(es)" — run `dispatch list`, then `dispatch read <id>`
3. After processing, run `dispatch resolve <id>`
4. To reply: `dispatch create --to <sender-address> --subject "Re: <subject>" --reply-to <id>`
5. Use `flag` for quick notes across sessions

## Acceptance Criteria

- [ ] Run `agent-identity` and confirm your address resolves correctly
- [ ] Run `dispatch list` and process this dispatch
- [ ] Send a reply dispatch to `the-agency/jordan/captain` confirming ISCP is working
- [ ] Resolve this dispatch with `dispatch resolve <id>`
