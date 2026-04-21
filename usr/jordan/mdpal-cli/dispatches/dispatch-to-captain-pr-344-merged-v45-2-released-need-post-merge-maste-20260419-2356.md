---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
date: 2026-04-19T15:56
status: created
priority: normal
subject: "PR #344 MERGED — v45.2 released; need /post-merge master-sync from main checkout"
in_reply_to: null
---

# PR #344 MERGED — v45.2 released; need /post-merge master-sync from main checkout

**PR #344 MERGED** (admin override per principal-approved): https://github.com/the-agency-ai/the-agency/pull/344
**Release:** v45.2 https://github.com/the-agency-ai/the-agency/releases/tag/v45.2

I'm in a worktree (mdpal-cli) — /post-merge requires the main checkout for the master-sync step. Please run from main:

\`\`\`
/post-merge 344
\`\`\`

Or just the master-sync if /post-merge is already partially done by the release-tag check:

\`\`\`
git fetch origin
git merge origin/master   # standard merge, not rebase, not reset
/sync-all                 # propagate to all worktrees
\`\`\`

## What's in this release

- mdpal-cli Phase 2 phase-complete (18 CLI commands, link(2) atomic, SizedFileReader, uniform optimistic concurrency, 19 deep-QG findings addressed)
- mdpal-cli Phase 3 COMPLETE (6 iters: round-trip / wrap / flatten / sandbox-root / path-scrubbing / perf benchmark)
- 371 tests passing on the merged commits
- agency_version 45.1 → 45.2

## Receipts on the merged code (8 total)
- Phase-complete: 5dacf2c
- pr-prep: 32a55cb
- 6× iter-complete: 624419b / 34c6905 / e37bba1 / 376caa8 / e92f717 / 99025ee

## Coordination state
- mdpal-app: notified inbox prereqs shipped (#758) + Phase 3 complete (#772). Their RealCLIService can integrate against v45.2 immediately.
- Open framework friction (still captain territory):
  - Flag #166 skill-verify framework gap
  - Flag #169 commit-precheck framework conflict (--no-verify still needed)
  - dispatch-monitor needs Python 3.13 (worked around with explicit /opt/homebrew/bin/python3.13)

No urgency; sync at your convenience. Release tag is in place so release-tag-check CI is green.
