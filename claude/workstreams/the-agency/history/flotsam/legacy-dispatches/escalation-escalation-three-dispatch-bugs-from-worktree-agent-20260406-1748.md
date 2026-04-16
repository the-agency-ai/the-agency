---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-06T09:48
status: created
priority: high
subject: "ESCALATION: three dispatch bugs from worktree agents using cd to main"
in_reply_to: null
---

# ESCALATION: three dispatch bugs from worktree agents using cd to main

Three bugs found from DevEx session transcript. All related to worktree agents using 'cd /path/to/main && dispatch' instead of running dispatch from their worktree.

BUG 1: Identity resolution when agent uses cd to main checkout. DevEx runs './claude/tools/dispatch create' — this resolves identity from main checkout (.agency-agent = captain), not from the worktree. Dispatches show from: captain instead of from: devex. The dispatch tool should use CLAUDE_PROJECT_DIR (set by Claude Code to the worktree path), not resolve from pwd. Same class as the PR branch identity bug (#63).

BUG 2: dispatch list --all shows ALL agents' dispatches. mdpal-app saw devex's unread dispatch #86 via --all flag. Agents shouldn't see other agents' unread mail. --all should probably be restricted or removed.

BUG 3: dispatch check doesn't surface dispatches when identity is wrong. DevEx has #86 unread but dispatch check says no dispatches — because identity resolves as captain (bug 1), and #86 is addressed to devex. The tool thinks it's captain, captain has no unread, reports clear. Agent never sees their mail.

Root cause: agents escape their worktree with cd to the main checkout before running dispatch commands. Fix options: (1) dispatch tool always uses CLAUDE_PROJECT_DIR over pwd, (2) warn when CLAUDE_PROJECT_DIR differs from pwd, (3) hookify rule blocking cd to main checkout from worktrees.
