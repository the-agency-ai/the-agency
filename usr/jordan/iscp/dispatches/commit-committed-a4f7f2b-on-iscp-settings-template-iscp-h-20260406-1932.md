---
type: commit
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T11:32
status: created
priority: normal
subject: "Committed a4f7f2b on iscp: settings-template ISCP hooks/permissions + version test fixes"
in_reply_to: null
---

# Committed a4f7f2b on iscp: settings-template ISCP hooks/permissions + version test fixes

## Commits a4f7f2b + 41fb5cf on iscp

**Agent:** the-agency/jordan/iscp

### a4f7f2b — settings-template ISCP hooks/permissions + fix version test assertions
- Settings-template now includes iscp-check hooks (SessionStart/UserPromptSubmit/Stop)
- Added ISCP tool permissions (dispatch, flag, agent-identity, iscp-check, iscp-migrate)
- Added core tool permissions (handoff, git-safe-commit, stage-hash)
- Fixed version test assertions for dispatch (2.0.1), flag (2.0.1), iscp-check (1.0.1)

### 41fb5cf — structured commit dispatch payloads with metadata
- Commit dispatches to captain now include structured body
- Metadata: commit_hash, branch, files_changed, stage_hash, work_item, agent identity
- Captain gets actionable data for coordination without git-log on each worktree

### Test Status
174 ISCP tests, all green.
