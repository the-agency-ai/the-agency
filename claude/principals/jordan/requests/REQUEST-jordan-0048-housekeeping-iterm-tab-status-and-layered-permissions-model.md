# REQUEST-jordan-0048-housekeeping-iterm-tab-status-and-layered-permissions-model

**Status:** Complete
**Priority:** Normal
**Requested By:** principal:jordan
**Assigned To:** housekeeping
**Created:** 2026-01-14
**Updated:** 2026-01-20

## Summary

Implement iTerm tab status feature and establish layered permissions model for The Agency

## Details

### iTerm Tab Status Feature (COMPLETED)

Migrate the dynamic tab status feature from ordinaryfolk-nextgen to provide visual feedback on agent state:

**States:**
- **Blue ● Circle** - Available (ready for input)
- **Green ◐ Half-circle** - Working (processing)
- **Red ▲ Triangle** - Attention (needs user input)

**Implementation:**
- `tools/tab-status` - Tool to set tab status (shapes + colors)
- Claude Code hooks in `.claude/settings.json` trigger status updates automatically
- Accessibility: Uses distinct shapes for colorblind users
- Terminal compatibility: iTerm2 (full), Terminal.app, Ghostty, Kitty (shapes only)

### Layered Permissions Model (TO DO)

Establish a permissions architecture that allows:
1. Framework defaults (shipped with The Agency)
2. User customizations (project-specific)
3. Proper merging/precedence

**Claude Code Settings Precedence:**
1. Enterprise managed: `/etc/claude-code/managed-settings.json`
2. Project Local: `.claude/settings.local.json` (highest for users)
3. Project Shared: `.claude/settings.json` (framework defaults)
4. User Global: `~/.claude/settings.json`

**Proposed Model:**
- `.claude/settings.json` - Framework defaults (versioned, synced to starter)
  - Standard Agency tool permissions
  - Standard hooks (tab-status, session-backup, check-messages)
  - Shipped with every The Agency installation

- `.claude/settings.local.json` - User overrides (gitignored, NOT synced)
  - Project-specific permissions (git, npm, domain-specific WebFetch)
  - User-specific tool approvals
  - Local customizations

**Benefits:**
- Users can update The Agency without losing customizations
- Framework can ship updated permissions
- Clean separation of concerns
- Follows Claude Code best practices

## Acceptance Criteria

**iTerm Tab Status:**
- [x] `tools/tab-status` created with versioning and help
- [x] Hooks configured in `.claude/settings.json`
- [x] SessionEnd hook creates backups automatically
- [x] `tools/starter-release` syncs `.claude/settings.json`
- [x] Documentation added to `CLAUDE.md`
- [x] Tested in actual iTerm session (colors work, shapes in badge only - see BUG-0001)

**Layered Permissions:**
- [x] `.gitignore` updated to exclude `.claude/settings.local.json`
- [x] Current `.claude/settings.json` contains only framework defaults
- [x] User/project-specific permissions moved to example `.claude/settings.local.json.example`
- [x] Documentation explains the layered model
- [x] `tools/starter-release` verified to handle both files correctly
- [x] `.gitignore` synced to starter (includes settings.local.json exclusion)
- [x] Tested in actual installation workflow

**Distribution:**
- [x] `the-agency-starter` receives both settings files (via starter-release)
- [x] Installation instructions explain permissions model (in CLAUDE.md)
- [x] Users know where to add custom permissions (settings.local.json.example)

## Notes

### Current State (2026-01-14)
- Tab status feature is implemented and integrated
- All changes are uncommitted (waiting for permission model completion)
- ordinaryfolk-nextgen uses only `.claude/settings.local.json` (reference implementation)

### Reference
- ordinaryfolk-nextgen: Uses `settings.local.json` exclusively
- Claude Code docs: `claude/knowledge/claude-code/05-configuration.md`
- Working notes: WORKING-NOTE-0004 (terminal config), WORKING-NOTE-0005 (hooks)

---

## Activity Log

### 2026-01-14 - Created
- Request created by agent:housekeeping (on behalf of jordan)

### 2026-01-14 - Implementation Complete
**iTerm Tab Status:**
- Created `tools/tab-status` with versioning (1.0.0-20260114-000001)
- Configured hooks in `.claude/settings.json`: SessionStart, SessionEnd, PreToolUse, PostToolUse, PermissionRequest, Stop
- Added SessionEnd hook to automatically create session backups
- Updated `tools/starter-release` to sync `.claude/settings.json` and hooks
- Documented in CLAUDE.md (iTerm Integration section)

**Layered Permissions Model:**
- Updated `.gitignore` to exclude `.claude/settings.local.json`
- Current `.claude/settings.json` now contains only framework defaults
- Created `.claude/settings.local.json.example` with user permission templates
- Documented permissions model in CLAUDE.md (new Permissions section)
- Updated `tools/starter-release` to sync `.gitignore` and example file
- Framework permissions: Agency tools, hooks, standard operations
- User permissions: git, npm, domains, project-specific commands

**Files Changed:**
- `.claude/settings.json` - Framework defaults + hooks
- `.claude/settings.local.json.example` - User template
- `.gitignore` - Exclude settings.local.json
- `tools/tab-status` - New tool
- `tools/starter-release` - Sync settings files
- `CLAUDE.md` - iTerm Integration + Permissions sections

**Distribution Ready:**
- Next `./tools/starter-release` will sync all changes to the-agency-starter
- Users get pre-configured hooks and tab status
- Users can customize via settings.local.json without conflicts

### 2026-01-14 - CLAUDE.md Refactored to Lean Constitution

**Problem:**
CLAUDE.md had become a 551-line user manual with exhaustive documentation, making it hard for agents to find critical information.

**Solution:**
Refactored to 311 lines (43% reduction) focusing on agent-essential content:

**CLAUDE.md (Agent Constitution - 311 lines):**
- Core concepts, conventions, workflow
- Essential commands with minimal examples
- Critical constraints (MUST/NEVER)
- Pointers to detailed documentation

**Moved to Reference Docs:**
- `claude/docs/TERMINAL-INTEGRATION.md` (83 lines) - iTerm setup, troubleshooting
- `claude/docs/PERMISSIONS.md` (230 lines) - Complete permissions model, patterns
- `claude/docs/SECRETS.md` (377 lines) - Full secrets reference, API docs

**Secrets in CLAUDE.md Now Shows:**
- Essential commands (get, create, list)
- First-time setup (vault unlock, init)
- Pointer to claude/docs/SECRETS.md for complete reference
- Critical constraint: MUST use Secret Service, NEVER commit secrets

**Benefits:**
- Agents can quickly scan CLAUDE.md for what they need
- Detailed docs available when needed via clear pointers
- Secrets retrieval pattern is immediately visible
- Constitution remains focused on conventions and workflow

**Files Changed:**
- `CLAUDE.md` - Refactored to lean constitution
- `claude/docs/TERMINAL-INTEGRATION.md` - Created
- `claude/docs/PERMISSIONS.md` - Created
- `claude/docs/SECRETS.md` - Created
- `tools/starter-release` - Updated to sync new docs
- `CLAUDE-old.md` - Backup of original (can be deleted after review)

### 2026-01-20 - Complete
- Marked complete with known limitation
- Tab colors work correctly
- Tab shapes appear in badge only (not tab title) - filed as BUG-0001
- Layered permissions model fully functional
- Investigation documented in `claude/docs/investigations/ITERM-TAB-SHAPES.md`
