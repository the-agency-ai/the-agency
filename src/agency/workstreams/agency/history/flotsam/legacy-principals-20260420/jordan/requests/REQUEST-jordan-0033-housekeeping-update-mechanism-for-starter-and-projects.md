# REQUEST-jordan-0033-housekeeping-update-mechanism-for-starter-and-projects

**Status:** Complete
**Priority:** Normal
**Requested By:** agent:housekeeping (on behalf of jordan)
**Assigned To:** housekeeping
**Created:** 2026-01-11
**Updated:** 2026-01-20

## Summary

Update mechanism for starter and projects

## Details

Implement update-starter and update-agency tools. Allow updating local starter from GitHub, and projects from starter or GitHub. Version tracking, preserve user content, show changelogs.

## Acceptance Criteria

- [x] Tool to update projects from starter with version tracking
- [x] Tool to update starter itself from GitHub
- [x] Preserve user content (principals, worklogs, local customizations)
- [x] File hash tracking to detect local modifications
- [x] Preview mode before applying changes
- [x] Backup of conflicting files

## Implementation

### Tools Implemented

1. **`tools/project-update`** - Primary tool for updating projects from starter
   - `--init` - Initialize manifest tracking for existing project
   - `--status` - Show current version status
   - `--check` / `--check --json` - Check for updates (read-only)
   - `--preview` - Preview changes without applying
   - `--apply` - Apply updates
   - `--from=/path/to/starter` - Use local starter instead of GitHub

2. **`tools/starter-update`** - Update the-agency-starter itself from GitHub
   - For use within the starter repo
   - Git fetch/pull with conflict handling

3. **`tools/agency-update`** - Legacy/alternate update tool
   - Simpler rsync-based approach
   - Works from manifest source or GitHub

### Protected Paths (Never Updated)

- `tools/local/` - Project-specific tools
- `agency/agents/local/` - Local agent customizations
- `claude/knowledge/local/` - Project-specific knowledge
- `claude/docs/local/` - Project-specific docs
- `claude/principals/` - User's principals and requests
- `agency/agents/*/WORKLOG.md` - Agent work history
- `agency/agents/*/ADHOC-WORKLOG.md` - Ad-hoc work logs
- `.agency/` - Local metadata

### Version Tracking

- Manifest stored in `.agency/manifest.json`
- Tracks file hashes, versions, and modification status
- Components tracked from `registry.json`
- Projects registered in starter's `.agency/projects.json`

---

## Activity Log

### 2026-01-20 - Complete
- Verified all tools implemented and working
- `project-update` provides full manifest-based tracking (1032 lines)
- `starter-update` handles starter repo updates
- Protected paths properly exclude user content
- Marked complete

### 2026-01-11 - Created
- Request created by agent:housekeeping (on behalf of jordan)
