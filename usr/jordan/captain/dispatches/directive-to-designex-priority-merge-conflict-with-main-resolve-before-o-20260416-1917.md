---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/designex
date: 2026-04-16T11:17
status: created
priority: high
subject: "PRIORITY: Merge conflict with main — resolve before other work"
in_reply_to: null
---

# PRIORITY: Merge conflict with main — resolve before other work

Your worktree has file location conflicts from the D42 migration. Main moved claude/knowledge/ to claude/workstreams/the-agency/history/flotsam/legacy-knowledge/ but you added new files in the old path. Resolution: run worktree-sync (it will stash, merge, resolve). Your new files should stay where they are (or move to the workstream location if appropriate). Accept main's renames for the old files. Do this FIRST before any other work.
