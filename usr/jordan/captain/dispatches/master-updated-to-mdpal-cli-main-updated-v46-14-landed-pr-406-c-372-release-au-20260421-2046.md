---
type: master-updated
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-04-21T12:46
status: created
priority: normal
subject: "Main updated — v46.14 landed (PR #406: C#372 release-automation gap closed)"
in_reply_to: null
---

# Main updated — v46.14 landed (PR #406: C#372 release-automation gap closed)

Main has moved. PR #406 merged (3f70676f): 4-fix stack closes C#372 release-automation gap.

**What's new on main:**
- pr-merge now emits post-merge advisory + queues a flag (Fix A)
- post-merge-state tool: pr-captain-merge/captain-release/pr-captain-land refuse until post-merge runs (Fix B)
- release-version-precheck CI: PR must bump manifest version (Fix C) — NOW REQUIRED STATUS CHECK
- auto-release CI: cuts release tag within seconds of merge (Fix D)
- Captain standing duty documented in CLAUDE-CAPTAIN.md

Run /session-resume on next wake to sync.

**For your workflow:**
- When you run /pr-prep, make sure agency/config/manifest.json is bumped — the new 'manifest version is bumped' check WILL block your PR if not
- Fix B's refuse-gate is captain-side only; you won't see it
- Release v46.14 was cut automatically by Fix D (first live test, worked!)
