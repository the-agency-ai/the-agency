# REQUEST-jordan-0046: project-update Tool

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** Complete
**Priority:** High
**Created:** 2026-01-14

---

## Summary

Create a tool that allows users to update existing projects created from the-agency-starter with new tools, fixes, and features without losing local customizations.

---

## Problem Statement

Users who adopted The Agency early want to receive:
- New tools (e.g., the 44 renamed tools from v1.1.0)
- Bug fixes
- Documentation updates
- Knowledge base improvements

But they don't want to lose:
- Their custom tools in `tools/local/`
- Their agents and principals
- Their modifications to shared files

---

## Design

### Version Tracking

Store version metadata in `.agency/version.json`:

```json
{
  "starter_version": "1.1.0",
  "installed_at": "2026-01-14T10:30:00Z",
  "last_updated": "2026-01-14T10:30:00Z",
  "source": "github:the-agency-ai/the-agency-starter",
  "files": {
    "tools/agent-create": {
      "hash": "abc123...",
      "version": "1.1.0",
      "modified": false
    }
  }
}
```

### Protected Paths (NEVER touched)

Based on PROP-0001 and PROP-0006:

| Path | Reason |
|------|--------|
| `tools/local/` | Project-specific tools |
| `claude/agents/local/` | Local agent customizations |
| `claude/knowledge/local/` | Project-specific knowledge |
| `claude/docs/local/` | Project-specific docs |
| `claude/principals/` | User's principals and requests |
| `claude/workstreams/*/sprints/` | Active work |
| `claude/agents/*/WORKLOG.md` | Agent work history |
| `claude/agents/*/ADHOC-WORKLOG.md` | Adhoc work history |
| `.agency/` | Local metadata |

### Updatable Paths

| Path | Update Strategy |
|------|-----------------|
| `tools/*` (except local/) | Replace if unmodified, backup if modified |
| `claude/docs/*` (except local/) | Replace if unmodified |
| `claude/knowledge/*` (except local/) | Replace if unmodified |
| `claude/agents/templates/` | Replace (framework templates) |
| `claude/config/agency.yaml` | Merge with project values preserved |
| `CLAUDE.md` | Section-based merge |

### CLAUDE.md Merge Strategy

Use section markers to enable safe merging:

```markdown
<!-- AGENCY:START - Do not edit this section -->
[Framework content - auto-updated]
<!-- AGENCY:END -->

<!-- PROJECT:START - Your customizations below -->
[Project-specific content - preserved]
<!-- PROJECT:END -->
```

### CLI Interface

```bash
# Preview what would change
./tools/project-update --preview

# Apply updates
./tools/project-update --apply

# Use local starter instead of GitHub
./tools/project-update --from=/path/to/the-agency-starter --apply

# Check current status
./tools/project-update --status

# Initialize tracking for existing project
./tools/project-update --init
```

---

## Implementation

### Files to Create

1. `tools/project-update` - Main update tool

### Files to Modify

1. `tools/project-create` - Initialize version tracking
2. `CLAUDE.md` (starter) - Add section markers

---

## Success Criteria

- [x] `project-update --preview` shows pending updates
- [x] `project-update --apply` updates files without losing local changes
- [x] Protected paths are never modified
- [x] Modified files are backed up before replacement
- [x] CLAUDE.md project sections are preserved
- [x] Works with both GitHub source and local path
- [x] `project-create` initializes version tracking

---

## Work Log

### 2026-01-14

- Created REQUEST
- Designed version tracking and protected paths
- Defined CLI interface

### 2026-01-15

**Implementation:**
- Updated existing `tools/project-update` (v1.1.0)
  - Added quiet-by-default pattern with `--verbose` flag
  - Added proper telemetry logging with log_start/log_end
  - Fixed help output formatting
  - Supports `--status`, `--preview`, `--apply`, `--init` modes
  - Supports `--from=PATH` for local starter source
  - Handles GitHub clone for remote updates
  - CLAUDE.md section-based merging with markers
  - SHA256 hashes for file modification detection
  - Automatic backup of modified files before replacement

- Updated `tools/project-create` (v1.2.0)
  - Added version tracking initialization
  - Creates `.agency/version.json` on project creation
  - Records starter version from VERSION file

**Protected Paths:**
- `tools/local/` - Project-specific tools
- `claude/principals/` - User's principals
- `claude/agents/*/WORKLOG.md` - Work history
- `claude/agents/*/ADHOC-WORKLOG.md` - Adhoc work
- `claude/workstreams/*/sprints/` - Active sprints
- `.agency/` - Local metadata

**Tested:**
- `--help` shows proper usage
- `--status` shows version tracking state
- `--init --from=PATH` initializes tracking with file hashes
- `--preview` compares versions and shows pending updates

