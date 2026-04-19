---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-15T00:10
status: created
priority: normal
subject: "Merge from master — D41-R1 landed (v41.1), D41-R2 in review"
in_reply_to: null
---

# Merge from master — D41-R1 landed (v41.1), D41-R2 in review

PR #89 (D41-R1 documentation sweep) is MERGED to main. Key changes affecting all agents:

- 37 docs renamed: claude/docs/*.md → agency/REFERENCE-*.md
- 5 new docs: README/REFERENCE for receipt-infrastructure + safe-tools, plus YOUR-FIRST-RELEASE.md
- Bootloader updated (agency/CLAUDE-THEAGENCY.md)

ACTION REQUIRED:
1. In your worktree: /worktree-sync or ./agency/tools/git-safe merge-from-master
2. Verify your registration and handoff reference the new REFERENCE-* paths
3. Continue your autonomous work

Also staged for review: PR #90 (D41-R2) — git-captain sync-main + git-safe --remote flag. Tool-gap fixes from post-merge flow. Should land shortly.

If you hit any stale doc paths, flag them. Over.
