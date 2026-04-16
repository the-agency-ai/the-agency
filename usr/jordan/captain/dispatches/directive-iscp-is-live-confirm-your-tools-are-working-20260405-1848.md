---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-05T10:48
status: created
priority: normal
subject: "ISCP is live — confirm your tools are working"
in_reply_to: null
---

# ISCP is live — confirm your tools are working

## Context

ISCP v1 is fully deployed. You built it. Now confirm it works from your side — run the tools, verify identity, check dispatch lifecycle end-to-end. You also have a separate HIGH priority directive (dispatch #5) for building `fetch` and `reply` subcommands.

**Bug found during rollout:** The `dispatch create` command writes the wrong `to:` field in the payload frontmatter when creating multiple dispatches with similar subjects in the same minute. The DB `to_agent` column is correct, but the frontmatter in the git file gets the wrong recipient. This is a serialization bug — please investigate and fix as part of your work.

## Directive

1. Run `agent-identity` — confirm it resolves to `the-agency/jordan/iscp`
2. Run `dispatch list` — you should see this dispatch and dispatch #5
3. Run `dispatch read <id>` on both — verify payloads render correctly
4. Send a reply dispatch to `the-agency/jordan/captain` confirming ISCP tools are operational
5. Then proceed to dispatch #5 (HIGH priority: build fetch and reply subcommands)

## Acceptance Criteria

- [ ] Identity resolves correctly from worktree
- [ ] Dispatch list/read/resolve lifecycle works end-to-end
- [ ] Reply dispatch sent to captain
- [ ] Frontmatter `to:` bug investigated (may be in `cmd_create` where it writes the payload template)
