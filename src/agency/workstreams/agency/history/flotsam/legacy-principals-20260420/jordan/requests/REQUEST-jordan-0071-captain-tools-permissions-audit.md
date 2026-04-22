# REQUEST-jordan-0071: Tools permissions audit

**Status:** Complete
**Priority:** Normal
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-20
**Updated:** 2026-01-20

## Summary

Tools permissions audit

## Details

Audit all tools in tools/ directory, categorize as destructive vs non-destructive, and update .claude/settings.json permissions so non-destructive tools don't require confirmation.

## Acceptance Criteria

- [x] All tools audited and categorized
- [x] Non-destructive tools added to allow list
- [x] Destructive tools added to deny list
- [x] Old/incorrect tool names removed
- [x] JSON validated

## Work Completed

### 2026-01-20 - Implementation

**Audited 97 tools, categorized by risk:**

**Auto-approved (87 tools)** - Normal workflow operations:
- Display/query: `agentname`, `whoami`, `now`, `requests`, `news-read`, etc.
- Workflow: `collaborate`, `news-post`, `nit-add`, `context-save`, `tag`, etc.
- Create operations: `agent-create`, `sprint-create`, `request`, etc.
- Build/test: `bench-build`, `test-run`, `code-review`, etc.

**Require confirmation (10 tools)** - Could cause harm if run accidentally:
- `commit` - permanent git history
- `sync` - pushes to remote
- `release` - creates releases, pushes tags
- `install-hooks` - modifies git config
- `starter-release`, `starter-update` - releases to starter repo
- Setup scripts: `mac-setup`, `linux-setup`, `iterm-setup`, `icloud-setup`

**Key insight:** "Destructive" = "could cause harm if run accidentally", not "writes files"

---

## Activity Log

### 2026-01-20 - Created
- Request created by jordan
