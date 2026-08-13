---
type: commit
from: the-agency/jordan/migrate-mdpal
to: the-agency/jordan/captain
date: 2026-08-13T10:31
status: created
priority: normal
subject: "Committed 0cd9ef3c on migrate-mdpal: refactor(mdpal): migrate usr/jordan/mdpal → agency/workstreams/mdpal, remove stale sandbox (flag #183)

The stale combined sandbox usr/jordan/mdpal/ (pre mdpal-cli/mdpal-app split)
held the ONLY copies of the workstream's A&D (67KB), plan, and PVRs. Consolidated
to the canonical location:
- Workstream artifacts (ad-mdpal, plan-mdpal, 3 PVRs) → agency/workstreams/mdpal/
- Instance history (dispatches, transcripts, code-reviews, handoffs, old QGRs,
  the 2 agent handoffs) → agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/
- seeds/ dropped (byte-identical duplicates of canonical seeds — verified) + tmp/
- usr/jordan/mdpal/ removed

Verified nothing lost: git detects 50 renames (content preserved), the only 6
plain deletes are the duplicate seeds + tmp, and each dropped seed hashes
identical to its canonical copy."
in_reply_to: null
---

# Committed 0cd9ef3c on migrate-mdpal: refactor(mdpal): migrate usr/jordan/mdpal → agency/workstreams/mdpal, remove stale sandbox (flag #183)

The stale combined sandbox usr/jordan/mdpal/ (pre mdpal-cli/mdpal-app split)
held the ONLY copies of the workstream's A&D (67KB), plan, and PVRs. Consolidated
to the canonical location:
- Workstream artifacts (ad-mdpal, plan-mdpal, 3 PVRs) → agency/workstreams/mdpal/
- Instance history (dispatches, transcripts, code-reviews, handoffs, old QGRs,
  the 2 agent handoffs) → agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/
- seeds/ dropped (byte-identical duplicates of canonical seeds — verified) + tmp/
- usr/jordan/mdpal/ removed

Verified nothing lost: git detects 50 renames (content preserved), the only 6
plain deletes are the duplicate seeds + tmp, and each dropped seed hashes
identical to its canonical copy.

## Commit: 0cd9ef3c

**Branch:** migrate-mdpal
**Agent:** the-agency/jordan/migrate-mdpal
**Message:** housekeeping/captain: refactor(mdpal): migrate usr/jordan/mdpal → agency/workstreams/mdpal, remove stale sandbox (flag #183)

The stale combined sandbox usr/jordan/mdpal/ (pre mdpal-cli/mdpal-app split)
held the ONLY copies of the workstream's A&D (67KB), plan, and PVRs. Consolidated
to the canonical location:
- Workstream artifacts (ad-mdpal, plan-mdpal, 3 PVRs) → agency/workstreams/mdpal/
- Instance history (dispatches, transcripts, code-reviews, handoffs, old QGRs,
  the 2 agent handoffs) → agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/
- seeds/ dropped (byte-identical duplicates of canonical seeds — verified) + tmp/
- usr/jordan/mdpal/ removed

Verified nothing lost: git detects 50 renames (content preserved), the only 6
plain deletes are the duplicate seeds + tmp, and each dropped seed hashes
identical to its canonical copy.

### Metadata
- commit_hash: 0cd9ef3c
- branch: migrate-mdpal
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/workstreams/mdpal/PVR-markdown-pal.md
agency/workstreams/mdpal/ad-mdpal-20260404.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/code-reviews/.gitkeep
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/.gitkeep
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-app-ack-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-app-response-20260404.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-collab-kickoff-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-item8-resolved-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-kickoff-20260404.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-ad-review-ready-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-captain-mar-findings-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-captain-mar-response-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-cli-json-output-shapes-20260406.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-iscp-adoption-20260404.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-iscp-mar-findings-20260405.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-iscp-pvr-ad-consumer-review-20260406.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-iscp-pvr-ad-review-20260404-2013.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-mar-response-valueflow-pvr-mdpal-cli-20260406.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-mar2-valueflow-pvr-mdpal-cli-20260406.md
agency/workstreams/mdpal/history/usr-sandbox-archive-20260421/dispatches/dispatch-plan-review-request-20260406.md
```
