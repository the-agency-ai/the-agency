---
type: feedback
feedback_id: 61261384-a937-472e-bb41-a604caf56f0e
github_issue: https://github.com/anthropics/claude-code/issues/49712
product: claude-code
date_filed: 2026-04-17
filer: jordan (via /feedback)
status: open
topic: Session name auto-rename overwrites user-set names
severity: high (daily friction, multi-agent workflow blocker)
---

# Session name auto-rename overwrites user-set names

## Feedback ID
`61261384-a937-472e-bb41-a604caf56f0e`

## GitHub issue
https://github.com/anthropics/claude-code/issues/49712

## Topic
Claude Code desktop session names are being auto-overwritten with random snippets from conversation dialog. User-set names (agent/workstream identifiers like `captain`, `designex`, `of-mobile`) get replaced in an endless rename loop.

## Why it matters for TheAgency
- Multi-agent workflows run N tabs in parallel (captain + worktree agents)
- Stable, short session names are central to tab differentiation
- Without sticky names, the whole multi-session UX degrades
- Hits Jordan constantly in daily use

## Requested behavior
1. User-set name is sticky forever — never auto-renamed
2. Expose a hook or env var (e.g., `CLAUDE_SESSION_NAME`) so agents can self-name at startup
3. Track name source: `user | auto | agent`

## Related
- TheAgency flag #153 — feedback tooling proposal (skill + command + tool for preparing and submitting feedback, don't hardcode reporter identity)

## Timeline
- 2026-04-17: Filed via `/feedback`
